#!/usr/bin/env bash
# Validate GDScript using the same compiler settings as the editor (project.godot [debug]
# gdscript/warnings -- e.g. untyped_declaration / inferred_declaration as errors).
#
# Usage (from repo root or elsewhere):
#   GODOT_BIN=/path/to/godot bash Hafnium/presubmit_godot_compile.sh
#
# Requires: Godot 4.x on PATH or GODOT_BIN.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
GODOT="${GODOT_BIN:-godot}"

if ! command -v "$GODOT" &>/dev/null && [[ ! -x "$GODOT" ]]; then
	echo "[presubmit_godot_compile] Godot not found. Set GODOT_BIN or install godot on PATH."
	exit 1
fi

echo "[presubmit_godot_compile] Using: $GODOT"
echo "[presubmit_godot_compile] Project: $PROJECT_DIR"

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "[presubmit_godot_compile] Importing assets..."
set +e
"$GODOT" --path "$PROJECT_DIR" --headless --import --quit >>"$LOG" 2>&1
imp=$?
set -e
if [[ "$imp" -ne 0 ]]; then
	echo "[presubmit_godot_compile] --import failed (exit $imp). Output:"
	cat "$LOG"
	exit "$imp"
fi

: >"$LOG"
echo "[presubmit_godot_compile] Running main loop briefly (loads autoloads + main scene)..."
set +e
"$GODOT" --path "$PROJECT_DIR" --headless --quit-after 120 >>"$LOG" 2>&1
run=$?
set -e

echo "----- Godot output (tail) -----"
tail -n 80 "$LOG" || true
echo "--------------------------------"

# Warnings promoted to errors and parse failures land as ERROR lines or contain these phrases.
if grep -E '(^ERROR:|^SCRIPT ERROR:).*\.gd|Parse Error:|Compile Error:|implicitly inferred static type' "$LOG" >&2; then
	echo "[presubmit_godot_compile] FAIL: GDScript errors detected (project treats many warnings as errors)."
	exit 1
fi

if [[ "$run" -ne 0 ]]; then
	echo "[presubmit_godot_compile] FAIL: Godot exited with code $run."
	exit "$run"
fi

echo "[presubmit_godot_compile] OK."
exit 0
