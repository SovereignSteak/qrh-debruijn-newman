/-
  LiuOAIClashCheck -- provenance helper (run with `lake env lean LiuOAIClashCheck.lean`).
  The workspace build already proves that no Liu declaration collides with a declaration of the
  2,925 OpenAI modules Liu imports (a collision is a duplicate-declaration import error).  This
  script extends the check to EVERY built OpenAI module, including those outside Liu's closure:
  it reads each `.olean` under `.lake/build/lib/lean/OAI` without importing it, and reports any
  constant name also declared by one of Liu's modules.  Output: `LIU_CLASH <oai module> <name>`
  lines (expected: none) and one summary line.
-/
import ArdaLiuBridge

open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  let isLiu : Name → Bool := fun m =>
    let r := m.getRoot
    r == `RHZeroFreeExtension || r == `geometry || r == `analytic_low
  let mut liuNames : NameSet := {}
  for (n, _) in env.constants.map₁.toList do
    let some idx := env.getModuleIdxFor? n | continue
    if isLiu env.header.moduleNames[idx.toNat]! then liuNames := liuNames.insert n
  let imported : NameSet := env.header.moduleNames.foldl (·.insert ·) {}
  let root : System.FilePath := ".lake/build/lib/lean"
  let files ← (root / "OAI").walkDir
  let mut scanned := 0
  let mut outside := 0
  let mut clashes := 0
  for f in files do
    unless f.extension == some "olean" do continue
    let rel := f.toString.drop (root.toString.length + 1)
    let modName := (rel.dropRight 6).replace "/" "."
    let mod := modName.toName
    scanned := scanned + 1
    if imported.contains mod then continue
    outside := outside + 1
    let (data, region) ← readModuleData f
    for n in data.constNames do
      if liuNames.contains n then
        clashes := clashes + 1
        IO.println s!"LIU_CLASH {mod} {n}"
    region.free
  IO.println s!"LIU_CLASH_SUMMARY liu_constants={liuNames.size} oai_oleans_scanned={scanned} outside_liu_closure={outside} clashes={clashes}"
