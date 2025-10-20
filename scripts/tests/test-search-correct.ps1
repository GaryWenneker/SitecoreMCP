# Test Correct Search Structure
. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$Headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "[INFO] Testing CORRECT search structure..." -ForegroundColor Cyan
Write-Host ""

# Endpoint fallback: prefer SITECORE_ENDPOINT, else build from SITECORE_HOST
$endpoint = $env:SITECORE_ENDPOINT
if (-not $endpoint -and $env:SITECORE_HOST) {
  $endpoint = "$(($env:SITECORE_HOST))/sitecore/api/graph/items/master"
}

# Correct structure based on error hints
$queryCorrect = @'
{
  search(keyword: "Home", first: 5) {
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

Write-Host "Test: Search with items (plural)" -ForegroundColor Yellow
try {
    $body = @{ query = $queryCorrect } | ConvertTo-Json
  $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $Headers -Body $body
    Write-Host "[OK] SUCCESS!" -ForegroundColor Green
    $response.data | ConvertTo-Json -Depth 10
    Write-Host ""
    Write-Host "CORRECT SCHEMA:" -ForegroundColor Green
    Write-Host "search { results { items { id name path } } }" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Access pattern: result.search.results.items (NOT .item!)" -ForegroundColor Cyan
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""
