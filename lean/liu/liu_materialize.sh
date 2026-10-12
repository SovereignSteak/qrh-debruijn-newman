#!/bin/bash
# Materialize the liu_dbn_bridge workspace.  ONE Lake workspace, rooted at an UNMODIFIED checkout of
# openai/math (pinned in ../oai_qrh_bridge/OAI_PIN), into which this script places
#   (a) Baiying Liu's Lean sources (arXiv:2610.12234) at the commit pinned in LIU_PIN, re-laid-out
#       to match their own import graph (the GitHub tree is flattened, see LAYOUT below);
#   (b) the 19-module single-pin port of the Arda dbn island (same recipe as oai_qrh_bridge);
#   (c) our own modules from lean/ and one appended lakefile stanza.
#
# LICENSE NOTE.  Licence basis: owner decision 2026-10-11, no author grant on file.  Liu's
# repository has no LICENSE file; the Arda owner ruled it is to be treated as Apache-2.0, with
# attribution to Baiying Liu kept.  Nothing of it is committed to Arda: this script fetches it at
# build time into work/ (gitignored).
#
# Usage: liu_materialize.sh [--from-local OAI_DIR] [--liu-local LIU_GIT_DIR]
#   --from-local OAI_DIR  reflink-copy (cp -c, APFS) an already-built copy of openai/math's lean/
#                         directory whose sources equal the pinned commit (checked file by file
#                         against the pinned git checkout $OAI_GIT, default ~/oai-math).  Default:
#                         clone openai/math at the pin (network).
#   --liu-local DIR       take Liu's files from a local git clone (read through `git archive` at
#                         the pinned commit, so untracked files in DIR are ignored).  Default:
#                         clone Liu's repository (network).
# Verification performed (any failure aborts):
#   1. OAI tree = openai/math@adc7f124 (diff -rq against the pinned checkout, or a fresh clone).
#   2. Liu's commit = LIU_PIN, and every one of Liu's files we use matches liu_sources.sha256.
#   3. Liu's upstream/closure_manifest.json pins the same OAI commit, and all 2925 listed OAI
#      modules in the workspace match its sha256 values.
#   4. Liu's lean-toolchain, lake-manifest revisions and its two dependency patches equal OpenAI's.
#   5. No file of Liu's lands on an existing path (no upstream file is overwritten).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
QRH="$HERE/../oai_qrh_bridge"
. "$QRH/OAI_PIN"
. "$HERE/LIU_PIN"
WORK="$HERE/work/oai"
OAI_LOCAL=""; LIU_LOCAL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --from-local) OAI_LOCAL="$2"; shift 2 ;;
    --liu-local)  LIU_LOCAL="$2"; shift 2 ;;
    *) echo "unknown argument $1"; exit 2 ;;
  esac
done
mkdir -p "$HERE/work"

# ---- 1. openai/math at the pin -------------------------------------------------------------
if [ -n "$OAI_LOCAL" ]; then
  GIT="${OAI_GIT:-$HOME/oai-math}"
  [ "$(git -C "$GIT" rev-parse HEAD)" = "$commit" ] || { echo "OAI_GIT is not at $commit"; exit 1; }
  diff -rq "$GIT/$subdir" "$OAI_LOCAL" -x .lake -x .git -x replay_configs -x replay_logs \
       -x REPLAY_REPORT.md -x ReplayChecks || { echo "OAI source tree differs from $commit"; exit 1; }
  rm -rf "$WORK"; cp -c -R "$OAI_LOCAL" "$WORK" 2>/dev/null || cp -R "$OAI_LOCAL" "$WORK"
else
  rm -rf "$HERE/work/math"
  git clone --no-checkout "$repo" "$HERE/work/math"
  git -C "$HERE/work/math" checkout --detach "$commit"
  rm -rf "$WORK"; mv "$HERE/work/math/$subdir" "$WORK"
fi
echo "[1/5] OAI tree = openai/math $commit"

