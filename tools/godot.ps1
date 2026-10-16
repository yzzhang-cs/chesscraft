# tools/godot.ps1 - single source of truth for running Godot from the command line.
#
# Usage:
#   pwsh -NoProfile -File tools/godot.ps1 --version
#   pwsh -NoProfile -File tools/godot.ps1 --headless --path . --import
#   pwsh -NoProfile -File tools/godot.ps1 --headless --path . --script res://tests/smoke_test.gd
#
# Two things this wrapper handles so callers do not have to:
#
# 1. Binary choice. Always use the *_console.exe* build for command-line work.
#    The plain Godot_v4.7.2-stable_win64.exe is a GUI-subsystem binary, so its
#    stdout/stderr are not attached to the calling console and all output is lost.
#    Override the location with the GODOT_BIN environment variable.
#
# 2. Data-directory containment. Godot writes editor settings to %APPDATA%\Godot,
#    caches to %LOCALAPPDATA%\Godot, and a running game's user:// directory to
#    %APPDATA%\Godot\app_userdata\<project>. Under the agent sandbox those paths
#    are outside the writable workspace, which produced "Cannot save file" and
#    "Cannot create file" errors on every invocation. This wrapper points both
#    variables at repo-local directories instead, which also means agent runs
#    never overwrite the user's real editor settings.
#
#    Set GODOT_USE_SYSTEM_APPDATA=1 to opt out and use the real user profile.

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $GodotArgs
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

# --- 1. Locate the engine binary -------------------------------------------
$exe = $env:GODOT_BIN
if (-not $exe) {
    $candidates = @(
        (Join-Path $env:USERPROFILE 'Desktop\Godot_v4.7.2-stable_win64_console.exe'),
        'C:\Users\yzzhang\Desktop\Godot_v4.7.2-stable_win64_console.exe'
    )
    $exe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
    throw 'Godot console binary not found. Set $env:GODOT_BIN to the full path of Godot_v4.7.2-stable_win64_console.exe, or edit the candidate list in tools/godot.ps1.'
}

# The console build is a thin launcher that expects the full engine binary to
# sit beside it. Fail loudly rather than mysteriously.
$engineExe = $exe -replace '_console\.exe$', '.exe'
if ($exe -ne $engineExe -and -not (Test-Path -LiteralPath $engineExe)) {
    throw "Found '$exe' but its engine binary '$engineExe' is missing. Both files must stay in the same directory."
}

# --- 2. Contain writes inside the repo --------------------------------------
if ($env:GODOT_USE_SYSTEM_APPDATA -ne '1') {
    $localAppData = Join-Path $repoRoot '.godot-userdata\AppData\Roaming'
    $localCache = Join-Path $repoRoot '.godot-userdata\AppData\Local'
    New-Item -ItemType Directory -Force -Path $localAppData, $localCache | Out-Null
    $env:APPDATA = $localAppData
    $env:LOCALAPPDATA = $localCache
}

# --- 3. Run -----------------------------------------------------------------
& $exe @GodotArgs
exit $LASTEXITCODE
