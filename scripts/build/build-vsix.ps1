# build-vsix.ps1 (moved)
# Build VSIX package for Sitecore MCP Server

Write-Host "=== VSIX Package Builder ===" -ForegroundColor Cyan
Write-Host ""

# Check if vsce is installed
Write-Host "[INFO] Checking for @vscode/vsce..." -ForegroundColor Cyan
$vsceInstalled = $null -ne (Get-Command vsce -ErrorAction SilentlyContinue)

if (-not $vsceInstalled) {
    Write-Host "[WARN] @vscode/vsce is not installed globally" -ForegroundColor Yellow
    Write-Host "[INFO] Installing @vscode/vsce..." -ForegroundColor Cyan
    npm install -g @vscode/vsce
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Failed to install @vscode/vsce" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] @vscode/vsce installed successfully!" -ForegroundColor Green
}
else {
    Write-Host "[OK] @vscode/vsce is already installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "[INFO] Building TypeScript..." -ForegroundColor Cyan
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] TypeScript build failed" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] TypeScript build successful!" -ForegroundColor Green
Write-Host ""

# Get version from package.json
Write-Host "[INFO] Reading package.json..." -ForegroundColor Cyan
$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
$version = $packageJson.version
$name = $packageJson.name

Write-Host "[OK] Package: $name v$version" -ForegroundColor Green
Write-Host ""

# Build VSIX
Write-Host "[INFO] Building VSIX package..." -ForegroundColor Cyan
vsce package --allow-star-activation --no-yarn --out "$name-$version.vsix"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] VSIX packaging failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] VSIX package created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Output file: $name-$version.vsix" -ForegroundColor Yellow
Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Cyan
