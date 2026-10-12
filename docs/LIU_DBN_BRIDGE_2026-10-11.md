# Liu's zero-free half-plane into the de Bruijn-Newman converter (2026-10-11)

Island: `telperion/examples/liu_dbn_bridge/`. Branch `rh/liu-bridge`, local only, not pushed.

## 1. What is proved

One kernel check, in one Lake workspace (Lean v4.34.1, Mathlib d13f23b, openai/math @ adc7f124,
Liu @ 7d10420, the 19-module dbn single-pin port):

```lean
-- ArdaLiuBridge.lean
theorem liu_zeta_zero_free :
    ∀ s : ℂ, (1507 - 2 * Real.sqrt 921) / 1653 < s.re → riemannZeta s ≠ 0
theorem liu_boundary_eq : CombinedPaper.B_new = (1507 - 2 * Real.sqrt 921) / 1653   -- rfl
theorem sqrt921_bounds :
    (303479818109 / 10000000000 : ℝ) < Real.sqrt 921 ∧ Real.sqrt 921 < (303479818110 / 10000000000 : ℝ)
theorem liuBoundary_lt_seven_eighths : (1507 - 2 * Real.sqrt 921) / 1653 < (7 / 8 : ℝ)
theorem liuBoundary_bounds :   0.8749570697 < θ ∧ θ < 0.8749570698
theorem liu_lambda_closed_form :
    2 * ((1507 - 2 * Real.sqrt 921) / 1653 - 1 / 2) ^ 2 = (1867057 - 10888 * Real.sqrt 921) / 5464818

-- ArdaDBNLiu.lean
theorem dbn_real_zeros_of_liu_unconditional :
    ∀ t : ℝ, 2 * ((1507 - 2 * Real.sqrt 921) / 1653 - 1 / 2) ^ 2 ≤ t →
      ∀ z : ℂ, DBN.H t z = 0 → z.im = 0
theorem dbn_real_zeros_of_liu_closed_form :
    ∀ t : ℝ, (1867057 - 10888 * Real.sqrt 921) / 5464818 ≤ t → ∀ z : ℂ, DBN.H t z = 0 → z.im = 0
theorem dbn_real_zeros_ge_2811856084 :
    ∀ t : ℝ, (2811856084 / 10000000000 : ℝ) ≤ t → ∀ z : ℂ, DBN.H t z = 0 → z.im = 0
theorem dbn_real_zeros_ge_2811857 :
    ∀ t : ℝ, (2811857 / 10000000 : ℝ) ≤ t → ∀ z : ℂ, DBN.H t z = 0 → z.im = 0
theorem liu_threshold_lt_nine_thirtyseconds :
    2 * ((1507 - 2 * Real.sqrt 921) / 1653 - 1 / 2) ^ 2 < (9 / 32 : ℝ)
```

The exact threshold, with θ = (1507 − 2√921)/1653 = 0.87495706979916874...:

```
Λ ≤ 2(θ − 1/2)² = (1867057 − 10888·√921) / 5464818 = 0.28118560838475739685...
```

The derivation of the closed form: 2(θ − 1/2)² = 2(1361 − 4√921)²/3306², and
(1361 − 4√921)² = 1852321 + 14736 − 10888√921 = 1867057 − 10888√921, while 3306²/2 = 5464818.

The two rational corollaries use the lower bound √921 > 30.3479818109. The ten-decimal one,
0.2811856084, sits 1.5e-11 above the exact value. Its proof is linear arithmetic once the
closed form is in place. The seven-decimal one, 0.2811857, is the convenient round number.

**How the composition works.** Liu's top theorem is
`CombinedPaper.algebraic_zeta_nonzero (s) (hs : B_new < s.re) (hpole : s ≠ 1) : riemannZeta s ≠ 0`,
with `B_new := (1507 - 2 * Real.sqrt 921) / 1653` (and `B_new = RHV2.boundary` by `rfl`). The
converter wants no pole hypothesis. At s = 1 we use Mathlib's `riemannZeta_one_ne_zero`
(NumberTheory/Harmonic/ZetaAsymp.lean). Lean accepts Liu's term as the converter's hypothesis
directly, which confirms at kernel level that Liu's `riemannZeta` is Mathlib's.

The s = 1 step is a precaution and is not needed. peterwmurphy-e9's independent replay found that
Liu's proof never uses `hpole`. It is bound as `_hpole`, and Liu's transfer step handles s = 1
itself through `riemannZeta_one_ne_zero`.

