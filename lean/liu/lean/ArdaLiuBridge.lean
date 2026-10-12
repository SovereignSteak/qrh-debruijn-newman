/-
  ArdaLiuBridge -- Baiying Liu's zero-free half-plane for ζ (arXiv:2610.12234), re-exported in the
  exact shape consumed by the Arda dbn converter `dbn_real_zeros_of_zeta_halfplane`.

  CREDIT.  The proof is entirely Liu's: `CombinedPaper.algebraic_zeta_nonzero`
  (CombinedPaperVerification.lean in
  github.com/liubaiying101/Slightly-improved-zero-free-half-planes-for-the-quasi-Riemann-hypothesis
  at commit 7d10420de90efa2f082a06a342fc7accbd57ab37), which bootstraps on OpenAI's 7/8 theorem from
  github.com/openai/math at adc7f1241b42e322a6451854ab7e4b4c146bf78a (Apache-2.0).

  LICENSE / PROVENANCE.  Licence basis: owner decision 2026-10-11, no author grant on file (Liu's
  repository has no LICENSE file; the Arda owner ruled it is to be treated as Apache-2.0; author
  attribution to Baiying Liu kept).  None of Liu's files is vendored into
  Arda: ../liu_materialize.sh fetches the pinned commit at build time and lays it out inside an
  unmodified openai/math workspace.  This file adds only (i) the closure over Liu's pole
  hypothesis `s ≠ 1` (discharged by Mathlib's `riemannZeta_one_ne_zero`), with Liu's boundary
  `B_new` written as an explicit real, and (ii) elementary facts about that real.

  Toolchain: Lean v4.34.1, Mathlib d13f23b723b8a846827a245b89c10fc7d3f11612 (OpenAI's and Liu's pins).

  SCOPE.  Re s > 0.87495707 is NOT the Riemann hypothesis (RH is Re s > 1/2).  Nothing here
  proves RH.  conjecture1_proved = False.
-/
import RHZeroFreeExtension.CombinedPaperVerification

/-- Liu's boundary `B_new` is, by definition, the explicit real `(1507 - 2√921)/1653`. -/
theorem liu_boundary_eq : CombinedPaper.B_new = (1507 - 2 * Real.sqrt 921) / 1653 := rfl

/-- **Liu's zero-free half-plane for ζ**: `ζ(s) ≠ 0` for `Re s > (1507 - 2√921)/1653 ≈ 0.874957`.
Liu's `CombinedPaper.algebraic_zeta_nonzero` with the pole hypothesis `s ≠ 1` closed by
`riemannZeta_one_ne_zero`.  The statement is word for word the hypothesis `hfree` of
`dbn_real_zeros_of_zeta_halfplane` at `θ = (1507 - 2√921)/1653`.  Not RH. -/
theorem liu_zeta_zero_free :
    ∀ s : ℂ, (1507 - 2 * Real.sqrt 921) / 1653 < s.re → riemannZeta s ≠ 0 := by
  intro s hs
  by_cases h1 : s = 1
  · subst h1
    exact riemannZeta_one_ne_zero
  · exact CombinedPaper.algebraic_zeta_nonzero s hs h1

/-- Two-sided rational enclosure of `√921 = 30.347981810987...`, width `10⁻¹⁰`. -/
theorem sqrt921_bounds :
    (303479818109 / 10000000000 : ℝ) < Real.sqrt 921 ∧
      Real.sqrt 921 < (303479818110 / 10000000000 : ℝ) := by
  constructor
  · rw [Real.lt_sqrt (by norm_num)]; norm_num
  · rw [Real.sqrt_lt' (by norm_num)]; norm_num

/-- Liu's boundary is strictly below OpenAI's `7/8`. -/
theorem liuBoundary_lt_seven_eighths : (1507 - 2 * Real.sqrt 921) / 1653 < (7 / 8 : ℝ) := by
  have h := sqrt921_bounds
  rw [div_lt_iff₀ (by norm_num)]
  linarith [h.1]

/-- Decimal enclosure of Liu's boundary: `0.8749570697 < θ < 0.8749570698`. -/
theorem liuBoundary_bounds :
    (8749570697 / 10000000000 : ℝ) < (1507 - 2 * Real.sqrt 921) / 1653 ∧
      (1507 - 2 * Real.sqrt 921) / 1653 < (8749570698 / 10000000000 : ℝ) := by
  have h := sqrt921_bounds
  constructor
  · rw [lt_div_iff₀ (by norm_num)]; linarith [h.2]
  · rw [div_lt_iff₀ (by norm_num)]; linarith [h.1]

/-- The de Bruijn-Newman threshold of Liu's boundary in closed form:
`2(θ - 1/2)² = (1867057 - 10888√921)/5464818` for `θ = (1507 - 2√921)/1653`. -/
theorem liu_lambda_closed_form :
    2 * ((1507 - 2 * Real.sqrt 921) / 1653 - 1 / 2) ^ 2
      = (1867057 - 10888 * Real.sqrt 921) / 5464818 := by
  have hx : Real.sqrt 921 ^ 2 = 921 := Real.sq_sqrt (by norm_num)
  linear_combination (32 / 10929636 : ℝ) * hx
