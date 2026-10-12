#!/bin/bash
# Materialize the v1.1.0 workspace for Lambda <= 0.2811857 (Liu's half-plane into the dbn converter).
#
# The recipe lives in the Arda repository (island telperion/examples/liu_dbn_bridge, tag qrh-liu-v1.1.0);
# this repository vendors our own files from that island (lean/liu/, lean/judge_liu/) and checks them byte
# for byte against the tag, then runs the island's liu_materialize.sh inside the Arda checkout. That script
# checks out an UNMODIFIED openai/math at the pinned commit, fetches Baiying Liu's Lean (arXiv:2610.12234)
# at the pinned commit and verifies every file by hash, adds the single-pin dbn port and our modules, and
# appends one lakefile stanza. Nothing of Liu's or OpenAI's code is stored in this repository.
#
# Licence basis for Liu's code: owner decision 2026-10-11, no grant from the author on file (his repository
# carries no LICENSE; a LICENSE has been requested). Attribution to Baiying Liu is kept.
#
#   scripts/materialize_liu.sh            # network: clones Arda at the tag, then openai/math and Liu
# Then, from work/arda/telperion/examples/liu_dbn_bridge/work/oai:
#   lake exe cache get
#   lake build ArdaLiuBridge AxiomGuardLiuBridge ArdaDBNLiuChallenge ArdaDBNLiuNegativeControl
#   lake env lean AxiomGuardLiuBridge.lean                                  # [propext, Classical.choice, Quot.sound]
#   lake env comparator dbn_real_zeros_of_liu_unconditional.comparator.json  # must accept (nanoda on)
#   lake env comparator negative_control/liu_tampered.comparator.json       # must REJECT
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TAG=qrh-liu-v1.1.0
ARDA="$HERE/work/arda"
mkdir -p "$HERE/work"
rm -rf "$ARDA"
git clone --depth 1 --branch "$TAG" https://github.com/DrMurphyIsIn/Arda.git "$ARDA"
ISL="$ARDA/telperion/examples/liu_dbn_bridge"
JDG="$ARDA/telperion/missions/judge/liu_dbn_bridge"
diff -rq -x work "$HERE/lean/liu" "$ISL" || { echo "vendored lean/liu differs from Arda $TAG"; exit 1; }
diff -rq "$HERE/lean/judge_liu" "$JDG" || { echo "vendored lean/judge_liu differs from Arda $TAG"; exit 1; }
for n in RH_zeta_zero_free_liu RH_dbn_real_zeros_of_liu_unconditional RH_dbn_real_zeros_ge_2811857; do
  cmp -s "$HERE/provenance/registry/$n.toml" "$ARDA/telperion/missions/rh/nodes/$n.toml" || { echo "record $n differs"; exit 1; }
done
echo "vendored copies verified byte-identical to Arda $TAG"
"$ISL/liu_materialize.sh"
echo "workspace: $ISL/work/oai"