## 2. Gain, and why this is the end of this route

| bound | θ | Λ threshold |
|---|---|---|
| OpenAI 7/8 (`dbn_real_zeros_of_qrh_unconditional`) | 0.875 | 0.28125 |
| Liu, this island | 0.8749570698 | 0.2811856084 |
| gain | 4.29e-5 | 6.44e-5 |
| Polymath15 (for scale) | | 0.22 |

The rh-team's gate analysis, `~/rh-team/gates/gate0.md` Addendum 2 (2026-10-11), and PR #684
found that the best you can do inside OpenAI's quasi-Riemann-hypothesis architecture, using only
proved inputs, is exactly Liu's θ. For ell > 1/6 the binding high-side constraint is the balanced
witness-count bin. It crosses the low-side bound 11/12 − ell/4 at sigma0 = 0.87495707, which
equals Liu's B_new to 8 digits. So this theorem is the proved-input optimum of the QRH route. The
earlier 13/15 figure was an idealisation, not a floor. A better Λ along these lines needs a new
input, not more tuning.

## 3. Provenance and license

**Licence basis: owner decision 2026-10-11, no author grant on file.** As of 2026-10-11,
github.com/liubaiying101/Slightly-improved-zero-free-half-planes-for-the-quasi-Riemann-hypothesis
has no LICENSE file, and no licence or copyright line appears in its README or in any Lean file.
It is a derivative overlay on openai/math. openai/math's Apache-2.0 grant covers OpenAI's code,
not Liu's additions. On 2026-10-11 the Arda owner ruled that Liu's code is to be treated as
Apache-2.0. Liu has granted nothing in writing. Author attribution to Baiying Liu is kept in
every file that touches the work. We still commit none of Liu's files. The island holds only:

- `LIU_PIN`: repository URL, commit `7d10420de90efa2f082a06a342fc7accbd57ab37`, paper id, counts;
- `liu_sources.sha256`: the sha256 of each of Liu's files that the recipe uses;
- the layout rule inside `liu_materialize.sh`;
- `liu_oai_declarations.txt`: the names of the `OAI.*` declarations Liu's modules add (section 4).

`liu_materialize.sh` fetches the pinned commit at build time into `work/`, which is gitignored.
CI is active as `.github/workflows/liu-dbn-bridge.yml`. It builds and judges the island on every
relevant push to main and weekly, and the Comparator judge job `judge-liu-dbn-bridge` in
`missions-comparator.yml` covers granted nodes. Public release waits on the missions governance
path. peterwmurphy-e9's independent replay of Liu's upload passed the build and axiom checks on
2026-10-11.

**Liu's repository is not self-verifying as shipped.** Its `verify.py` expects `vendor/`,
`verification/` and `vendor/LICENSE`. Its root module refers to `check_extension.sh` and
`audits/extension_replay/`. None of these is in the public repository. The GitHub tree is also
flattened, so the files do not sit where their own `import` lines expect them. The recipe
reconstructs the layout mechanically from the import graph, with zero collisions:

| Liu's path | workspace path |
|---|---|
| `RHZeroFreeExtension.lean` | unchanged |
| other top-level `X.lean` | `RHZeroFreeExtension/X.lean` |
| `analytic_high/X`, `analytic_high_v2/X` | `RHZeroFreeExtension/analytic_high/X` |
| `moment_adapters/X` | `RHZeroFreeExtension/moment_adapters/X` |
| `geometry/X`, `analytic_low/X` | unchanged |

**What the recipe verifies** (run 2026-10-11, `logs/materialize_2026-10-11.txt`):

```
[1/5] OAI tree = openai/math adc7f1241b42e322a6451854ab7e4b4c146bf78a
[2/5] Liu tree = 7d10420de90efa2f082a06a342fc7accbd57ab37 (219 modules, sha256 list matched)
[3/5] closure manifest: 2925 OAI modules match by sha256 at adc7f1241b42e322a6451854ab7e4b4c146bf78a
[4/5] Liu's lake-manifest: 15 packages, all revisions equal OpenAI's
[5/5] placed 219 Liu modules (no existing path overwritten)
```

Step 1 is a `diff -rq` of the source tree against a clean `openai/math` checkout at the pin. Step 4
also checks Liu's `lean-toolchain` and that Liu's two dependency patches
(`PrimeNumberTheoremAnd`, `rellich-kondrachov`) are byte-identical to OpenAI's.

