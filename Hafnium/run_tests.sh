#!/bin/bash
# run_tests.sh
# Helper script to run Godot GUT tests headlessly.

PROJECT_DIR=$(dirname "$0")
cd "$PROJECT_DIR"

if command -v godot &> /dev/null
then
    GODOT_BIN="godot"
elif [ -f "./godot.x86_64" ]; then
    GODOT_BIN="./godot.x86_64"
elif [ -f "/usr/bin/godot" ]; then
    GODOT_BIN="/usr/bin/godot"
else
    echo "Godot executable not found in PATH or standard locations."
    echo "Please add Godot to your PATH."
    exit 1
fi

echo "Running tests with Godot: $GODOT_BIN"

$GODOT_BIN --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
