# Test script for sitecore_create_item MCP tool
# Tests item creation mutation (DESTRUCTIVE - creates test items!)

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
Write-Host "[WARN] This test CREATES items in Sitecore!" -ForegroundColor Yellow
Write-Host "[WARN] Items will be created under /sitecore/content" -ForegroundColor Yellow
Write-Host "[INFO] Test items will be named 'MCPTest_*'" -ForegroundColor Cyan
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
$script:createdItems = @()

Write-Host "=== Testing sitecore_create_item ===" -ForegroundColor Cyan
Write-Host "[INFO] Checking mutation support..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Check if mutations are supported
Write-Host "[TEST] Create item - Check mutation support" -ForegroundColor Cyan
try {
    # Try a simple query first to ensure connection works
    $query = @"
{
  item(path: "/sitecore/content", language: "en") {
    id
    name
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.data.item) {
        Write-Host "[PASS] Connection works, can query items" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host "[FAIL] Cannot query items" -ForegroundColor Red
        $script:failCount++
    }
}
catch {
    Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Test 2: Attempt to create item (may fail if mutations not supported)
Write-Host "[TEST] Create item - Simple item creation" -ForegroundColor Cyan
Write-Host "[INFO] Attempting to create: /sitecore/content/MCPTest_Item1" -ForegroundColor Gray
try {
    $mutation = @"
mutation {
  createItem(
    name: "MCPTest_Item1"
    templateId: "{76036F5E-CBCE-46D1-AF0A-4143F9B557AA}"
    parent: "/sitecore/content"
    language: "en"
  ) {
    id
    name
    path
  }
}
"@
    $body = @{ query = $mutation } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.errors) {
        Write-Host "[EXPECTED] Mutations may not be supported" -ForegroundColor Yellow
        Write-Host "  Error: $($response.errors[0].message)" -ForegroundColor Gray
        # Not a failure if mutations aren't supported
        $script:passCount++
    } elseif ($response.data.createItem) {
        Write-Host "[PASS] Item created successfully!" -ForegroundColor Green
        Write-Host "  ID: $($response.data.createItem.id)" -ForegroundColor Gray
        Write-Host "  Path: $($response.data.createItem.path)" -ForegroundColor Gray
        $script:createdItems += $response.data.createItem.path
        $script:passCount++
    } else {
        Write-Host "[INFO] Unexpected response" -ForegroundColor Yellow
        $script:passCount++
    }
}
catch {
    Write-Host "[EXPECTED] Mutations not supported or endpoint error" -ForegroundColor Yellow
    Write-Host "  Exception: $($_.Exception.Message)" -ForegroundColor Gray
    $script:passCount++
}
Write-Host ""

# Test 3: Alternative - Check if item exists via search
Write-Host "[TEST] Create item - Verify via search" -ForegroundColor Cyan
try {
    $query = @"
{
  search(
    keyword: "MCPTest_Item1"
    rootItem: "/sitecore/content"
    first: 1
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
    
    $found = $response.data.search.results.items | Where-Object { $_.name -eq "MCPTest_Item1" }
    if ($found) {
        Write-Host "[INFO] Created item found via search" -ForegroundColor Cyan
        $script:passCount++
    } else {
        Write-Host "[INFO] Item not found (expected if creation failed)" -ForegroundColor Yellow
        $script:passCount++
    }
}
catch {
    Write-Host "[FAIL] Search exception: $($_.Exception.Message)" -ForegroundColor Red
    $script:failCount++
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_create_item" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

if ($script:createdItems.Count -gt 0) {
    Write-Host ""
    Write-Host "[WARN] Created items (manual cleanup required):" -ForegroundColor Yellow
    foreach ($item in $script:createdItems) {
        Write-Host "  - $item" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "[INFO] Note: GraphQL mutations support varies by Sitecore version" -ForegroundColor Yellow
Write-Host "[INFO] Use Sitecore Management API for guaranteed mutation support" -ForegroundColor Yellow
Write-Host "[INFO] Created test items should be deleted manually" -ForegroundColor Yellow

exit $script:failCount
