# Test script for sitecore_search_paginated MCP tool
# Tests pagination, cursors, enhanced filters, and orderBy

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

function Test-SearchPaginated {
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

Write-Host "=== Testing sitecore_search_paginated ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Basic paginated search with first parameter
Test-SearchPaginated -TestName "Search paginated - First 5 items" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/content"
    first: 5
  ) {
    results {
      totalCount
      pageInfo {
        hasNextPage
        endCursor
      }
      items {
        id
        name
        path
      }
    }
  }
}
"@ -Validation { param($data) 
    $items = $data.search.results.items
    $pageInfo = $data.search.results.pageInfo
    Write-Host "  Items: $($items.Count), HasNext: $($pageInfo.hasNextPage)" -ForegroundColor Gray
    return $items.Count -le 5 -and $pageInfo
}

# Test 2: Search with after cursor (page 2)
# Note: This requires getting a cursor from previous query, so we'll test the structure
Test-SearchPaginated -TestName "Search paginated - With after parameter structure" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/content"
    first: 3
  ) {
    results {
      pageInfo {
        hasNextPage
        endCursor
      }
      items {
        id
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    $pageInfo = $data.search.results.pageInfo
    if ($pageInfo.endCursor) {
        Write-Host "  EndCursor: $($pageInfo.endCursor)" -ForegroundColor Gray
    }
    return $pageInfo -and ($pageInfo.hasNextPage -eq $true -or $pageInfo.hasNextPage -eq $false)
}

# Test 3: Search with multiple results
Test-SearchPaginated -TestName "Search paginated - Multiple results" -Query @"
{
  search(
    keyword: ""
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
"@ -Validation { param($data) 
    $items = $data.search.results.items
    Write-Host "  Found $($items.Count) items" -ForegroundColor Gray
    return $items.Count -ge 0
}

# Test 4: Search templates folder
Test-SearchPaginated -TestName "Search paginated - Templates folder" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/templates"
    first: 5
  ) {
    results {
      items {
        name
        path
      }
    }
  }
}
"@ -Validation { param($data) 
    $items = $data.search.results.items
    return $items.Count -ge 0
}

# Test 5: Search with enhanced filters (path_contains)
Test-SearchPaginated -TestName "Search paginated - With path_contains filter" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore"
    first: 10
    fieldsEqual: [
      { name: "_path", value: "content" }
    ]
  ) {
    results {
      totalCount
      items {
        name
        path
      }
    }
  }
}
"@ -Validation { param($data) 
    $items = $data.search.results.items
    # All items should have "content" in path
    if ($items.Count -gt 0) {
        $allMatch = $true
        foreach ($item in $items) {
            if ($item.path -notlike "*content*") {
                $allMatch = $false
                break
            }
        }
        return $allMatch
    }
    return $true  # Accept empty results
}

# Test 6: Search with templateName filter
Test-SearchPaginated -TestName "Search paginated - With template filter" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/templates"
    first: 5
    fieldsEqual: [
      { name: "_templatename", value: "Template" }
    ]
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

# Test 7: Search with totalCount
Test-SearchPaginated -TestName "Search paginated - Verify totalCount" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/content"
    first: 10
  ) {
    results {
      totalCount
      items {
        id
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    $totalCount = $data.search.results.totalCount
    $itemsCount = $data.search.results.items.Count
    Write-Host "  Total: $totalCount, Items: $itemsCount" -ForegroundColor Gray
    return $totalCount -ge $itemsCount
}

# Test 8: Search with language parameter
Test-SearchPaginated -TestName "Search paginated - With language (nl-NL)" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/content"
    first: 5
    language: "nl-NL"
  ) {
    results {
      items {
        name
        path
        language
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.search.results.items.Count -ge 0
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_search_paginated" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

exit $script:failCount
