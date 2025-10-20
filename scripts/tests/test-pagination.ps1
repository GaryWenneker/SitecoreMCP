# Pagination Support Test
# Tests cursor-based pagination functionality in searchItems()

. .\Load-DotEnv.ps1

$ENDPOINT = $env:SITECORE_ENDPOINT_URL
$API_KEY = $env:SITECORE_API_KEY

if (-not $ENDPOINT -or -not $API_KEY) {
    Write-Host "[FAIL] Missing environment variables!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Pagination Support Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: First page (no cursor)
Write-Host "[TEST 1] First page (first: 5, no cursor)" -ForegroundColor Yellow
Write-Host ""

$query1 = @"
{
  search(
    keyword: "Home"
    first: 5
    language: "en"
  ) {
    total
    results {
      items {
        id
        name
        path
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      totalCount
    }
  }
}
"@

try {
    $body1 = @{ query = $query1 } | ConvertTo-Json -Depth 10
    $response1 = Invoke-RestMethod -Uri $ENDPOINT -Method Post -Body $body1 -ContentType "application/json" -Headers @{ "sc_apikey" = $API_KEY }
    
    if ($response1.errors) {
        Write-Host "[FAIL] GraphQL errors: $($response1.errors | ConvertTo-Json)" -ForegroundColor Red
    } else {
        $items = $response1.data.search.results.items
        $pageInfo = $response1.data.search.results.pageInfo
        $totalCount = $response1.data.search.results.totalCount
        
        Write-Host "[OK] First page retrieved!" -ForegroundColor Green
        Write-Host "  - Items returned: $($items.Count)" -ForegroundColor Gray
        Write-Host "  - Total count: $totalCount" -ForegroundColor Gray
        Write-Host "  - Has next page: $($pageInfo.hasNextPage)" -ForegroundColor Gray
        Write-Host "  - Has previous page: $($pageInfo.hasPreviousPage)" -ForegroundColor Gray
        Write-Host "  - Start cursor: $($pageInfo.startCursor)" -ForegroundColor Gray
        Write-Host "  - End cursor: $($pageInfo.endCursor)" -ForegroundColor Gray
        Write-Host ""
        
        if ($items.Count -eq 5) {
            Write-Host "[PASS] Test 1: Correct number of items" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Test 1: Expected 5 items, got $($items.Count)" -ForegroundColor Red
        }
        
        if ($pageInfo.hasNextPage -eq $true) {
            Write-Host "[PASS] Test 1: Has next page (expected)" -ForegroundColor Green
        } else {
            Write-Host "[WARN] Test 1: No next page (may be valid if <5 total items)" -ForegroundColor Yellow
        }
        
        if ($pageInfo.hasPreviousPage -eq $false) {
            Write-Host "[PASS] Test 1: No previous page (expected for first page)" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Test 1: Has previous page on first page!" -ForegroundColor Red
        }
        
        # Save cursor for next test
        $endCursor = $pageInfo.endCursor
        Write-Host ""
        Write-Host "[INFO] Saved endCursor for next test: $endCursor" -ForegroundColor Cyan
    }
} catch {
    Write-Host "[FAIL] Test 1 failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Test 2: Second page (with cursor)
Write-Host "[TEST 2] Second page (first: 5, after: cursor)" -ForegroundColor Yellow
Write-Host ""

if (-not $endCursor) {
    Write-Host "[SKIP] Test 2: No cursor available from Test 1" -ForegroundColor Yellow
} else {
    $query2 = @"
{
  search(
    keyword: "Home"
    first: 5
    after: "$endCursor"
    language: "en"
  ) {
    total
    results {
      items {
        id
        name
        path
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        startCursor
        endCursor
      }
      totalCount
    }
  }
}
"@

    try {
        $body2 = @{ query = $query2 } | ConvertTo-Json -Depth 10
        $response2 = Invoke-RestMethod -Uri $ENDPOINT -Method Post -Body $body2 -ContentType "application/json" -Headers @{ "sc_apikey" = $API_KEY }
        
        if ($response2.errors) {
            Write-Host "[FAIL] GraphQL errors: $($response2.errors | ConvertTo-Json)" -ForegroundColor Red
        } else {
            $items2 = $response2.data.search.results.items
            $pageInfo2 = $response2.data.search.results.pageInfo
            
            Write-Host "[OK] Second page retrieved!" -ForegroundColor Green
            Write-Host "  - Items returned: $($items2.Count)" -ForegroundColor Gray
            Write-Host "  - Has next page: $($pageInfo2.hasNextPage)" -ForegroundColor Gray
            Write-Host "  - Has previous page: $($pageInfo2.hasPreviousPage)" -ForegroundColor Gray
            Write-Host ""
            
            if ($items2.Count -gt 0) {
                Write-Host "[PASS] Test 2: Got items on page 2" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Test 2: No items on page 2 (may be valid if only 5 total items)" -ForegroundColor Yellow
            }
            
            if ($pageInfo2.hasPreviousPage -eq $true) {
                Write-Host "[PASS] Test 2: Has previous page (expected)" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Test 2: No previous page on second page" -ForegroundColor Yellow
            }
            
            # Verify items are different
            $firstPageIds = $response1.data.search.results.items | ForEach-Object { $_.id }
            $secondPageIds = $items2 | ForEach-Object { $_.id }
            $overlap = $firstPageIds | Where-Object { $secondPageIds -contains $_ }
            
            if ($overlap.Count -eq 0) {
                Write-Host "[PASS] Test 2: No duplicate items between pages" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] Test 2: Found $($overlap.Count) duplicate items between pages!" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "[FAIL] Test 2 failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

# Test 3: Large page size
Write-Host "[TEST 3] Large page (first: 100)" -ForegroundColor Yellow
Write-Host ""

$query3 = @"
{
  search(
    rootItem: "/sitecore/content"
    first: 100
    language: "en"
  ) {
    results {
      items {
        id
        name
      }
      pageInfo {
        hasNextPage
        endCursor
      }
      totalCount
    }
  }
}
"@

try {
    $body3 = @{ query = $query3 } | ConvertTo-Json -Depth 10
    $response3 = Invoke-RestMethod -Uri $ENDPOINT -Method Post -Body $body3 -ContentType "application/json" -Headers @{ "sc_apikey" = $API_KEY }
    
    if ($response3.errors) {
        Write-Host "[FAIL] GraphQL errors: $($response3.errors | ConvertTo-Json)" -ForegroundColor Red
    } else {
        $items3 = $response3.data.search.results.items
        $pageInfo3 = $response3.data.search.results.pageInfo
        $total3 = $response3.data.search.results.totalCount
        
        Write-Host "[OK] Large page retrieved!" -ForegroundColor Green
        Write-Host "  - Items returned: $($items3.Count)" -ForegroundColor Gray
        Write-Host "  - Total count: $total3" -ForegroundColor Gray
        Write-Host "  - Has next page: $($pageInfo3.hasNextPage)" -ForegroundColor Gray
        Write-Host ""
        
        if ($items3.Count -le 100) {
            Write-Host "[PASS] Test 3: Items within limit" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Test 3: Returned more than 100 items!" -ForegroundColor Red
        }
        
        if ($total3 -ge $items3.Count) {
            Write-Host "[PASS] Test 3: Total count >= items returned" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Test 3: Total count < items returned!" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "[FAIL] Test 3 failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Pagination Tests Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
