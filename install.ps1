# yt-tui installer for Windows.
#   .\install.ps1                     install from this checkout
#   irm https://raw.githubusercontent.com/YajatGhule/yt-tui/main/install.ps1 | iex
# Installs to %LOCALAPPDATA%\Programs\yt-tui and adds it to your user PATH.
$RepoRaw = "https://raw.githubusercontent.com/YajatGhule/yt-tui/main"
$Dest = Join-Path $env:LOCALAPPDATA "Programs\yt-tui"

function Say($msg) { Write-Host "> $msg" -ForegroundColor Red }
function Warn($msg) { Write-Host "! $msg" -ForegroundColor Yellow }
function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# Find a real Python 3 (skip the Microsoft Store stub).
$Python = $null
foreach ($cand in "py -3", "python", "python3") {
    $cmd, $extra = $cand -split " "
    if (-not (Has $cmd)) { continue }
    $exe = & $cmd @($extra | Where-Object { $_ }) -c "import sys; print(sys.executable)" 2>$null
    if ($LASTEXITCODE -eq 0 -and $exe) { $Python = $exe.Trim(); break }
}
if (-not $Python) {
    Warn "Python 3 not found. Install it with: winget install Python.Python.3.12"
    exit 1
}
Say "Using Python at $Python"

# curses is not bundled with Python on Windows.
& $Python -c "import curses" 2>$null
if ($LASTEXITCODE -ne 0) {
    Say "Installing windows-curses"
    & $Python -m pip install --user --quiet windows-curses
}

if (-not (Has "yt-dlp")) {
    if (Has "winget") { Say "Installing yt-dlp"; winget install --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements }
    else { Warn "yt-dlp not found. Install it from https://github.com/yt-dlp/yt-dlp/releases" }
}
if (-not (Has "ffmpeg")) {
    if (Has "winget") { Say "Installing ffmpeg"; winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements }
    else { Warn "ffmpeg not found (needed for merging and audio). Get it from https://ffmpeg.org" }
}

New-Item -ItemType Directory -Force -Path $Dest -ErrorAction Stop | Out-Null
$Script = Join-Path $Dest "yt-tui.py"
$Local = if ($PSScriptRoot) { Join-Path $PSScriptRoot "yt-tui" } else { $null }
if ($Local -and (Test-Path $Local)) {
    Copy-Item $Local $Script -Force -ErrorAction Stop
} else {
    Say "Downloading yt-tui"
    Invoke-WebRequest "$RepoRaw/yt-tui" -OutFile $Script -UseBasicParsing -ErrorAction Stop
}
Set-Content -Path (Join-Path $Dest "yt-tui.cmd") -Encoding ASCII -Value "@`"$Python`" `"%~dp0yt-tui.py`" %*"
Say "Installed $Dest"

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not (($UserPath -split ";") -contains $Dest)) {
    [Environment]::SetEnvironmentVariable("Path", (($UserPath.TrimEnd(";"), $Dest) -join ";").TrimStart(";"), "User")
    $env:Path += ";$Dest"
    Say "Added $Dest to your PATH (open a new terminal to pick it up)"
}
Say "Run: yt-tui [URL]   (Windows Terminal recommended for colours)"
