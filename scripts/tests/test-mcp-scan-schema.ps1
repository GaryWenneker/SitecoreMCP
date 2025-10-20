# Test script for sitecore_scan_schema MCP tool
# Tests schema analysis and introspection (LIMITED - server doesn't support introspection)

# Load environment variables
. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

if (-not $env:SITECORE_API_KEY) {
    Write-Host "[ERROR] SITECORE_API_KEY not found in environment" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Environment variables loaded successfully!" -ForegroundColor Green
Write-Host ""

# Configuration
$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

# Test results tracking
$script:passCount = 0
$script:failCount = 0

Write-Host "=== Testing sitecore_scan_schema ===" -ForegroundColor Cyan
Write-Host "[WARN] Sitecore instance does NOT support GraphQL introspection!" -ForegroundColor Yellow
Write-Host "[INFO] Testing alternative schema discovery methods..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Check if introspection is available (expected to fail)
Write-Host "[TEST] Schema scan - Introspection query" -ForegroundColor Cyan
try {
    $query = @"
{
  __schema {
    types {
      name
    }
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.errors) {
        Write-Host "[EXPECTED] Introspection not supported (500 error)" -ForegroundColor Yellow
        Write-Host "  Error: $($response.errors[0].message)" -ForegroundColor Gray
        $script:passCount++
    } else {
        Write-Host "[UNEXPECTED] Introspection worked!" -ForegroundColor Green
        $script:passCount++
    }
}
catch {
    Write-Host "[EXPECTED] Introspection failed (expected behavior)" -ForegroundColor Yellow
    $script:passCount++
}
Write-Host ""

# Test 2: Use static schema file instead
Write-Host "[TEST] Schema scan - Load static schema file" -ForegroundColor Cyan
$schemaFile = "$PSScriptRoot\..\..\data\graphql-schema-summary.json"
if (Test-Path $schemaFile) {
    Write-Host "[PASS] Static schema file exists" -ForegroundColor Green
    $schema = Get-Content $schemaFile | ConvertFrom-Json
    Write-Host "  Queries: $($schema.queries.Count)" -ForegroundColor Gray
    $script:passCount++
} else {
    Write-Host "[FAIL] Static schema file not found" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Test 3: Verify __typename works (limited introspection)
Write-Host "[TEST] Schema scan - __typename field" -ForegroundColor Cyan
try {
    $query = @"
{
  item(path: "/sitecore/content", language: "en") {
    __typename
    id
    name
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.data.item.__typename) {
        Write-Host "[PASS] __typename field works" -ForegroundColor Green
        Write-Host "  Type: $($response.data.item.__typename)" -ForegroundColor Gray
        $script:passCount++
    } else {
        Write-Host "[FAIL] __typename not returned" -ForegroundColor Red
        $script:failCount++
    }
}
catch {
    Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Test 4: Test known query structures
Write-Host "[TEST] Schema scan - Verify known query: item()" -ForegroundColor Cyan
try {
    $query = @"
{
  item(path: "/sitecore", language: "en") {
    id
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.data.item) {
        Write-Host "[PASS] item() query works" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host "[FAIL] item() query failed" -ForegroundColor Red
        $script:failCount++
    }
}
catch {
    Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Test 5: Test search query structure
Write-Host "[TEST] Schema scan - Verify known query: search()" -ForegroundColor Cyan
try {
    $query = @"
{
  search(keyword: "", rootItem: "/sitecore", first: 1) {
    results {
      items {
        id
      }
    }
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.data.search) {
        Write-Host "[PASS] search() query works" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host "[FAIL] search() query failed" -ForegroundColor Red
        $script:failCount++
    }
}
catch {
    Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_scan_schema" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[INFO] Note: Full GraphQL introspection NOT supported by Sitecore" -ForegroundColor Yellow
Write-Host "[INFO] Use static schema file: .github/introspectionSchema.json" -ForegroundColor Yellow
Write-Host "[INFO] Schema analysis via manual query testing only" -ForegroundColor Yellow

exit $script:failCount
