# liu_dbn_bridge: Liu's zero-free half-plane, fed to the de Bruijn-Newman converter

This island exists for one theorem:

```lean
theorem dbn_real_zeros_of_liu_unconditional :
    ∀ t : ℝ, 2 * ((1507 - 2 * Real.sqrt 921) / 1653 - 1 / 2) ^ 2 ≤ t →
      ∀ z : ℂ, DBN.H t z = 0 → z.im = 0
```

In words: every zero of the de Bruijn-Newman function H_t is real once t is at least
2(θ − 1/2)², where θ = (1507 − 2√921)/1653 ≈ 0.8749570698. In closed form the threshold is

```
Λ ≤ (1867057 − 10888·√921) / 5464818 = 0.28118560838475...
```

That is about 6.4e-5 better than the 9/32 = 0.28125 of `dbn_real_zeros_of_qrh_unconditional` on
the `oai_qrh_bridge` island. It is not RH, and it is a long way from Polymath15's 0.22.

The half-plane is not ours. It is Baiying Liu's (arXiv:2610.12234), and Liu's proof in turn
bootstraps on OpenAI's 7/8 theorem. Our contribution is the converter from a zero-free half-plane
to real zeros of H_t (the dbn island) and the two lines that join the pieces.

## Why this number matters

The rh-team's gate analysis (`~/rh-team/gates/gate0.md`, Addendum 2, 2026-10-11; see also PR
#684) found that when you push every parameter in OpenAI's quasi-Riemann-hypothesis argument as
far as its proved inputs allow, the binding constraint crosses the low-side bound at exactly
Liu's θ, to 8 digits. So Liu's half-plane is the proved-input optimum of that architecture, and
Λ ≤ 0.2811856 is the limit of this route. Going further needs a new idea, not better tuning.

## Credit, license and why nothing of Liu's is in this directory

- **Liu.** The zero-free half-plane `CombinedPaper.algebraic_zeta_nonzero` is Baiying Liu's work,
  from https://github.com/liubaiying101/Slightly-improved-zero-free-half-planes-for-the-quasi-Riemann-hypothesis
  at commit `7d10420de90efa2f082a06a342fc7accbd57ab37` (paper: arXiv:2610.12234).
- **OpenAI.** Liu's proof imports 2,925 modules of https://github.com/openai/math at commit
  `adc7f1241b42e322a6451854ab7e4b4c146bf78a`, released under the Apache License, Version 2.0.
- **Licence basis: owner decision 2026-10-11, no author grant on file.** Liu's repository has no
  LICENSE file and no licence or copyright line in any file. It is a derivative overlay on
  openai/math, whose Apache-2.0 grant covers OpenAI's code, not Liu's additions. The Arda owner
  ruled on 2026-10-11 that Liu's code is to be treated as Apache-2.0. Liu has granted nothing in
  writing. Attribution to Baiying Liu is kept everywhere. This directory still contains none of
  Liu's files. `liu_materialize.sh`
  fetches the pinned commit at build time into `work/`, which is gitignored. The only things we
  commit about Liu's code are its commit hash, a list of sha256 hashes of its files
  (`liu_sources.sha256`), the layout rule, and the names of the `OAI.*` declarations it adds.
- **CI is active** (`.github/workflows/liu-dbn-bridge.yml`, plus the `judge-liu-dbn-bridge` job in
  `missions-comparator.yml`). Both restore oai-qrh-bridge's build checkpoint read-only and save no
  cache of their own. Release waits on the missions governance path.

## Files

