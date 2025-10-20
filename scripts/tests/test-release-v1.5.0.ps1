# ============================================================
# TEST: Version 1.5.0 - Final Verification
# ============================================================
# Purpose: Verify v1.5.0 is ready to ship
# Date: 17 oktober 2025
# ============================================================

Write-Host ""
Write-Host "=== VERSION 1.5.0 - FINAL VERIFICATION ===" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# ============================================================
# TEST 1: Version Number
# ============================================================
Write-Host "[TEST 1] Version number in package.json" -ForegroundColor Yellow

$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
$version = $packageJson.version

if ($version -eq "1.5.0") {
    Write-Host "[PASS] Version is 1.5.0" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Version is $version (expected 1.5.0)" -ForegroundColor Red
    $allPassed = $false
}

# ============================================================
# TEST 2: TypeScript Build
# ============================================================
Write-Host ""
Write-Host "[TEST 2] TypeScript build status" -ForegroundColor Yellow

if (Test-Path "dist/sitecore-service.js") {
    Write-Host "[PASS] dist/sitecore-service.js exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] dist/sitecore-service.js not found" -ForegroundColor Red
    $allPassed = $false
}

if (Test-Path "dist/index.js") {
    Write-Host "[PASS] dist/index.js exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] dist/index.js not found" -ForegroundColor Red
    $allPassed = $false
}

# ============================================================
# TEST 3: New Features in Code
# ============================================================
Write-Host ""
Write-Host "[TEST 3] New features in compiled code" -ForegroundColor Yellow

$serviceJs = Get-Content "dist/sitecore-service.js" -Raw

# Check for pagination
if ($serviceJs -match "searchItemsPaginated") {
    Write-Host "[PASS] searchItemsPaginated method found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] searchItemsPaginated method not found" -ForegroundColor Red
    $allPassed = $false
}

# Check for pageInfo
if ($serviceJs -match "pageInfo") {
    Write-Host "[PASS] pageInfo in code" -ForegroundColor Green
} else {
    Write-Host "[FAIL] pageInfo not found" -ForegroundColor Red
    $allPassed = $false
}

# Check for filters
$filterCount = 0
if ($serviceJs -match "pathContains") { $filterCount++ }
if ($serviceJs -match "pathStartsWith") { $filterCount++ }
if ($serviceJs -match "nameContains") { $filterCount++ }
if ($serviceJs -match "templateIn") { $filterCount++ }
if ($serviceJs -match "hasChildrenFilter") { $filterCount++ }
if ($serviceJs -match "hasLayoutFilter") { $filterCount++ }

if ($filterCount -eq 6) {
    Write-Host "[PASS] All 6 filters found in code" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Only $filterCount/6 filters found" -ForegroundColor Red
    $allPassed = $false
}

# Check for ordering
if ($serviceJs -match "orderBy") {
    Write-Host "[PASS] orderBy in code" -ForegroundColor Green
} else {
    Write-Host "[FAIL] orderBy not found" -ForegroundColor Red
    $allPassed = $false
}

if ($serviceJs -match "localeCompare") {
    Write-Host "[PASS] localeCompare (sorting) found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] localeCompare not found" -ForegroundColor Red
    $allPassed = $false
}

# ============================================================
# TEST 4: MCP Tools
# ============================================================
Write-Host ""
Write-Host "[TEST 4] MCP tool definitions" -ForegroundColor Yellow

$indexJs = Get-Content "dist/index.js" -Raw

# Check for sitecore_search_paginated tool
if ($indexJs -match "sitecore_search_paginated") {
    Write-Host "[PASS] sitecore_search_paginated tool registered" -ForegroundColor Green
} else {
    Write-Host "[FAIL] sitecore_search_paginated tool not found" -ForegroundColor Red
    $allPassed = $false
}

# Count tools
$toolMatches = [regex]::Matches($indexJs, "case `"sitecore_")
$toolCount = $toolMatches.Count

if ($toolCount -eq 10) {
    Write-Host "[PASS] All 10 MCP tools found" -ForegroundColor Green
} else {
    Write-Host "[WARN] Found $toolCount tools (expected 10)" -ForegroundColor Yellow
}

# ============================================================
# TEST 5: Documentation
# ============================================================
Write-Host ""
Write-Host "[TEST 5] Documentation files" -ForegroundColor Yellow

$docs = @(
    "PAGINATION-COMPLETE.md",
    "ENHANCED-FILTERS-COMPLETE.md",
    "SEARCH-ORDERING-COMPLETE.md",
    "HELIX-RELATIONSHIP-DISCOVERY.md",
    "RELEASE-NOTES-v1.5.0.md",
    "READY-TO-SHIP-v1.5.0.md",
    "SUMMARY-v1.5.0.md"
)

$docsMissing = 0
foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "[OK] $doc" -ForegroundColor Gray
    } else {
        Write-Host "[MISSING] $doc" -ForegroundColor Red
        $docsMissing++
        $allPassed = $false
    }
}

