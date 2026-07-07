param(
    [string]$OutputDir = $(Join-Path $PSScriptRoot 'dist'),
    [string]$Name = 'InterventionReport'
)

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot
Set-Location $ScriptDir

$pyinstaller = Get-Command pyinstaller -ErrorAction SilentlyContinue
if (-not $pyinstaller) {
    Write-Host 'PyInstaller is not installed.' -ForegroundColor Yellow
    Write-Host 'Install it with: python -m pip install pyinstaller' -ForegroundColor Yellow
    exit 1
}

# Build a single-file EXE that serves the app from the EXE folder.
# server.py looks for static files in the frozen app resource directory and
# stores the database next to the EXE under ./data/.
& pyinstaller --noconfirm --clean --onefile --name $Name `
    --add-data 'index.html;.' `
    --add-data 'index.js;.' `
    --add-data 'manifest.json;.' `
    --add-data 'sw.js;.' `
    --add-data 'icons;icons' `
    server.py

$distDir = Join-Path $ScriptDir 'dist'
$exeFolder = Join-Path $distDir $Name
if (-not (Test-Path $exeFolder)) {
    throw "PyInstaller finished, but the output folder was not found: $exeFolder"
}

# Keep the source static assets beside the EXE for convenience when distributing
# the folder. (The one-file EXE already contains them, but this also makes the
# folder runnable from Explorer without unpacking anything else.)
foreach ($item in @('index.html', 'index.js', 'manifest.json', 'sw.js', 'icons')) {
    $source = Join-Path $ScriptDir $item
    $dest = Join-Path $exeFolder $item
    if (Test-Path $source) {
        Copy-Item $source $dest -Recurse -Force
    }
}

Write-Host "Built $exeFolder\$Name.exe" -ForegroundColor Green
Write-Host 'Open the folder and double-click the EXE to start the local server.' -ForegroundColor Green
