/-
  ArdaDBNLiu -- the de Bruijn-Newman bound Λ ≤ 2(θ - 1/2)² at Liu's boundary
  θ = (1507 - 2√921)/1653, i.e. Λ ≤ (1867057 - 10888√921)/5464818 ≈ 0.2811856084, UNCONDITIONAL
  and in ONE environment (Lean v4.34.1, Mathlib d13f23b, inside openai/math @ adc7f124 with Liu's
  overlay @ 7d10420 and the 19-module dbn single-pin port).

  `dbn_real_zeros_of_zeta_halfplane` is the dbn island's converter (DBNZeroFreeHalfplane, ported to
  this pin exactly as in ../oai_qrh_bridge; see telperion/docs/QRH_DBN_BRIDGE_2026-10-07.md §6).
  `liu_zeta_zero_free` is Liu's half-plane (arXiv:2610.12234), re-exported in ArdaLiuBridge.  Both
  are elaborated against the SAME `riemannZeta`: one kernel check, no cross-pin identification.

  This is the proved-input optimum of OpenAI's QRH architecture (see
  telperion/docs/LIU_DBN_BRIDGE_2026-10-11.md).  It improves 9/32 by about 6.4e-5.  Polymath15's
  0.22 is far stronger.  A zero-free half-plane is not RH; RH is Λ ≤ 0.  Nothing here proves RH.
  conjecture1_proved = False.
-/
import DBNZeroFreeHalfplane
import ArdaLiuBridge

/-- **Every zero of `H_t` is real for every `t ≥ 2((1507 - 2√921)/1653 - 1/2)²`**, unconditionally
(classically `Λ ≤ 0.28118560838...`): the dbn converter applied to Liu's zero-free half-plane, in
one environment.  Not RH.  conjecture1_proved = False. -/
theorem dbn_real_zeros_of_liu_unconditional :
    ∀ t : ℝ, 2 * ((1507 - 2 * Real.sqrt 921) / 1653 - 1 / 2) ^ 2 ≤ t →
      ∀ z : ℂ, DBN.H t z = 0 → z.im = 0 :=
  dbn_real_zeros_of_zeta_halfplane _ liu_zeta_zero_free

/-- The same bound with the threshold in closed form `(1867057 - 10888√921)/5464818`. -/
theorem dbn_real_zeros_of_liu_closed_form :
    ∀ t : ℝ, (1867057 - 10888 * Real.sqrt 921) / 5464818 ≤ t →
      ∀ z : ℂ, DBN.H t z = 0 → z.im = 0 := by
  intro t ht
  apply dbn_real_zeros_of_liu_unconditional t
  rw [liu_lambda_closed_form]
  exact ht

/-- Rational corollary at ten decimals: every zero of `H_t` is real for `t ≥ 0.2811856084`
(the exact threshold is `0.28118560838475...`). -/
theorem dbn_real_zeros_ge_2811856084 :
    ∀ t : ℝ, (2811856084 / 10000000000 : ℝ) ≤ t → ∀ z : ℂ, DBN.H t z = 0 → z.im = 0 := by
  intro t ht
  apply dbn_real_zeros_of_liu_closed_form t
  have h := sqrt921_bounds
  rw [div_le_iff₀ (by norm_num)]
  linarith [h.1, ht]

/-- Rational corollary at seven decimals: every zero of `H_t` is real for `t ≥ 0.2811857`. -/
theorem dbn_real_zeros_ge_2811857 :
    ∀ t : ℝ, (2811857 / 10000000 : ℝ) ≤ t → ∀ z : ℂ, DBN.H t z = 0 → z.im = 0 :=
  fun t ht ↦ dbn_real_zeros_ge_2811856084 t (le_trans (by norm_num) ht)

/-- The new threshold is strictly below the 9/32 of `dbn_real_zeros_of_qrh_unconditional`. -/
theorem liu_threshold_lt_nine_thirtyseconds :
    2 * ((1507 - 2 * Real.sqrt 921) / 1653 - 1 / 2) ^ 2 < (9 / 32 : ℝ) := by
  rw [liu_lambda_closed_form]
  have h := sqrt921_bounds
  rw [div_lt_iff₀ (by norm_num)]
  linarith [h.1]