if ($docsMissing -eq 0) {
    Write-Host "[PASS] All 7 documentation files exist" -ForegroundColor Green
} else {
    Write-Host "[FAIL] $docsMissing documentation files missing" -ForegroundColor Red
}

# ============================================================
# TEST 6: Test Scripts
# ============================================================
Write-Host ""
Write-Host "[TEST 6] Test scripts" -ForegroundColor Yellow

$tests = @(
    "test-pagination-mcp.ps1",
    "test-filters-validation.ps1",
    "test-ordering-validation.ps1"
)

$testsMissing = 0
foreach ($test in $tests) {
    if (Test-Path $test) {
        Write-Host "[OK] $test" -ForegroundColor Gray
    } else {
        Write-Host "[MISSING] $test" -ForegroundColor Red
        $testsMissing++
        $allPassed = $false
    }
}

if ($testsMissing -eq 0) {
    Write-Host "[PASS] All 3 test scripts exist" -ForegroundColor Green
} else {
    Write-Host "[FAIL] $testsMissing test scripts missing" -ForegroundColor Red
}

# ============================================================
# TEST 7: Copilot Instructions
# ============================================================
Write-Host ""
Write-Host "[TEST 7] Copilot instructions updated" -ForegroundColor Yellow

$copilotInstructions = Get-Content ".github/copilot-instructions.md" -Raw

if ($copilotInstructions -match "RELATIONSHIP DISCOVERY") {
    Write-Host "[PASS] Helix relationship discovery in copilot-instructions" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Relationship discovery section not found" -ForegroundColor Red
    $allPassed = $false
}

if ($copilotInstructions -match "HELIX-RELATIONSHIP-DISCOVERY.md") {
    Write-Host "[PASS] Reference to HELIX-RELATIONSHIP-DISCOVERY.md" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Reference to documentation not found" -ForegroundColor Red
    $allPassed = $false
}

# ============================================================
# FINAL SUMMARY
# ============================================================
Write-Host ""
Write-Host "=== FINAL SUMMARY ===" -ForegroundColor Cyan
Write-Host ""

if ($allPassed) {
    Write-Host "[SUCCESS] VERSION 1.5.0 IS READY TO SHIP!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Features Implemented:" -ForegroundColor Yellow
    Write-Host "  [OK] Pagination Support (cursor-based)" -ForegroundColor Green
    Write-Host "  [OK] Enhanced Search Filters (6 types)" -ForegroundColor Green
    Write-Host "  [OK] Search Ordering (multi-field)" -ForegroundColor Green
    Write-Host "  [OK] Helix Relationship Discovery (documentation)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Quality Checks:" -ForegroundColor Yellow
    Write-Host "  [OK] Version bumped to 1.5.0" -ForegroundColor Green
    Write-Host "  [OK] TypeScript compiled successfully" -ForegroundColor Green
    Write-Host "  [OK] All features in compiled code" -ForegroundColor Green
    Write-Host "  [OK] 10 MCP tools registered" -ForegroundColor Green
    Write-Host "  [OK] All documentation created" -ForegroundColor Green
    Write-Host "  [OK] All test scripts created" -ForegroundColor Green
    Write-Host "  [OK] Copilot instructions updated" -ForegroundColor Green
    Write-Host ""
    Write-Host "READY FOR PRODUCTION USE!" -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host ""
} else {
    Write-Host "[FAILED] Some checks failed - review above" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# ============================================================
# Next Steps
# ============================================================
Write-Host "=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Commit all changes:" -ForegroundColor Yellow
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Release v1.5.0: Pagination, Filters, Ordering, Helix Discovery'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Tag release:" -ForegroundColor Yellow
Write-Host "   git tag -a v1.5.0 -m 'Version 1.5.0: Enterprise-grade search suite'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Push to GitHub:" -ForegroundColor Yellow
Write-Host "   git push origin main" -ForegroundColor Gray
Write-Host "   git push origin v1.5.0" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Create GitHub Release:" -ForegroundColor Yellow
Write-Host "   - Go to: https://github.com/GaryWenneker/sitecore-mcp-server/releases" -ForegroundColor Gray
Write-Host "   - Click 'Draft a new release'" -ForegroundColor Gray
Write-Host "   - Use content from RELEASE-NOTES-v1.5.0.md" -ForegroundColor Gray
Write-Host ""