```
LIU_PIN                       Liu's repo, commit, paper, module counts
liu_sources.sha256            sha256 of each Liu file we use (hashes only, no content)
liu_materialize.sh            the recipe: OAI + Liu + dbn port + our modules, all hashes checked
liu_oai_declarations.txt      the OAI.* names that Liu's modules declare (provenance)
lean/ArdaLiuBridge.lean       Liu's half-plane with the pole closed; √921 bounds; θ < 7/8
lean/ArdaDBNLiu.lean          the unconditional theorem and its corollaries
lean/AxiomGuardLiuBridge.lean #print axioms for everything above
lean/LiuOAIDeclarations.lean  prints the OAI.* names declared in Liu's modules
lean/LiuOAIClashCheck.lean    scans every built OpenAI .olean for a name Liu also declares
lean/ArdaDBNLiuChallenge.lean Comparator challenge (Mathlib only + transcribed DBN.H)
lean/negative_control/        tampered challenge that Comparator must reject
lean/lakefile-stanza.lean     the lean_lib lines appended to OpenAI's lakefile
logs/                         recipe, axiom, clash-scan and Comparator logs
```

The full record is `telperion/docs/LIU_DBN_BRIDGE_2026-10-11.md`.

## Building it

```sh
cd telperion/examples/liu_dbn_bridge
./liu_materialize.sh                                   # network: clones openai/math and Liu
# or, from local copies (OAI_GIT defaults to ~/oai-math, a clean checkout at the pin):
./liu_materialize.sh --from-local ~/oai-replay --liu-local ~/liu-qrh
cd work/oai
lake update && lake exe cache get                      # fresh clone only
lake build ArdaLiuBridge ArdaDBNLiu AxiomGuardLiuBridge ArdaDBNLiuChallenge ArdaDBNLiuChallengeTampered
lake env lean AxiomGuardLiuBridge.lean
```

The recipe checks, and aborts on any mismatch:

1. the OpenAI tree equals `openai/math@adc7f124`;
2. Liu's files come from commit `7d10420` and match `liu_sources.sha256`;
3. Liu's `upstream/closure_manifest.json` pins the same OpenAI commit, and all 2,925 OpenAI modules
   it lists match their recorded sha256 in the workspace;
4. Liu's toolchain, every `lake-manifest` revision and both dependency patches equal OpenAI's;
5. no Liu file lands on a path that already exists.

Liu's GitHub tree is flattened. The recipe puts each file where Liu's own `import` lines expect
it. Top-level modules and `moment_adapters/` go under `RHZeroFreeExtension/`. Both `analytic_high/`
and `analytic_high_v2/` go into `RHZeroFreeExtension/analytic_high/`, with no name clashes.
`geometry/` and `analytic_low/` stay where they are.

Everything is one Lake workspace with OpenAI's package as the root. Liu's modules, the dbn port and
OpenAI's modules are imported together, so a Liu declaration that collided with one of OpenAI's
would fail the build as a duplicate declaration.

## What was checked locally (2026-10-11)

| Check | Result |
|---|---|
| `liu_materialize.sh --from-local ~/oai-replay --liu-local ~/liu-qrh` | all five checks passed |
| `lake build ArdaLiuBridge ArdaDBNLiuChallenge ArdaDBNLiuNegativeControl` | green, 12,117 jobs; Liu's modules built with `warningAsError` |
| `#print axioms`, 14 names | all `[propext, Classical.choice, Quot.sound]` |
| `OAI.*` names declared by Liu | 334 user-facing plus 131 internal, all under `OAI.SevenEighths` |
| clash scan over 3,232 OpenAI oleans | 0 clashes |
| Comparator, nanoda on, exact theorem vs Mathlib-only challenge | "nanoda kernel accepts", "Lean default kernel accepts", "Your solution is okay!" |
| Comparator on the tampered challenge | rejected: `Const does not match between challenge and target 'DBN.Φ'` |

Comparator ran locally on macOS with a pass-through landrun shim, so it was not sandboxed.

## Scope

A zero-free half-plane at Re s > 0.87496 is not the Riemann hypothesis, which needs Re s > 1/2.
Λ ≤ 0.2811856 is not RH either; RH is Λ ≤ 0. conjecture1_proved = False.