# ---- 2. Liu's sources at the pin -----------------------------------------------------------
LIU="$HERE/work/liu-src"
rm -rf "$LIU"; mkdir -p "$LIU"
if [ -n "$LIU_LOCAL" ]; then
  git -C "$LIU_LOCAL" cat-file -e "$liu_commit^{commit}" || { echo "Liu commit $liu_commit not in $LIU_LOCAL"; exit 1; }
  git -C "$LIU_LOCAL" archive "$liu_commit" | tar -x -C "$LIU"
else
  rm -rf "$HERE/work/liu-git"
  git clone --no-checkout "$liu_repo" "$HERE/work/liu-git"
  git -C "$HERE/work/liu-git" archive "$liu_commit" | tar -x -C "$LIU"
fi
(cd "$LIU" && shasum -a 256 -c --quiet "$HERE/liu_sources.sha256") || { echo "Liu sources differ from liu_sources.sha256"; exit 1; }
n_lean=$(cd "$LIU" && find . -name '*.lean' ! -name lakefile.lean | wc -l | tr -d ' ')
[ "$n_lean" = "$liu_lean_modules" ] || { echo "expected $liu_lean_modules Liu modules, found $n_lean"; exit 1; }
echo "[2/5] Liu tree = $liu_commit ($n_lean modules, sha256 list matched)"

# ---- 3 + 4. Liu's own pins against the workspace ------------------------------------------
python3 - "$LIU" "$WORK" "$commit" "$liu_manifest_modules" <<'PY'
import hashlib, json, os, sys
liu, work, commit, nmods = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
man = json.load(open(os.path.join(liu, "upstream/closure_manifest.json")))
assert man["commit"] == commit, f"closure manifest pins {man['commit']}, not {commit}"
mods = man["modules"]
assert len(mods) == nmods, f"closure manifest lists {len(mods)} modules, expected {nmods}"
bad = []
for name, rec in mods.items():
    rel = rec["path"]
    assert rel.startswith("vendor/"), rel
    p = os.path.join(work, rel[len("vendor/"):])
    h = hashlib.sha256(open(p, "rb").read()).hexdigest() if os.path.exists(p) else None
    if h != rec["sha256"]:
        bad.append(name)
assert not bad, f"{len(bad)} OAI modules differ from Liu's closure manifest, e.g. {bad[:5]}"
lm = json.load(open(os.path.join(liu, "lake-manifest.json")))
om = json.load(open(os.path.join(work, "lake-manifest.json")))
orev = {p["name"]: p.get("rev") for p in om["packages"]}
diff = [p["name"] for p in lm["packages"] if orev.get(p["name"]) != p.get("rev")]
assert not diff, f"Liu's lake-manifest revisions differ from OpenAI's for {diff}"
print(f"[3/5] closure manifest: {len(mods)} OAI modules match by sha256 at {commit}")
print(f"[4/5] Liu's lake-manifest: {len(lm['packages'])} packages, all revisions equal OpenAI's")
PY
[ "$(cat "$LIU/lean-toolchain")" = "$(cat "$WORK/lean-toolchain")" ] || { echo "Liu toolchain differs"; exit 1; }
for p in PrimeNumberTheoremAnd rellich-kondrachov; do
  cmp -s "$LIU/upstream/$p-lean4341.patch" "$WORK/patches/$p-lean4341.patch" \
    || { echo "Liu's $p patch differs from OpenAI's"; exit 1; }
done