**Build options.** Liu's three libraries are built with Liu's own package options,
`autoImplicit := false` and `warningAsError := true`, so any warning in Liu's code fails the build.

**Credit.**

- The half-plane is Baiying Liu's: arXiv:2610.12234, "Slightly improved zero-free half-planes for
  the quasi-Riemann hypothesis", Lean at the commit above.
- Liu's proof bootstraps on OpenAI's 7/8 theorem: github.com/openai/math at adc7f124, family 003,
  Apache License 2.0. It reuses `beta_le_seven_eighths` to fix kappa = 3/4, then re-derives the
  moment inputs at a new geometry and feeds them to OpenAI's continuation machinery.
- The converter, the dbn port and the two joining lines are Arda's.

## 4. Liu's declarations in `namespace OAI`

90 of Liu's 219 modules open `namespace OAI` and declare new constants there, for example under
`OAI.SevenEighths.*`. These names read like OpenAI's but are Liu's. A reader who sees an `OAI.*`
name in a proof term cannot assume OpenAI wrote it.

The island guards against two failure modes.

- **Clash.** Everything is built in one workspace, with OpenAI's package as root. Liu's modules
  import 2,925 OpenAI modules. Any Liu declaration whose name equals one of theirs would fail the
  import as a duplicate declaration. The build is green, so there is no clash inside that closure.
  `lean/LiuOAIClashCheck.lean` extends this beyond the closure. It reads every built OpenAI
  `.olean` without importing it and compares constant names with Liu's. Result, 2026-10-11:
  `liu_constants=2624 oai_oleans_scanned=3232 outside_liu_closure=307 clashes=0`.
  OpenAI's tree has many more sources than are built here. All of Liu's `OAI.*` names lie under
  `OAI.SevenEighths`, and every one of the 2,633 OpenAI source files that mentions `SevenEighths`
  is among the scanned oleans. So no clash exists anywhere in openai/math at the pin. That last
  step is a text search, not a kernel check.
- **Attribution.** `lean/LiuOAIDeclarations.lean` lists every constant named `OAI.*` that is
  declared in one of Liu's modules. Its output is committed as `liu_oai_declarations.txt`.
  Liu's 219 modules declare 2,624 constants. Of these, 334 user-facing names and 131 internal
  auxiliaries are named `OAI.*`, all under `OAI.SevenEighths`. The biggest groups are
  `OAI.SevenEighths.ProbePhysical` (63 names), `OAI.SevenEighths.ProbeHighRowFamily` (38) and
  `OAI.SevenEighths.V2CenteredMomentNaturalFixedRaySource` (26). An example on the proof path is
  `OAI.SevenEighths.V2ProbeFinalAssemblyCertifiedBands.chosen_moments_of_original_headline`, used
  by `RHV2.physical_probe_estimates`.

## 5. Kernel and axiom checks

All commands ran through `ARDA_LEAN_SLOTS=1 ~/hodge-engine/leanlock.sh`, on a workspace made by
`liu_materialize.sh --from-local ~/oai-replay --liu-local ~/liu-qrh`. OpenAI's closure came from
the replay's `.lake` and was not recompiled. Liu's 219 modules and the dbn port were compiled here.

