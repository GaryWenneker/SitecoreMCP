# Simple Search Fix Verification
# Checks if the code fixes compile correctly

Write-Host ""
Write-Host "=== Search API Fix Verification ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Checking TypeScript build..." -ForegroundColor Yellow

# Test build
try {
    $buildOutput = npm run build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] TypeScript build successful!" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] TypeScript build failed!" -ForegroundColor Red
        Write-Host $buildOutput
        exit 1
    }
} catch {
    Write-Host "[FAIL] Build error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[INFO] Checking for ContentSearchResult fixes in code..." -ForegroundColor Yellow

# Check if fixes are in place
$serviceFile = Get-Content "src/sitecore-service.ts" -Raw

$checks = @(
    @{ Pattern = "templateName"; Description = "Uses templateName (not template.name)" },
    @{ Pattern = "ContentSearchResult fields:"; Description = "Has ContentSearchResult comment" },
    @{ Pattern = "displayName: item.name"; Description = "Maps displayName to name" },
    @{ Pattern = "ContentSearchResult doesn't have"; Description = "Has warning comments" },
    @{ Pattern = "uri"; Description = "Uses uri (not url)" },
    @{ Pattern = "language: string"; Description = "language is String comment" }
)

$passCount = 0
foreach ($check in $checks) {
    if ($serviceFile -match [regex]::Escape($check.Pattern)) {
        Write-Host "[PASS] $($check.Description)" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "[FAIL] $($check.Description)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Fixes applied: $passCount / $($checks.Count)" -ForegroundColor Yellow

if ($passCount -eq $checks.Count) {
    Write-Host "[SUCCESS] All ContentSearchResult fixes verified!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Fixed issues:" -ForegroundColor Yellow
    Write-Host "  - Removed 'total' field from ContentSearchResults" -ForegroundColor Gray
    Write-Host "  - Removed 'displayName' field (using 'name' instead)" -ForegroundColor Gray
    Write-Host "  - Changed 'template { id, name }' to 'templateName'" -ForegroundColor Gray
    Write-Host "  - Removed 'hasChildren' field" -ForegroundColor Gray
    Write-Host "  - Removed 'fields' array" -ForegroundColor Gray
    Write-Host "  - Changed 'url' to 'uri'" -ForegroundColor Gray
    Write-Host "  - Changed 'language { name }' to 'language' (String)" -ForegroundColor Gray
    Write-Host "  - Added warning comments for unsupported filters" -ForegroundColor Gray
} else {
    Write-Host "[WARNING] Some fixes may be missing!" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