# ---- 5. LAYOUT: place Liu's modules where their import graph expects them -------------------
#   RHZeroFreeExtension.lean            -> RHZeroFreeExtension.lean
#   <root>/X.lean (other)               -> RHZeroFreeExtension/X.lean
#   analytic_high/X, analytic_high_v2/X -> RHZeroFreeExtension/analytic_high/X  (no name clashes)
#   moment_adapters/X                   -> RHZeroFreeExtension/moment_adapters/X
#   geometry/X, analytic_low/X          -> unchanged
place() {  # place SRC DST: refuse to overwrite anything already in the workspace
  [ -e "$WORK/$2" ] && { echo "layout clash: $2 already exists in the workspace"; exit 1; }
  mkdir -p "$(dirname "$WORK/$2")"; cp "$LIU/$1" "$WORK/$2"
}
placed=0
while IFS= read -r f; do
  f="${f#./}"
  case "$f" in
    lakefile.lean) continue ;;
    RHZeroFreeExtension.lean) dst="$f" ;;
    analytic_high/*|analytic_high_v2/*) dst="RHZeroFreeExtension/analytic_high/${f#*/}" ;;
    moment_adapters/*) dst="RHZeroFreeExtension/$f" ;;
    geometry/*|analytic_low/*) dst="$f" ;;
    */*) echo "unexpected Liu path $f"; exit 1 ;;
    *) dst="RHZeroFreeExtension/$f" ;;
  esac
  place "$f" "$dst"; placed=$((placed + 1))
done < <(cd "$LIU" && find . -name '*.lean' | sort)
[ "$placed" = "$liu_lean_modules" ] || { echo "placed $placed, expected $liu_lean_modules"; exit 1; }
echo "[5/5] placed $placed Liu modules (no existing path overwritten)"

# ---- dbn single-pin port (identical to ../oai_qrh_bridge/materialize.sh) -------------------
DBN="$HERE/../dbn/lean"
for m in DBNZeroFreeHalfplane DBNRealZerosIffFinal DBNRealZerosIff DBNDefs DBNXi DBNXiIBP \
         DBNGKernel DBNXiCos DBNXiRiemann DBNM1Parametric DBNM1Approx DBNHadamard \
         DBNHadamardLinear DBNHadamardMean DBNHadamardProduct DBNHadamardCount DBNStep \
         DBNHeatApprox DBNHurwitz; do
  cp "$DBN/$m.lean" "$WORK/$m.lean"
done
for pf in "$QRH"/dbn_port/patches/*.patch; do
  [ -e "$pf" ] || continue
  (cd "$WORK" && patch -p1 --no-backup-if-mismatch < "$pf")
done
mkdir -p "$WORK/Lc/LiCriterion"
cp "$QRH/dbn_port/Lc/XiZeros.lean" "$WORK/Lc/XiZeros.lean"
cp "$QRH/dbn_port/Lc/LiCriterion/Basic.lean" "$WORK/Lc/LiCriterion/Basic.lean"

# ---- our modules, Comparator configs, stanza ---------------------------------------------
cp "$HERE/lean/"*.lean "$WORK/"; rm -f "$WORK/lakefile-stanza.lean"
cp "$HERE/lean/"*.comparator.json "$WORK/"
cp "$HERE/lean/negative_control/"*.lean "$HERE/lean/negative_control/"*.json "$WORK/"
cat "$HERE/lean/lakefile-stanza.lean" >> "$WORK/lakefile.lean"
[ "$(cat "$WORK/lean-toolchain")" = "$toolchain" ] || { echo "toolchain mismatch"; exit 1; }
grep -q "\"rev\": \"$mathlib\"" "$WORK/lake-manifest.json" || { echo "mathlib pin mismatch"; exit 1; }
rm -rf "$LIU" "$HERE/work/liu-git" "$HERE/work/math"
cat <<MSG
Materialized at $WORK (openai/math $commit + Liu $liu_commit, $toolchain, Mathlib $mathlib).
Next, from $WORK:
  lake update            # only on a fresh clone: OAI's hooks clone + patch its dependencies
  lake exe cache get     # Mathlib oleans
  lake build ArdaLiuBridge ArdaDBNLiu AxiomGuardLiuBridge ArdaDBNLiuChallenge ArdaDBNLiuChallengeTampered
  lake env lean AxiomGuardLiuBridge.lean
  lake env comparator dbn_real_zeros_of_liu_unconditional.comparator.json
  lake env comparator liu_tampered.comparator.json      # must be REJECTED
MSG
