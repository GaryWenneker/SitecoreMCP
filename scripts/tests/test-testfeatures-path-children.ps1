# Quick test: Get TestFeatures children via path
. "$PSScriptRoot\Load-DotEnv.ps1"

$endpoint = $env:SITECORE_ENDPOINT
$apiKey = $env:SITECORE_API_KEY

$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

$query = @"
{
  item(
    path: "/sitecore/templates/Feature/TestFeatures"
    language: "en"
  ) {
    id
    name
    path
    hasChildren
    children(first: 10) {
      id
      name
      path
    }
  }
}
"@

Write-Host "[INFO] Testing path query for TestFeatures children..." -ForegroundColor Cyan

$body = @{ query = $query } | ConvertTo-Json -Depth 10
$response = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 10

Write-Host ""
Write-Host "Response:" -ForegroundColor Yellow
$response | ConvertTo-Json -Depth 10

if ($response.data.item) {
    Write-Host ""
    Write-Host "[OK] Item found!" -ForegroundColor Green
    Write-Host "  Name: $($response.data.item.name)" -ForegroundColor Yellow
    Write-Host "  Path: $($response.data.item.path)" -ForegroundColor Yellow
    Write-Host "  Has Children: $($response.data.item.hasChildren)" -ForegroundColor Yellow
    if ($response.data.item.children) {
        Write-Host "  Children Count: $($response.data.item.children.Count)" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "[FAIL] Item not found" -ForegroundColor Red
}
