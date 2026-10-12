# Λ ≤ 9/32, and now Λ ≤ 0.2811857, kernel-checked

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23269134.svg)](https://doi.org/10.5281/zenodo.23269134)

The de Bruijn–Newman constant Λ is a single real number that encodes the Riemann Hypothesis.
Take the Riemann ξ function, write it as a Fourier transform, and let that transform evolve
under the backward heat equation for time t. For each t you get an entire function H_t, and
H_0 is ξ in disguise. De Bruijn showed in 1950 that once the zeros of H_t are all real they stay
real as t grows, so there is a threshold Λ: the zeros of H_t are all real exactly when t ≥ Λ.
Newman conjectured in 1976 that Λ ≥ 0, which Rodgers and Tao proved in 2020. The Riemann
Hypothesis is the statement Λ ≤ 0, and so, today, the statement Λ = 0.

Upper bounds on Λ have come down slowly. De Bruijn's own argument gives Λ ≤ 1/2. Ki, Kim and
Lee made that strict in 2009. The Polymath15 project brought it to 0.22 in 2019, and Platt and
Trudgian to 0.2 in 2021, both by computer-assisted analysis that lives outside any proof
assistant.

This repository records a bound that is far weaker than those two, and is the first one below
1/2 to be checked by a proof kernel end to end:

> **Every zero of H_t is real for every t ≥ 9/32.** Classically, Λ ≤ 9/32 = 0.28125.

## Where it comes from

Two theorems, and a one-line composition.

**The half-plane.** In October 2026 OpenAI released a Lean 4 proof that the Riemann zeta
function has no zero with real part greater than 7/8: a *quasi-Riemann hypothesis*, in their
phrase. Before it, every known zero-free region hugged the line Re s = 1 and thinned out at
height; no fixed vertical strip inside the critical strip had ever been cleared. The theorem,
`OAI.riemannZeta_ne_zero_of_seven_eighths_lt_re`, is theirs, Apache-2.0, in
[openai/math](https://github.com/openai/math) at commit `adc7f124`. We replayed it through
Comparator with a second kernel before touching it, and this repository re-exports it with one
added line (`lean/bridge/ArdaQRHBridge.lean`). Nothing here proves anything about ζ.

**The conversion.** De Bruijn's theorem, in the parametric form the Arda project formalized on
its dbn island: if every zero of H_0 has imaginary part at most y, then every zero of H_t is
real for t ≥ y²/2. A zero-free half-plane Re s > θ confines the zeros of H_0 to |Im z| ≤ 2θ − 1,
so Λ ≤ 2(θ − ½)². At θ = 1 this is de Bruijn's 1/2. At θ = 7/8 it is 9/32.

**The composition.** `dbn_real_zeros_of_qrh qrh_seven_eighths`. That is the whole proof term of
the theorem `dbn_real_zeros_of_qrh_unconditional` in `lean/bridge/ArdaDBNUnconditional.lean`.
The work was not in writing it. The work was in making the two sides meet in one Lean
environment, and then in checking the result harder than it needed to be checked.

## What was checked, and by what

The two theorems were born under different Mathlib pins, six weeks apart. The statement
`riemannZeta s ≠ 0` looks identical on both sides, but a lean4export comparison found 267
definitions underneath it that differ, from Mathlib's algebraic-hierarchy refactor down to the
core definition of `Bool.and`. Plugging one side into the other across that seam would have
been a mathematical identification, not a kernel check. So the nineteen modules of the de
Bruijn machinery were ported to OpenAI's exact pin, inside OpenAI's own workspace. Seventeen
ported byte-identically. Two needed a one-line proof repair each, recorded as patches in
`lean/patches/`. No statement and no definition changed. After that, the theorem is one kernel
term, and `#print axioms` says `[propext, Classical.choice, Quot.sound]`.

Then the layers of checking:

- **A second kernel.** openai/ten-proofs Comparator re-exports the theorem and replays it
  through Lean's kernel and through nanoda, against a challenge file that imports only Mathlib
  and transcribes the definition of H_t verbatim. Both kernels accept. A tampered challenge, with
  one exponent in the Polymath15 kernel changed from 9 to 8, is rejected.
- **An independent audit.** A second session, from a fresh checkout, rebuilt everything, diffed
  every ported file against its source, verified OpenAI's statement and pins from GitHub, and
  re-ran all three Comparator configurations with its own Comparator and nanoda builds
  (`docs/QRH_DBN_AUDIT_2026-10-07_e9.md`).
- **Continuous integration.** The Arda CI job materializes OpenAI's checkout cold, builds,
  re-elaborates the committed artifacts, checks the guards and runs the Comparator stage on
  every push (`provenance/arda-oai-qrh-bridge.yml`; this repository's `verify.yml` does the same).
- **A registry with teeth.** The result is four nodes in Arda's missions registry. The
  operator, not the authoring session, wrote the read-backs under his own identity; the verify
  gate granted them against their artifacts; and a separate CI judge re-proved each registered
  statement from the artifact, with both kernels, before the pass was recorded with the artifact
  hashed at the judged commit (`provenance/registry/`, `logs/ci_judge_run_37955041118.txt`).

What remains trusted as code rather than checked: Mathlib's definition of `riemannZeta`, the
pinned OpenAI tree (verified byte-for-byte against the commit, never modified), Lean's kernel,
and nanoda. That is the same trust the result rests on anyway.

## Version 1.1: Λ ≤ 0.2811857, from Liu's improvement of the half-plane

Three days after OpenAI's release, Baiying Liu posted "Slightly improved zero-free half-planes for the
quasi-Riemann hypothesis" (arXiv:2610.12234, 8 October 2026). Following OpenAI's own argument and varying
two of its length parameters, it moves the half-plane from Re s > 7/8 to

    Re s > B = (1507 − 2√921)/1653 = 0.8749570698…,

with a Lean formalization at OpenAI's exact pin. The same converter then gives

> **Every zero of H_t is real for every t ≥ 2(B − ½)² = (1867057 − 10888√921)/5464818 = 0.2811856…**
> Classically, Λ ≤ 0.2811857.

That is 6.4·10⁻⁵ below 9/32. The gain is small, and it is not going to get much bigger along this route:
an independent modelling of OpenAI's method by the Arda team (its "thread C" loss ledger, Addendum 2) puts the
optimum of the whole architecture with proved inputs at σ₀ = 0.87495707, the same number to eight digits, with
the same √921 arising from the binding constraint (the team's earlier, coarser model had predicted 0.87498). So
this is the limit of OpenAI's method, formalized by its first improver, and converted.

**What was checked.** In one Lean workspace (openai/math at adc7f124, Liu's Lean at commit 7d10420, the
single-pin dbn port), `liu_zeta_zero_free` re-exports Liu's `CombinedPaper.algebraic_zeta_nonzero` and
`dbn_real_zeros_of_liu_unconditional` composes it with de Bruijn's theorem, with the rational headline
`dbn_real_zeros_ge_2811857`; the axiom guard prints `[propext, Classical.choice, Quot.sound]` for every line.
Liu's theorem was replayed independently: his upload had to be reconstructed to build (the vendored OpenAI
closure was missing and the module tree flattened; both repaired by hash-verified copies), then built green
(12,088 jobs) with standard axioms; his `s ≠ 1` hypothesis turns out to be unused. Comparator with nanoda
accepts the composed theorem against a challenge that imports only Mathlib and rejects the tampered control,
both in CI (Arda workflow liu-dbn-bridge) and in the registry judge, which replayed all three registered
statements (judge run 38179118143; transcript in `logs/`). The three registry nodes were read back by the
operator himself before they were granted (`provenance/registry/`).

**Provenance and licence.** Nothing of Liu's or OpenAI's code is stored here. `scripts/materialize_liu.sh`
clones Arda at tag `qrh-liu-v1.1.0`, checks this repository's vendored files (`lean/liu/`, `lean/judge_liu/`,
the node records) byte for byte against it, and runs the island's materialize script, which fetches openai/math
and Liu's repository at their pinned commits and verifies every file by hash. Liu's repository carries no
LICENSE; it is treated as Apache-2.0 by the owner's decision of 11 October 2026, with no grant from the author
on file, and attribution to Baiying Liu kept. A LICENSE has been requested from him. The theorem that the
half-plane holds is his, built on OpenAI's.

## What this does and does not advance

It does not move the frontier on Λ. The bound 9/32 is weaker than 0.22, and 0.22 is weaker than
0.2. It does not move the frontier on the Riemann Hypothesis: Λ = 0 is RH, and the conversion
from a half-plane is lossy by nature. Even a half-plane at ½ + ε would only give Λ ≤ 2ε².

What it does: it is the first bound on Λ below de Bruijn's 1/2 that is a kernel-checked theorem
rather than a computation; it is a verified, reusable conversion, so any future improvement in
the half-plane drops straight into the machinery and yields a certified bound; and it is a
worked example of what it takes to compose formal results across incompatible library pins
honestly. One number from the paper is worth keeping in mind: a zero-free half-plane at about
0.83 would beat the numerical record through this route. OpenAI's 7/8 = 0.875 is just short.

## The paper

`paper/paper.pdf`, CC-BY-4.0; archived with this repository at Zenodo, DOI [10.5281/zenodo.23324360](https://doi.org/10.5281/zenodo.23324360) for v1.1.0, [10.5281/zenodo.23269135](https://doi.org/10.5281/zenodo.23269135) for v1.0.0, and [10.5281/zenodo.23269134](https://doi.org/10.5281/zenodo.23269134) for all versions. It states the two theorems as formalized, walks through the
composition, documents the cross-pin seam and the single-pin port, lays out the verification
chain with a trust table, and says plainly what is and is not established.

The arXiv source package is `paper/arxiv.tar.gz` and the submission metadata is in `paper/ARXIV.md`;
the arXiv identifier will be added here once assigned.

## Reproducing it

You need Lean 4 (elan), about 25 GB of disk, and a few CPU-hours the first time.

```sh
scripts/materialize.sh          # openai/math at the pin, with this repository's files inside it
cd work/oai
lake update && lake exe cache get
lake build ArdaQRHBridge AxiomGuardQRHBridge ArdaDBNUnconditional ArdaDBNChallenge ArdaDBNNegativeControl
lake env lean AxiomGuardDBNUnconditional.lean      # [propext, Classical.choice, Quot.sound], no sorryAx
```

For v1.1's Λ ≤ 0.2811857 (`.github/workflows/verify-liu.yml` is the exact recipe):

```sh
scripts/materialize_liu.sh      # Arda at qrh-liu-v1.1.0 (vendored copies checked), openai/math + Liu at pins
cd work/arda/telperion/examples/liu_dbn_bridge/work/oai
lake update && lake exe cache get
lake build ArdaLiuBridge ArdaDBNLiu AxiomGuardLiuBridge ArdaDBNLiuChallenge ArdaDBNLiuChallengeTampered
lake env lean AxiomGuardLiuBridge.lean                                   # [propext, Classical.choice, Quot.sound]
lake env comparator dbn_real_zeros_of_liu_unconditional.comparator.json   # must accept
lake env comparator liu_tampered.comparator.json                         # must REJECT
```

For the Comparator stage, build [leanprover/comparator](https://github.com/leanprover/comparator)
at tag v4.34.0 with its `lean-toolchain` set to v4.34.1 (there is no v4.34.1 tag), build
[nanoda](https://github.com/ammkrn/nanoda_lib), and run `lake env comparator <config>.json` on
the five configs now in `work/oai`. The positive ones must say "Your solution is okay!"; the
tampered one must fail with `Const does not match`. `.github/workflows/verify.yml` is the exact
recipe.

## Layout

```
lean/liu/         v1.1: our liu_dbn_bridge island (bridge, guards, challenges, materialize recipe, Liu file hashes)
lean/judge_liu/   v1.1: the registry judge bundle for the three Liu nodes
lean/bridge/      the re-export, the unconditional theorem, guards, challenges, Comparator configs
lean/dbn/         the nineteen de Bruijn modules, byte-identical to the Arda dbn island
lean/patches/     the two one-line proof repairs for OpenAI's Mathlib pin
lean/Lc/          the LiCriterion shim (ξ as an entire function; Apache-2.0, see lean/Lc/NOTICE)
lean/fidelity/    the cross-pin comparison of riemannZeta and its 27 root causes
lean/judge/       the registry judge bundle: challenges whose TYPE is the registered statement
scripts/          materialize.sh
logs/             Comparator transcripts, local and CI
docs/             the design document, the independent audit, the judge review
provenance/       registry records, the Arda source commit, the Arda CI workflow
paper/            the paper
```

## Credit

The half-plane theorem is OpenAI's. The de Bruijn machinery, the bridge, the port, the audit and
this paper were produced with extensive use of an AI coding assistant (Claude, Anthropic) under
the direction of the author; see `NOTICE.md`. Licensing in `LICENSING.md`. Not yet refereed.
