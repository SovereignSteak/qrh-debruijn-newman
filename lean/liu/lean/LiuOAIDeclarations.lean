/-
  LiuOAIDeclarations -- provenance helper (run with `lake env lean LiuOAIDeclarations.lean`).
  Prints every constant whose name starts with `OAI.` but which is DECLARED in one of Liu's
  modules (RHZeroFreeExtension.*, geometry.*, analytic_low.*), i.e. Liu's additions to OpenAI's
  namespace.  Such names are not OpenAI's work even though they read like it.  Output lines:
  `LIU_OAI_DECL <module> <name>` for user-facing names, then summary counts.
-/
import ArdaLiuBridge

open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  let isLiu : Name → Bool := fun m =>
    let r := m.getRoot
    r == `RHZeroFreeExtension || r == `geometry || r == `analytic_low
  let mut pub : Array (String × String) := #[]
  let mut internal := 0
  let mut liuTotal := 0
  for (n, _) in env.constants.map₁.toList do
    let some idx := env.getModuleIdxFor? n | continue
    let m := env.header.moduleNames[idx.toNat]!
    unless isLiu m do continue
    liuTotal := liuTotal + 1
    unless n.getRoot == `OAI do continue
    if n.isInternalDetail then internal := internal + 1
    else pub := pub.push (m.toString, n.toString)
  let sorted := pub.qsort (fun a b => a.2 < b.2)
  for (m, n) in sorted do
    IO.println s!"LIU_OAI_DECL {m} {n}"
  let liuMods := env.header.moduleNames.filter isLiu
  IO.println s!"LIU_SUMMARY liu_modules={liuMods.size} liu_constants={liuTotal} oai_named_public={pub.size} oai_named_internal={internal}"