| Check | Result |
|---|---|
| first `lake build ArdaLiuBridge ArdaDBNLiuChallenge ArdaDBNLiuNegativeControl` | Liu's 219 modules green with Liu's `warningAsError := true`, 10 min 16 s wall; then the Lake root-module failure below |
| same, after the glob fix | green, 12,117 jobs |
| `lake env lean AxiomGuardLiuBridge.lean` | 14 lines, every one `[propext, Classical.choice, Quot.sound]`, no `sorryAx` (`logs/axioms_2026-10-11.txt`) |
| `sorry`, `native_decide`, `axiom` in our modules | none (the challenges' `sorry` bodies are the Comparator convention) |

The 14 guarded names are our 11 theorems plus `CombinedPaper.algebraic_zeta_nonzero`,
`RHV2.zeta_nonzero` and `dbn_real_zeros_of_zeta_halfplane`.

**The Lake root-module quirk, explained.** Session 23 saw `unknown module RHZeroFreeExtension` and
worked around it by compiling the root file by hand. The cause is Lake 4.34's
`LeanLibConfig.isBuildableModule`. A library's root module is buildable only if one of the
library's globs matches it. The glob `` `RHZeroFreeExtension.+ `` matches submodules only. With
`.andSubmodules `RHZeroFreeExtension` the root builds normally, and no manual step is needed.

## 6. Comparator (independent judge)

Run locally on 2026-10-11 with the e9 toolchain: `~/e9-tools/comparator` (built with v4.34.1),
its pinned lean4export, nanoda ON, and the landrun pass-through shim. That means it was NOT
sandboxed, exactly as in the 2026-10-07 runs. The challenge `ArdaDBNLiuChallenge` imports only
Mathlib. Its `DBN.thetaMoment`, `DBN.Φ`, `DBN.HIntegrand` and `DBN.H` block is byte-identical
to `oai_qrh_bridge/lean/ArdaDBNChallenge.lean`, so the `DBN.H` it pins is the same term as the
registered 9/32 node's. The configs permit only `propext`, `Quot.sound` and `Classical.choice`.

```
## dbn_real_zeros_of_liu_unconditional   (challenge ArdaDBNLiuChallenge, solution ArdaDBNLiu)
nanoda kernel accepts the solution
Lean default kernel accepts the solution
Your solution is okay!
EXIT 0      492 s wall, 9.2 GB peak RSS

## liu_tampered   (challenge ArdaDBNLiuChallengeTampered: Φ with e^{8u} instead of e^{9u})
uncaught exception: Const does not match between challenge and target 'DBN.Φ'
EXIT 1      163 s wall, 9.2 GB peak RSS
```

The export list for the positive run held only the target theorem, the three permitted axioms
and Lean's builtin constants. The trimmed log is `liu_dbn_bridge/logs/comparator_2026-10-11.txt`.

## 7. Comparison with the session-23 scratch

Session peterwmurphy-23 built a scratch composition the same morning
(`~/arda-research/followups/liu/build-liu/ArdaLiuScratch.lean`, report
`~/arda-research/followups/liu_lean_rebuild.md`). We wrote our modules independently and then
compared. A scratch file in the materialized workspace, not committed, restates 23's statements
verbatim and proves each from ours in one term. Lean accepted all five, with standard axioms.

| 23's statement | ours | relation |
|---|---|---|
| `liu_zeta_halfplane` (via `def liuBoundary`, `RHV2.zeta_nonzero`) | `liu_zeta_zero_free` (explicit real, `CombinedPaper.algebraic_zeta_nonzero`) | identical up to unfolding `liuBoundary`; `algebraic_zeta_nonzero` is `RHV2.zeta_nonzero` |
| `dbn_real_zeros_of_liu` | `dbn_real_zeros_of_liu_unconditional` | identical up to unfolding |
| `liuBoundary_lt_seven_eighths` | `liuBoundary_lt_seven_eighths` | identical up to unfolding |
| `sqrt921_bounds`: 30.347 < √921 < 31 | `sqrt921_bounds`: width 1e-10 | ours is tighter |
| `dbn_real_zeros_ge_28119`: t ≥ 0.28119 | `dbn_real_zeros_ge_2811856084`, `dbn_real_zeros_ge_2811857` | ours are stronger |
| `dbn_real_zeros_of_liu_rational` at Liu's 34999/40000 | omitted | weaker than the algebraic bound |

Ours adds the closed form, `liuBoundary_bounds` and the comparison with 9/32. We avoid a new
`def` so that the challenge statement is a plain Mathlib expression. Two differences of method
matter. 23 bypassed the Lake root-module error by compiling the root file by hand; we fixed the
glob, as explained in section 5. 23's Comparator run targeted the 0.28119 corollary; ours
targets the exact theorem and adds the tampered control.

## 8. What this does not establish

- **Not RH.** A zero-free half-plane at Re s > 0.87496 is not the Riemann hypothesis, which is
  Re s > 1/2. Λ ≤ 0.2811856 is not RH either; RH is Λ ≤ 0.
- **Not independent of OpenAI.** Liu's argument bootstraps on OpenAI's 7/8 proof. A flaw in
  openai/math would propagate here. A flaw in Liu's own 32k new lines would have been caught by
  the kernel, which accepted them.
- **No human referee.** Nobody here has read Liu's TeX against Liu's Lean. Kernel acceptance says
  the Lean statements are proved, not that they match the paper's prose.
- **Registration in progress.** Three draft nodes are in PR #693, stacked on this branch. The
  licence question is settled by owner decision (section 3), and CI coverage is now active.
  Granting still needs the operator read-back and the Comparator judge record.

conjecture1_proved = False.
