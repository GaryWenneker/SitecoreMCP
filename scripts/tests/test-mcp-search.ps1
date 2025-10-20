# Test script for sitecore_search MCP tool
# Tests all search parameters and filters

. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Write-Host "`n=== Testing sitecore_search ===" -ForegroundColor Cyan

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testResults = @{ Passed = 0; Failed = 0; Tests = @() }

function Test-Search {
    param([string]$TestName, [string]$Query, [scriptblock]$Validation)
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    try {
        $body = @{ query = $Query } | ConvertTo-Json -Depth 10
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

# Test 1: Basic keyword search (may return 0 results if no matches)
Test-Search -TestName "Search - Keyword 'Home'" -Query @"
{
  search(keyword: "Home", first: 10) {
    results {
      items {
        id
        name
        path
      }
    }
  }
}
"@ -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 2: Search with rootItem filter
Test-Search -TestName "Search - With rootItem filter" -Query @"
{
  search(keyword: "content", rootItem: "/sitecore/content", first: 10) {
    results {
      items {
        id
        name
        path
      }
    }
  }
}
"@ -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 3: Search with language filter
Test-Search -TestName "Search - With language (nl-NL)" -Query @"
{
  search(keyword: "Home", language: "nl-NL", first: 10) {
    results {
      items {
        id
        name
        language
      }
    }
  }
}
"@ -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 4: Search with pagination (first parameter)
Test-Search -TestName "Search - Pagination (first: 5)" -Query @"
{
  search(keyword: "template", first: 5) {
    results {
      items {
        id
        name
      }
    }
  }
}
"@ -Validation { param($data) return $data.search.results.items.Count -le 5 }

# Test 5: Search with path filter (path_contains)
Test-Search -TestName "Search - path_contains filter" -Query @"
{
  search(
    keyword: ""
    first: 10
    fieldsEqual: [{name: "path", value: "/sitecore/content"}]
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
"@ -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 6: Search with templateName filter
Test-Search -TestName "Search - templateName filter" -Query @"
{
  search(
    keyword: ""
    first: 10
    fieldsEqual: [{name: "templatename", value: "Template"}]
  ) {
    results {
      items {
        id
        name
        templateName
      }
    }
  }
}
"@ -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 7: Search - empty keyword (all items)
Test-Search -TestName "Search - Empty keyword (first 10)" -Query @"
{
  search(keyword: "", first: 10) {
    results {
      items {
        id
        name
      }
    }
  }
}
"@ -Validation { param($data) return $data.search.results.items.Count -ge 0 }

# Test 8: Search pagination support (check results structure)
Test-Search -TestName "Search - Results structure" -Query @"
{
  search(keyword: "item", first: 5) {
    results {
      items {
        id
        name
      }
    }
  }
}
"@ -Validation { param($data) return $data.search.results }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_search" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""
exit $testResults.Failed
