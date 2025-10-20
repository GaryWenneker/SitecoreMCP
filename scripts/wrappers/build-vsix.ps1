Write-Host "[DEPRECATED] Use: scripts/build/build-vsix.ps1" -ForegroundColor Yellow
& "$PSScriptRoot\..\build\build-vsix.ps1"
exit $LASTEXITCODE
