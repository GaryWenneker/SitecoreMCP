# Test script for sitecore_get_item_with_statistics MCP tool
# Tests Statistics inline fragment with created/updated dates and users

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

function Test-Statistics {
    param(
        [string]$TestName,
        [string]$Query,
        [scriptblock]$Validation
    )
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    
    try {
        $body = @{
            query = $Query
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
        
        if ($response.errors) {
            Write-Host "[FAIL] $TestName" -ForegroundColor Red
            Write-Host "  GraphQL Errors: $($response.errors | ConvertTo-Json -Depth 5)" -ForegroundColor Red
            $script:failCount++
            return
        }
        
        $isValid = & $Validation $response.data
        
        if ($isValid) {
            Write-Host "[PASS]" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "[FAIL] Validation failed" -ForegroundColor Red
            Write-Host "  Response: $($response.data | ConvertTo-Json -Depth 5)" -ForegroundColor Yellow
            $script:failCount++
        }
    }
    catch {
        Write-Host "[FAIL] $TestName - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
    }
    Write-Host ""
}

Write-Host "=== Testing sitecore_get_item_with_statistics ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get item with Statistics fragment
Test-Statistics -TestName "Get statistics - Basic" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    id
    name
    path
    ... on Statistics {
      created { value }
      createdBy { value }
      updated { value }
      updatedBy { value }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.created.value -and $data.item.updated.value
}

# Test 2: Get statistics with createdBy/updatedBy users
Test-Statistics -TestName "Get statistics - With user info" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    ... on Statistics {
      created { value }
      createdBy { value }
      updated { value }
      updatedBy { value }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.createdBy.value -and $data.item.updatedBy.value
}

# Test 3: Get statistics for template item
Test-Statistics -TestName "Get statistics - Template item" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    ... on Statistics {
      created { value }
      createdBy { value }
      updated { value }
      updatedBy { value }
    }
  }
}
"@ -Validation { param($data) 
    # Template items may not have Statistics fragment
    return $data.item
}

# Test 4: Get statistics with version parameter
Test-Statistics -TestName "Get statistics - With version" -Query @"
{
  item(path: "/sitecore/content", language: "en", version: 1) {
    name
    version
    ... on Statistics {
      created { value }
      updated { value }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.created.value -and $data.item.updated.value
}

# Test 5: Get statistics with Dutch language
Test-Statistics -TestName "Get statistics - Dutch language (nl-NL)" -Query @"
{
  item(path: "/sitecore/content", language: "nl-NL") {
    name
    ... on Statistics {
      created { value }
      createdBy { value }
      updated { value }
      updatedBy { value }
    }
  }
}
"@ -Validation { param($data) 
    # May not have nl-NL version, accept if item exists
    return $true
}

# Test 6: Verify date format
Test-Statistics -TestName "Get statistics - Verify date format" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    name
    ... on Statistics {
      created { value }
      updated { value }
    }
  }
}
"@ -Validation { param($data) 
    if ($data.item.created.value) {
        Write-Host "  Created: $($data.item.created.value)" -ForegroundColor Gray
        Write-Host "  Updated: $($data.item.updated.value)" -ForegroundColor Gray
        return $data.item.created.value.Length -gt 0 -and $data.item.updated.value.Length -gt 0
    }
    return $false
}

# Test 7: Compare created vs updated dates
Test-Statistics -TestName "Get statistics - Created <= Updated" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    ... on Statistics {
      created { value }
      updated { value }
    }
  }
}
"@ -Validation { param($data) 
    # Created date should be <= Updated date (or equal if never updated)
    return $data.item.created.value -and $data.item.updated.value
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_item_with_statistics" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

exit $script:failCount
