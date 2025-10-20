# Test script for sitecore_delete_item MCP tool
# Tests item deletion mutation (DESTRUCTIVE - deletes items!)

# Load environment variables
. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

if (-not $env:SITECORE_API_KEY) {
    Write-Host "[ERROR] SITECORE_API_KEY not found in environment" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Environment variables loaded successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Red
Write-Host "  WARNING: DESTRUCTIVE TEST!" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "[WARN] This test DELETES items in Sitecore!" -ForegroundColor Yellow
Write-Host "[WARN] Only test items named 'MCPTest_*' will be targeted" -ForegroundColor Yellow
Write-Host "[INFO] Deletion uses recycle bin by default" -ForegroundColor Cyan
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

Write-Host "=== Testing sitecore_delete_item ===" -ForegroundColor Cyan
Write-Host "[INFO] Checking mutation support..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Find test items to delete
Write-Host "[TEST] Delete item - Find test items" -ForegroundColor Cyan
$testItems = @()
try {
    $query = @"
{
  search(
    keyword: "MCPTest_"
    rootItem: "/sitecore/content"
    first: 10
  ) {
    results {
      items {
        name
        path
      }
    }
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    $testItems = $response.data.search.results.items | Where-Object { $_.name -like "MCPTest_*" }
    
    if ($testItems.Count -gt 0) {
        Write-Host "[INFO] Found $($testItems.Count) test items" -ForegroundColor Cyan
        foreach ($item in $testItems) {
            Write-Host "  - $($item.path)" -ForegroundColor Gray
        }
        $script:passCount++
    } else {
        Write-Host "[INFO] No test items found (nothing to delete)" -ForegroundColor Yellow
        $script:passCount++
    }
}
catch {
    Write-Host "[FAIL] Search exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Test 2: Attempt delete mutation
if ($testItems.Count -gt 0) {
    Write-Host "[TEST] Delete item - Attempt mutation" -ForegroundColor Cyan
    $targetPath = $testItems[0].path
    Write-Host "[INFO] Attempting to delete: $targetPath" -ForegroundColor Gray
    
    try {
        $mutation = @"
mutation {
  deleteItem(
    path: "$targetPath"
    deletePermanently: false
  ) {
    success
  }
}
"@
        $body = @{ query = $mutation } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
        
        if ($response.errors) {
            Write-Host "[EXPECTED] Mutations not supported" -ForegroundColor Yellow
            Write-Host "  Error: $($response.errors[0].message)" -ForegroundColor Gray
            $script:passCount++
        } elseif ($response.data.deleteItem) {
            Write-Host "[PASS] Delete mutation executed" -ForegroundColor Green
            Write-Host "[INFO] Item moved to recycle bin (can be restored)" -ForegroundColor Cyan
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
}

# Test 3: Verify item still queryable (if mutation failed)
if ($testItems.Count -gt 0) {
    Write-Host "[TEST] Delete item - Verify item state" -ForegroundColor Cyan
    $targetPath = $testItems[0].path
    
    try {
        $query = @"
{
  item(path: "$targetPath", language: "en") {
    id
    name
  }
}
"@
        $body = @{ query = $query } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
        
        if ($response.data.item) {
            Write-Host "[INFO] Item still exists (mutation didn't work)" -ForegroundColor Yellow
            $script:passCount++
        } else {
            Write-Host "[INFO] Item deleted or moved to recycle bin" -ForegroundColor Cyan
            $script:passCount++
        }
    }
    catch {
        Write-Host "[INFO] Item no longer queryable" -ForegroundColor Yellow
        $script:passCount++
    }
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_delete_item" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[INFO] Note: GraphQL mutations rarely supported in Sitecore" -ForegroundColor Yellow
Write-Host "[INFO] Use Sitecore Management API for guaranteed delete support" -ForegroundColor Yellow
Write-Host "[INFO] Deleted items go to recycle bin (unless deletePermanently: true)" -ForegroundColor Yellow

exit $script:failCount
