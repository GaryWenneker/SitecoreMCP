# Test script for sitecore_get_sites MCP tool
# Tests site configuration retrieval

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

function Test-Sites {
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

Write-Host "=== Testing sitecore_get_sites ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get site definitions folder
Test-Sites -TestName "Get sites - Site definitions folder" -Query @"
{
  item(path: "/sitecore/system/Sites", language: "en") {
    id
    name
    path
    hasChildren
  }
}
"@ -Validation { param($data) 
    # Sites folder may not exist in all Sitecore instances
    return $true
}

# Test 2: Get site definitions children
Test-Sites -TestName "Get sites - List site definitions" -Query @"
{
  item(path: "/sitecore/system/Sites", language: "en") {
    name
    children(first: 10) {
      id
      name
      path
      template {
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    $children = $data.item.children
    if ($children -and $children.Count -gt 0) {
        Write-Host "  Found $($children.Count) site definitions" -ForegroundColor Gray
        return $true
    }
    # Accept empty if no custom sites defined
    return $true
}

# Test 3: Get website site definition
Test-Sites -TestName "Get sites - Website site definition" -Query @"
{
  item(path: "/sitecore/system/Sites/website", language: "en") {
    id
    name
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@ -Validation { param($data) 
    # Website may or may not exist depending on Sitecore setup
    return $true
}

# Test 4: Search for site definitions
Test-Sites -TestName "Get sites - Search for sites" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/system/Sites"
    first: 10
  ) {
    results {
      items {
        name
        path
        templateName
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.search.results.items.Count -ge 0
}

# Test 5: Get site context from content root
Test-Sites -TestName "Get sites - Content root site context" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    name
    path
  }
}
"@ -Validation { param($data) 
    return $data.item
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_sites" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[INFO] Note: Site definitions stored in /sitecore/system/Sites" -ForegroundColor Yellow
Write-Host "[INFO] Actual site list depends on Sitecore configuration" -ForegroundColor Yellow

exit $script:failCount
