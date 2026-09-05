#!/usr/bin/env bash
#
# Overnight asset-breadth batch for Mars HAWC.
# Runs each generator in its own headless Blender process (memory: Blender is
# unstable — one asset per call), on the M1 Max Metal GPU, and writes a run log.
#
# Produces game-ready GLBs (procedural / derived-from-our-scans, licensing-safe),
# each with a Cycles ambient-occlusion pass composited into albedo:
#   godot/assets/basekit/   5 modular structure pieces  (ASSET_BUILD_LIST #11)
#   godot/assets/rockfield/ 16 scanned-rock variants     (terrain scatter)
#   godot/assets/props/     5 POI / set-dressing props   (world density)
#
# Usage:
#   tools/build_asset_breadth.sh            # run everything
#   tools/build_asset_breadth.sh props      # run one stage (basekit|rockfield|props)
#
set -euo pipefail

REPO="/Users/sinhaankur/Downloads/G-Nome_ISO"
BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"
LOG="$REPO/tools/asset_breadth.log"

cd "$REPO"

run_stage () {
  local name="$1" script="$2"
  echo "=== [$name] $(date '+%H:%M:%S') ===" | tee -a "$LOG"
  # --factory-startup = clean env; grep keeps the result lines + any errors
  "$BLENDER" --background --factory-startup --python "$script" 2>&1 \
    | grep -E "_OK|tris=|Error|Traceback|line [0-9]|Cannot" \
    | tee -a "$LOG"
  echo "" | tee -a "$LOG"
}

STAGE="${1:-all}"
echo "########## asset-breadth batch  $(date) ##########" | tee -a "$LOG"

case "$STAGE" in
  basekit)   run_stage basekit   tools/build_base_kit.py ;;
  rockfield) run_stage rockfield tools/build_rock_field.py ;;
  props)     run_stage props     tools/build_props.py ;;
  all)
    run_stage basekit   tools/build_base_kit.py
    run_stage props     tools/build_props.py
    run_stage rockfield tools/build_rock_field.py
    ;;
  *) echo "unknown stage: $STAGE (use basekit|rockfield|props|all)"; exit 1 ;;
esac

echo "########## done  $(date) ##########" | tee -a "$LOG"
echo ""
echo "Output GLBs:"
ls -1 godot/assets/basekit/*.glb godot/assets/props/*.glb godot/assets/rockfield/*.glb 2>/dev/null | sed 's/^/  /'
