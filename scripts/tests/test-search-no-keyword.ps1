# Test: Search all items under TestFeatures (no keyword filter)
. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$endpoint = $env:SITECORE_ENDPOINT
if (-not $endpoint -and $env:SITECORE_HOST) { $endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master" }
$apiKey = $env:SITECORE_API_KEY

$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

$query = @"
{
  search(
    rootItem: "/sitecore/templates/Feature/TestFeatures"
    language: "en"
    first: 50
  ) {
    results {
      items {
        id
        name
        path
        templateName
      }
    }
  }
}
"@

Write-Host "[INFO] Searching all items under TestFeatures (no keyword)..." -ForegroundColor Cyan

$body = @{ query = $query } | ConvertTo-Json -Depth 10
$response = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 10

Write-Host ""
Write-Host "Response:" -ForegroundColor Yellow
$response.data.search | ConvertTo-Json -Depth 10

if ($response.data.search.results.items) {
    Write-Host ""
  $count = $response.data.search.results.items.Count
  Write-Host "[OK] Found $count items!" -ForegroundColor Green
    foreach ($item in $response.data.search.results.items) {
        Write-Host "  - $($item.name) ($($item.templateName))" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "[FAIL] No items found" -ForegroundColor Red
}
