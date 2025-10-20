# Test Search Query Structure
# Load environment variables via canonical loader
. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$Headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "[INFO] Testing search query structure..." -ForegroundColor Cyan
if (-not $env:SITECORE_ENDPOINT -and $env:SITECORE_HOST) { $env:SITECORE_ENDPOINT = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master" }
Write-Host ""
$endpoint = $env:SITECORE_ENDPOINT

# Test 1: Simple search with __typename
$query1 = @'
{
  search(keyword: "Home", first: 1) {
    __typename
  }
}
'@

Write-Host "Test 1: Search basic structure" -ForegroundColor Yellow
try {
    $body = @{ query = $query1 } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $Headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Search with results
$query2 = @'
{
  search(keyword: "Home", first: 1) {
    results {
      __typename
    }
  }
}
'@

Write-Host "Test 2: Search results structure" -ForegroundColor Yellow
try {
    $body = @{ query = $query2 } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $Headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Search with item properties
$query3 = @'
{
  search(keyword: "Home", first: 1) {
    results {
      items {
        id
        name
        path
      }
    }
  }
}
'@

Write-Host "Test 3: Search results with item" -ForegroundColor Yellow
try {
    $body = @{ query = $query3 } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $Headers -Body $body
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10
    Write-Host ""
  Write-Host "[OK] SUCCESS! Correct structure found:" -ForegroundColor Green
  Write-Host "search.results.items is an array of items (id, name, path)" -ForegroundColor Yellow
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""
