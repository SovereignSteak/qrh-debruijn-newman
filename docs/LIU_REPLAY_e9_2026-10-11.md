# Liu arXiv:2610.12234 Lean replay report (Arda verification session, 2026-10-11)

Target: github.com/liubaiying101/Slightly-improved-zero-free-half-planes-for-the-quasi-Riemann-hypothesis
at HEAD 7d10420 (three "Add files via upload" commits, 2026-10-08), cloned read-only at ~/liu-qrh.
Claim: `CombinedPaper.algebraic_zeta_nonzero : riemannZeta s ≠ 0` for `B_new < s.re`, `s ≠ 1`,
`B_new = (1507 - 2 * Real.sqrt 921) / 1653` (= 0.874957...).

## 1. Integrity (no build needed)

### 1a. The upload is NOT buildable as cloned; two reconstructions were needed

1. **`vendor/` is absent.** `upstream/closure_manifest.json` lists 2925 OpenAI modules at
   `vendor/OAI/...` (commit adc7f1241b42e322a6451854ab7e4b4c146bf78a of github.com/openai/math);
   0 of 2925 were in the clone. `lakefile.lean` declares `lean_lib OAI where srcDir := "vendor"`.
   Also missing: `vendor/LICENSE` (hashed by verify.py), `check_extension.sh` and
   `audits/extension_replay/` (both referenced in RHZeroFreeExtension.lean's docstring).
   Reconstruction: sparse-cloned openai/math at adc7f124 (commit exists upstream, dated
   2026-10-06, "Initial commit"), copied exactly the 2925 manifest paths plus `lean/LICENSE`
   to `~/liu-qrh/vendor/`. Verified every module: **2925/2925 sha256 AND git-blob sha1 match**
   the manifest, 0 missing, 0 mismatched; `indexed_blob_match` is true for all. The manifest's
   import graph is closed (0 dangling imports), and the actual `import OAI.*` lines in the copied
   files equal the manifest's `imports` for all 2925 files. All 172 distinct `OAI.*` modules that
   Liu's own files import are in the manifest. Non-OAI imports inside the vendored closure:
   Lean, Mathlib, PrimeNumberTheoremAnd, RellichKondrachov only.
2. **Module tree is flattened.** Imports name `RHZeroFreeExtension.analytic_high.*` (209 uses,
   133 modules), `RHZeroFreeExtension.moment_adapters.*` (18), `RHZeroFreeExtension.Actual*`,
   `RHZeroFreeExtension.V2*`, and verify.py's entry is `RHZeroFreeExtension/CombinedPaperVerification.lean`;
   the upload has these at repo root in `analytic_high/` (65 files), `analytic_high_v2/` (68 files,
   all imported as `RHZeroFreeExtension.analytic_high.V2*`; no filename collisions), `moment_adapters/`,
   and root `*.lean`. (GitHub's web upload caps 100 files per upload, which explains the split.)
   Reconstruction: created `~/liu-qrh/RHZeroFreeExtension/{,analytic_high,moment_adapters}` with
   byte-identical COPIES of the uploaded files; Liu's uploaded files were not modified. `geometry/`
   and `analytic_low/` are separate `lean_lib`s and were already in place. After this, every local
   import resolves to a file.
3. Dependencies were materialized with `lake env true` (clones at `lake-manifest.json` revs, no
   `lake update`; manifest byte-identical before/after), then the two compatibility patches
   `upstream/{PrimeNumberTheoremAnd,rellich-kondrachov}-lean4341.patch` were applied with
   `git apply` exactly as Liu's `post_update` hook would (both `--check` clean; PNT: 8 files,
   rellich-kondrachov: 15 files). Both patch files are **byte-identical** to openai/math's
   `lean/patches/*-lean4341.patch` at adc7f124. Liu's `lake-manifest.json` pins are an exact
   subset of openai/math's manifest (same revs for every shared package; nothing differs):
   mathlib d13f23b7, PrimeNumberTheoremAnd c39a7511, PrimeCert 0803c2f6, leancert 7f91b6eb,
   rellich-kondrachov 70f85d4c. Toolchain `leanprover/lean4:v4.34.1` (same as openai/math).

verify.py was read but NOT run: it unconditionally runs `lake build` and a `--trust=0` replay
and writes `verification/`; its manifest/hash checks were replayed by hand above (same algorithm:
sha256 + `blob <len>\0` sha1). Note verify.py's `EXPECTED` list = 22 theorem names in
`CombinedPaper`, and its ALLOWED axiom set = {propext, Classical.choice, Quot.sound}.

### 1b. Source greps over Liu's own 220 .lean files (31,991 lines; vendor/ and .lake excluded)

| pattern | count | notes |
|---|---|---|
| `sorry` | 0 | |
| `^axiom` / ` axiom ` | 0 | |
| `native_decide` | 0 | |
| `implemented_by`, `@[extern`, `unsafe`, `partial def`, `opaque` | 0 | |
| `set_option maxHeartbeats` | 5 | 3x `0` (geometry/CountOptimization.lean:7, geometry/Endpoint.lean:7, geometry/V2Optimization.lean:5); 2x `1000000` (moment_adapters/DetectorMomentPrimeGeometry.lean:8, analytic_high_v2/V2MomentCertificateAdapters.lean:54) |
| `set_option maxRecDepth 100000` | 1 | geometry/Endpoint.lean:8 |
| `set_option linter.unusedVariables` | 98 | cosmetic |
| `macro` | 2 | geometry/V2AnalyticGeometry.lean:24 `v2_geometry`, :34 `v2_ring` (tactic macros, inspected: nlinarith/norm_num/ring wrappers) |
| `@[simp]` | 2 | ordinary simp lemmas |
| `noncomputable section` | 217 files | normal for real analysis; not abuse |
| imports outside Mathlib/OAI/own libs | 0 | roots: Mathlib 12 lines, OAI 172, RHZeroFreeExtension 160, analytic_low 50, geometry 8, Lake (lakefile only) |

Hygiene note (not soundness): 90 of Liu's files open `namespace OAI` / `OAI.SevenEighths.*`, i.e.
Liu adds declarations INSIDE OpenAI's namespace (e.g. `OAI.SevenEighths.V2ProbeFinalAssemblyCertifiedBands.chosen_moments_of_original_headline`
in analytic_high_v2/V2MomentCertificate.lean:154). Provenance by name alone is therefore unreliable;
provenance by file path is what the manifest hashes certify.

