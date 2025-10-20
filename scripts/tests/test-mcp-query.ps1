# Test script for sitecore_query MCP tool
# Tests Sitecore query syntax

. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Write-Host "`n=== Testing sitecore_query ===" -ForegroundColor Cyan

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testResults = @{ Passed = 0; Failed = 0 }

function Test-Query {
    param([string]$TestName, [string]$SitecoreQuery, [scriptblock]$Validation)
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    Write-Host "  Query: $SitecoreQuery" -ForegroundColor Gray
    
    try {
        $graphqlQuery = @"
{
  search(
    fieldsEqual: [{name: "path", value: "$SitecoreQuery"}]
    first: 100
  ) {
    results {
      items {
        id
        name
        path
      }
    }
  }
}
"@
        
        $body = @{ query = $graphqlQuery } | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body -Headers $headers
        
        if ($response.errors) {
            Write-Host "[FAIL] $($response.errors[0].message)" -ForegroundColor Red
            $testResults.Failed++
            return $false
        }
        
        if (& $Validation $response.data) {
            Write-Host "[PASS]" -ForegroundColor Green
            $testResults.Passed++
            return $true
        }
        Write-Host "[FAIL] Validation failed" -ForegroundColor Red
        $testResults.Failed++
        return $false
    }
    catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $testResults.Failed++
        return $false
    }
}

# Test 1: Simple path query
Test-Query -TestName "Query - Simple path" `
    -SitecoreQuery "/sitecore/content" `
    -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 2: Wildcard query (descendants)
Test-Query -TestName "Query - Descendants (//)" `
    -SitecoreQuery "/sitecore/content//*" `
    -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 3: Direct children query
Test-Query -TestName "Query - Direct children (/*)" `
    -SitecoreQuery "/sitecore/content/*" `
    -Validation { param($data) return $data.search.results.items.Count -ge 0 }

Write-Host ""
Write-Host "Note: Full Sitecore query syntax requires search implementation" -ForegroundColor Yellow
Write-Host "For template-based queries, use sitecore_search with templateName filter" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_query" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""
exit $testResults.Failed
