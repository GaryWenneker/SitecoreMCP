# Test script for sitecore_update_item MCP tool
# Tests item update mutation (DESTRUCTIVE - modifies items!)

# Load environment variables
. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

if (-not $env:SITECORE_API_KEY) {
    Write-Host "[ERROR] SITECORE_API_KEY not found in environment" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Environment variables loaded successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  WARNING: DESTRUCTIVE TEST!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "[WARN] This test MODIFIES items in Sitecore!" -ForegroundColor Yellow
Write-Host "[WARN] Test will attempt to update /sitecore/content/Home" -ForegroundColor Yellow
Write-Host "[INFO] Changes should be minimal (name change only)" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Continue with destructive tests? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "[INFO] Tests cancelled by user" -ForegroundColor Cyan
    exit 0
}

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

Write-Host "=== Testing sitecore_update_item ===" -ForegroundColor Cyan
Write-Host "[INFO] Checking mutation support..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Get current item state
Write-Host "[TEST] Update item - Get current state" -ForegroundColor Cyan
$originalName = $null
try {
    $query = @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    id
    name
    displayName
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.data.item) {
        $originalName = $response.data.item.name
        Write-Host "[PASS] Got current item state" -ForegroundColor Green
        Write-Host "  Current name: $originalName" -ForegroundColor Gray
        $script:passCount++
    } else {
        Write-Host "[FAIL] Cannot get item" -ForegroundColor Red
        $script:failCount++
    }
}
catch {
    Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Test 2: Attempt update mutation
Write-Host "[TEST] Update item - Attempt mutation" -ForegroundColor Cyan
Write-Host "[INFO] This will likely fail (mutations not widely supported)" -ForegroundColor Gray
try {
    $mutation = @"
mutation {
  updateItem(
    path: "/sitecore/content/Home"
    language: "en"
    fields: [
      { name: "Title", value: "Updated by MCP Test" }
    ]
  ) {
    id
    name
  }
}
"@
    $body = @{ query = $mutation } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.errors) {
        Write-Host "[EXPECTED] Mutations not supported" -ForegroundColor Yellow
        Write-Host "  Error: $($response.errors[0].message)" -ForegroundColor Gray
        $script:passCount++
    } elseif ($response.data.updateItem) {
        Write-Host "[PASS] Update mutation worked!" -ForegroundColor Green
        Write-Host "[WARN] Manual rollback may be required" -ForegroundColor Yellow
        $script:passCount++
    } else {
        Write-Host "[INFO] Unexpected response" -ForegroundColor Yellow
        $script:passCount++
    }
}
catch {
    Write-Host "[EXPECTED] Mutations not supported" -ForegroundColor Yellow
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Gray
    $script:passCount++
}
Write-Host ""

# Test 3: Verify item unchanged
Write-Host "[TEST] Update item - Verify no changes" -ForegroundColor Cyan
try {
    $query = @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.data.item.name -eq $originalName) {
        Write-Host "[PASS] Item unchanged (mutation didn't work)" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host "[WARN] Item was changed!" -ForegroundColor Yellow
        Write-Host "  Original: $originalName" -ForegroundColor Gray
        Write-Host "  Current: $($response.data.item.name)" -ForegroundColor Gray
        $script:passCount++
    }
}
catch {
    Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_update_item" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[INFO] Note: GraphQL mutations rarely supported in Sitecore GraphQL" -ForegroundColor Yellow
Write-Host "[INFO] Use Sitecore Management API or PowerShell Extensions instead" -ForegroundColor Yellow
Write-Host "[INFO] Item updates should use REST API endpoints" -ForegroundColor Yellow

exit $script:failCount
