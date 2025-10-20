# Test Search API Fixes
# Tests voor ContentSearchResult schema fixes

Write-Host ""
Write-Host "=== Test Search API Fixes ===" -ForegroundColor Cyan
Write-Host ""

# Load environment
. .\Load-DotEnv.ps1

$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"

Write-Host "[INFO] Testing ContentSearchResult schema..." -ForegroundColor Yellow
Write-Host "Endpoint: $endpoint" -ForegroundColor Gray
Write-Host ""

# Test 1: Basic search query with correct fields
Write-Host "Test 1: Basic Search (nameContains: TestFeatures)" -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Gray

$query1 = @"
{
  search(keyword: "TestFeatures", language: "en", first: 5) {
    results {
      items {
        id
        name
        path
        templateName
        url
        language {
          name
        }
      }
    }
  }
}
"@

try {
    $response1 = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body (@{ query = $query1 } | ConvertTo-Json)
    
    if ($response1.errors) {
        Write-Host "[FAIL] GraphQL errors:" -ForegroundColor Red
        $response1.errors | ForEach-Object { Write-Host "  - $($_.message)" -ForegroundColor Red }
    } else {
        $itemCount = $response1.data.search.results.items.Count
        Write-Host "[PASS] Query successful!" -ForegroundColor Green
        Write-Host "Items found: $itemCount" -ForegroundColor Yellow
        
        if ($itemCount -gt 0) {
            Write-Host ""
            Write-Host "First item:" -ForegroundColor Yellow
            $first = $response1.data.search.results.items[0]
            Write-Host "  ID: $($first.id)" -ForegroundColor Gray
            Write-Host "  Name: $($first.name)" -ForegroundColor Gray
            Write-Host "  Path: $($first.path)" -ForegroundColor Gray
            Write-Host "  TemplateName: $($first.templateName)" -ForegroundColor Gray
            Write-Host "  Language: $($first.language.name)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "[FAIL] HTTP Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "-----------------------------------------------" -ForegroundColor Gray
Write-Host ""

# Test 2: Search with facets
Write-Host "Test 2: Search with Pagination Fields" -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Gray

$query2 = @"
{
  search(keyword: "Home", language: "en", first: 2) {
    results {
      items {
        id
        name
        path
        templateName
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
    $response2 = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body (@{ query = $query2 } | ConvertTo-Json)
    
    if ($response2.errors) {
        Write-Host "[FAIL] GraphQL errors:" -ForegroundColor Red
        $response2.errors | ForEach-Object { Write-Host "  - $($_.message)" -ForegroundColor Red }
    } else {
        Write-Host "[PASS] Query successful!" -ForegroundColor Green
        Write-Host "TotalCount: $($response2.data.search.results.totalCount)" -ForegroundColor Yellow
        Write-Host "HasNextPage: $($response2.data.search.results.pageInfo.hasNextPage)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[FAIL] HTTP Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "-----------------------------------------------" -ForegroundColor Gray
Write-Host ""

# Test 3: Test MCP tool via Node.js
Write-Host "Test 3: MCP Tool sitecore_search" -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Gray

$mcpTest = @"
const { SitecoreService } = require('./dist/index.js');

(async () => {
  try {
    const service = new SitecoreService(
      process.env.SITECORE_HOST,
      process.env.SITECORE_USERNAME,
      process.env.SITECORE_PASSWORD,
      process.env.SITECORE_API_KEY
    );
    
    const results = await service.searchItems(
      'TestFeatures',
      undefined,
      undefined,
      'en',
      'master',
      5
    );
    
    console.log('[PASS] MCP search successful!');
    console.log('Items found:', results.length);
    
    if (results.length > 0) {
      console.log('\nFirst item:');
      console.log('  Name:', results[0].name);
      console.log('  Path:', results[0].path);
      console.log('  TemplateName:', results[0].templateName);
    }
  } catch (error) {
    console.log('[FAIL] MCP Error:', error.message);
  }
})();
"@

$mcpTest | Out-File -FilePath "test-mcp-search.cjs" -Encoding UTF8

try {
    $output = node test-mcp-search.cjs 2>&1
    Write-Host $output -ForegroundColor Yellow
    
    if ($output -match "\[PASS\]") {
        Write-Host ""
        Write-Host "[PASS] MCP tool works correctly!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "[FAIL] MCP tool has errors" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Node.js Error: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item "test-mcp-search.cjs" -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "-----------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "All ContentSearchResult schema fixes tested" -ForegroundColor Yellow
Write-Host ""