Proof architecture as read from the top-level files: `RHV2.zeta_nonzero` (V2FullVerification.lean)
= `zeta_nonzero_of_probes physical_probe_estimates`, where `PhysicalProbeEstimates` (V2Conditional.lean)
is an explicit Prop (NOT an axiom) discharged by `physical_probe_estimates`, which is built from
OpenAI's own 7/8 headline (`ActualOriginalBoundary.beta_le_seven_eighths`, derived from
`OAI...LFunction_ne_zero_of_seven_eighths_lt_re`) via Liu's new moment certificate. The zeta step
`ActualDirichletTransfer.zeta_nonzero_of_hecke_bound` goes through OpenAI's
`HeckeDirichlet.LFunction_eq_dirichlet_product` at modulus 1 and Mathlib's
`DirichletCharacter.LFunction_modOne_eq`; it handles `s = 1` itself via `riemannZeta_one_ne_zero`,
so the `hpole : s ≠ 1` hypothesis of `algebraic_zeta_nonzero` is never used (bound as `_hpole`).

## 2. Build

Command (from ~/liu-qrh, after `lake exe cache get`: 8907 Mathlib files, all already in ~/.cache/mathlib, 0 downloaded):

    ARDA_LEAN_SLOTS=1 ~/hodge-engine/leanlock.sh lake build RHZeroFreeExtension.CombinedPaperVerification

Result: `Build completed successfully (12088 jobs).` 0 lines containing `error:` in the log.
The only lines matching "error" are module and theorem names (for example `...ErrorMass`, `v2_actual_principal_slot_error`).
Wall time: 5276 s (03:03:36 to 04:31:32 EDT, 2026-10-11), on a 32-core Mac at load 8-25 with one leanlock slot.
Swap stayed at 715 MB throughout. Log: scratchpad/liu/build.log.
This target is verify.py's build target. The default `lean_lib RHZeroFreeExtension` target was not separately built.
It is a superset: it includes V2Conditional and the other modules imported by CombinedPaperVerification.
Lake warns at every invocation that PrimeNumberTheoremAnd and rellich-kondrachov "have local changes". These are the two pinned compatibility patches from section 1a, and the warning is expected.

