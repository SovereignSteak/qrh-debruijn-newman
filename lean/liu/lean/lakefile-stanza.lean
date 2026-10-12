
-- ===== Arda liu_dbn_bridge (appended by telperion/examples/liu_dbn_bridge/liu_materialize.sh) =====
-- Baiying Liu's overlay (arXiv:2610.12234, commit 7d10420), fetched at build time, NOT vendored
-- (licence basis: owner decision 2026-10-11, no author grant on file).  Three libraries, matching Liu's own lakefile, with Liu's own
-- package options (autoImplicit false, warningAsError true).  The layout fix in the script puts
-- analytic_high_v2/* under RHZeroFreeExtension/analytic_high/ as the import graph requires.
lean_lib LiuRHZeroFreeExtension where
  roots := #[`RHZeroFreeExtension]
  -- `.andSubmodules`, not `.+`: Lake 4.34 builds a root module only if a glob matches it.
  globs := #[.andSubmodules `RHZeroFreeExtension]
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`warningAsError, true⟩]
lean_lib LiuGeometry where
  roots := #[]
  globs := #[`geometry.+]
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`warningAsError, true⟩]
lean_lib LiuAnalyticLow where
  roots := #[]
  globs := #[`analytic_low.+]
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`warningAsError, true⟩]
-- Single-pin port of the dbn island closure (identical to ../oai_qrh_bridge/lean/lakefile-stanza.lean).
lean_lib ArdaDBNPort where
  roots := #[`DBNZeroFreeHalfplane, `DBNRealZerosIffFinal, `DBNRealZerosIff, `DBNDefs, `DBNXi,
    `DBNXiIBP, `DBNGKernel, `DBNXiCos, `DBNXiRiemann, `DBNM1Parametric, `DBNM1Approx,
    `DBNHadamard, `DBNHadamardLinear, `DBNHadamardMean, `DBNHadamardProduct,
    `DBNHadamardCount, `DBNStep, `DBNHeatApprox, `DBNHurwitz]
  leanOptions := #[⟨`autoImplicit, true⟩]
lean_lib ArdaLiCriterionShim where
  roots := #[`Lc.XiZeros, `Lc.LiCriterion.Basic]
  leanOptions := #[⟨`autoImplicit, false⟩, ⟨`maxSynthPendingDepth, .ofNat 3⟩]
-- Our modules.
lean_lib ArdaLiuBridge where
  roots := #[`ArdaLiuBridge, `ArdaDBNLiu]
-- The axiom guard is its own lean_lib (as AxiomGuardQRHBridge in ../oai_qrh_bridge): the judge's
-- telperion/scripts/judge_materialize.sh requires a `lean_lib AxiomGuard...` line in the workspace.
lean_lib AxiomGuardLiuBridge where
  roots := #[`AxiomGuardLiuBridge]
lean_lib ArdaDBNLiuChallenge where
  roots := #[`ArdaDBNLiuChallenge]
-- Negative control: the challenge with Φ altered (e^{9u} -> e^{8u}); Comparator must reject it.
lean_lib ArdaDBNLiuNegativeControl where
  roots := #[`ArdaDBNLiuChallengeTampered]
