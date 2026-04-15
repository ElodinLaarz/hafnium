# run_tests.ps1
# Helper script to run Godot GUT tests headlessly.

$GodotPath = "godot"
$CommonPaths = @(
    "$HOME\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe",
    "C:\Program Files\Godot\Godot.exe"
)

# Check if Godot is in PATH
if (-not (Get-Command $GodotPath -ErrorAction SilentlyContinue)) {
    $found = $false
    foreach ($path in $CommonPaths) {
        if (Test-Path $path) {
            $GodotPath = $path
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Error "Godot executable not found in PATH or common locations."
        Write-Host "Please add Godot to your PATH or set the `$GodotPath variable in this script." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Running tests with Godot at: $GodotPath" -ForegroundColor Cyan

& $GodotPath --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