The build log's own `#print axioms` output for all 22 CombinedPaper theorems in verify.py's EXPECTED list:
```
info: RHZeroFreeExtension/CombinedPaperVerification.lean:136:0: 'CombinedPaper.rational_parameters' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:137:0: 'CombinedPaper.algebraic_parameters' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:138:0: 'CombinedPaper.balanced_signal_matching' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:139:0: 'CombinedPaper.rational_boundary' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:140:0: 'CombinedPaper.algebraic_boundary' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:141:0: 'CombinedPaper.boundary_order' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:142:0: 'CombinedPaper.original_family_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:143:0: 'CombinedPaper.preliminary_family_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:144:0: 'CombinedPaper.rational_family_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:145:0: 'CombinedPaper.rational_hecke_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:146:0: 'CombinedPaper.rational_dirichlet_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:147:0: 'CombinedPaper.rational_zeta_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:148:0: 'CombinedPaper.algebraic_family_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:149:0: 'CombinedPaper.algebraic_hecke_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:150:0: 'CombinedPaper.algebraic_dirichlet_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:151:0: 'CombinedPaper.algebraic_zeta_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:152:0: 'CombinedPaper.original_hecke_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:153:0: 'CombinedPaper.original_dirichlet_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:154:0: 'CombinedPaper.original_zeta_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:155:0: 'CombinedPaper.rational_endpoint' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:156:0: 'CombinedPaper.algebraic_endpoint' depends on axioms: [propext, Classical.choice, Quot.sound]
info: RHZeroFreeExtension/CombinedPaperVerification.lean:157:0: 'CombinedPaper.scalar_obstruction' depends on axioms: [propext, Classical.choice, Quot.sound]
```

## 3. Axioms and elaborated statements (independent check module)

File ~/liu-qrh/RHZeroFreeExtension/ArdaLiuCheck.lean imports RHZeroFreeExtension.CombinedPaperVerification.
It was run with `ARDA_LEAN_SLOTS=1 ~/hodge-engine/leanlock.sh lake env lean RHZeroFreeExtension/ArdaLiuCheck.lean`, exit 0.
The first run failed only because the check file named `OAI.SevenEighths.HeckeFamily.HeckeZeroSupremum.beta`, which does not exist.
The correct name is `OAI.SevenEighths.HeckeZeroSupremum.beta`. The fixed second run's output is below verbatim, with the two lake "local changes" warnings omitted:

```
def CombinedPaper.B_new : ℝ :=
(1507 - 2 * √921) / 1653
algebraic_zeta_nonzero : ∀ (s : ℂ), B_new < s.re → s ≠ 1 → riemannZeta s ≠ 0
algebraic_dirichlet_nonzero : ∀ (q : ℕ) (hq : q ≠ 0) (chi : DirichletCharacter ℂ q) (s : ℂ),
  B_new < s.re → ¬(chi = 1 ∧ s = 1) → DirichletCharacter.LFunction chi s ≠ 0
algebraic_hecke_nonzero : ∀ (eta : OAI.SevenEighths.HeckeFamily.Character) (s : ℂ),
  B_new < s.re → s ≠ 1 ∨ eta.residue ≠ 1 → OAI.SevenEighths.HeckeFamily.LFunction eta s ≠ 0
algebraic_family_bound : OAI.SevenEighths.HeckeZeroSupremum.beta ≤ B_new
rational_zeta_nonzero : ∀ (s : ℂ), B_r < s.re → s ≠ 1 → riemannZeta s ≠ 0
original_zeta_nonzero : ∀ (s : ℂ), 7 / 8 < s.re → s ≠ 1 → riemannZeta s ≠ 0
OAI.SevenEighths.HeckeZeroSupremum.beta : ℝ
'CombinedPaper.algebraic_zeta_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CombinedPaper.algebraic_dirichlet_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CombinedPaper.algebraic_hecke_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CombinedPaper.algebraic_family_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'CombinedPaper.rational_zeta_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
'CombinedPaper.original_zeta_nonzero' depends on axioms: [propext, Classical.choice, Quot.sound]
CombinedPaper.algebraic_zeta_nonzero : ∀ (s : Complex)
  (hs : @LT.lt.{0} Real Real.instLT CombinedPaper.B_new (Complex.re s))
  (hpole : @Ne.{1} Complex s (@OfNat.ofNat.{0} Complex (nat_lit 1) (@One.toOfNat1.{0} Complex Complex.instOne))),
  @Ne.{1} Complex (riemannZeta s) (@OfNat.ofNat.{0} Complex (nat_lit 0) (@Zero.toOfNat0.{0} Complex Complex.instZero))
def riemannZeta : ℂ → ℂ :=
HurwitzZeta.hurwitzZetaEven 0
riemannZeta declared in module Mathlib.NumberTheory.LSeries.RiemannZeta
CombinedPaper.algebraic_zeta_nonzero declared in module RHZeroFreeExtension.CombinedPaperVerification
RHV2.zeta_nonzero declared in module RHZeroFreeExtension.V2FullVerification
OAI.SevenEighths.HeckeZeroSupremum.beta declared in module OAI.NumberTheory.DirichletL.Hecke.ZeroSupremum
```

All six requested theorems depend on exactly [propext, Classical.choice, Quot.sound]. That is the required set, so the axiom check PASSES.
