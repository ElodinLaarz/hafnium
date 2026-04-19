# Validate GDScript using project.godot [debug] gdscript/warnings (same as editor/debug adapter).
# Usage: .\Hafnium\presubmit_godot_compile.ps1
# Optional: $env:GODOT_BIN = "C:\Path\To\Godot_console.exe"

$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot

$Godot = $env:GODOT_BIN
if (-not $Godot) { $Godot = "godot" }

if (-not (Get-Command $Godot -ErrorAction SilentlyContinue)) {
    $fallbacks = @(
        "$env:LOCALAPPDATA\Programs\Godot\Godot.exe",
        "C:\Program Files\Godot\Godot.exe"
    )
    foreach ($p in $fallbacks) {
        if (Test-Path $p) {
            $Godot = $p
            break
        }
    }
}

if (-not (Test-Path $Godot) -and -not (Get-Command $Godot -ErrorAction SilentlyContinue)) {
    Write-Error "Godot not found. Set GODOT_BIN or add Godot to PATH."
    exit 1
}

Write-Host "[presubmit_godot_compile] Using: $Godot"
Write-Host "[presubmit_godot_compile] Project: $ProjectDir"

$log = New-TemporaryFile
try {
    Write-Host "[presubmit_godot_compile] Importing assets..."
    & $Godot --path $ProjectDir --headless --import --quit 2>&1 | Set-Content -Path $log -Encoding UTF8
    if ($LASTEXITCODE -ne 0) {
        Get-Content $log
        exit $LASTEXITCODE
    }

    Write-Host "[presubmit_godot_compile] Running main loop briefly..."
    & $Godot --path $ProjectDir --headless --quit-after 120 2>&1 | Set-Content -Path $log -Encoding UTF8
    $runCode = $LASTEXITCODE

    Write-Host "----- Godot output (tail) -----"
    Get-Content $log -Tail 80

    $lines = Get-Content $log
    $hit = $lines | Where-Object {
        $_ -match '(ERROR:|SCRIPT ERROR:).*\.gd' -or
        $_ -match 'Parse Error:' -or
        $_ -match 'Compile Error:' -or
        $_ -match 'implicitly inferred static type'
    }
    if ($hit) {
        Write-Host "[presubmit_godot_compile] FAIL: GDScript errors detected:" -ForegroundColor Red
        $hit | ForEach-Object { Write-Host $_ }
        exit 1
    }

    if ($runCode -ne 0) {
        Write-Host "[presubmit_godot_compile] FAIL: Exit code $runCode" -ForegroundColor Red
        exit $runCode
    }

    Write-Host "[presubmit_godot_compile] OK." -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item $log -ErrorAction SilentlyContinue
}
