# Quick Debug: List all Feature templates

. "$PSScriptRoot\Load-DotEnv.ps1"

$endpoint = "$env:SITECORE_HOST/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "Checking /sitecore/templates/Feature folder..." -ForegroundColor Cyan

$query = @"
{
  item(path: "/sitecore/templates/Feature", language: "en") {
    id
    name
    path
    children(first: 100) {
      id
      name
      path
      hasChildren
    }
  }
}
"@

$body = @{ query = $query } | ConvertTo-Json
$response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body

Write-Host ""
if ($response.data.item) {
    Write-Host "Feature folder found!" -ForegroundColor Green
    Write-Host "Children:" -ForegroundColor Yellow
    foreach ($child in $response.data.item.children) {
        Write-Host "  - $($child.name) ($($child.path))" -ForegroundColor Gray
        if ($child.name -like "*Test*") {
            Write-Host "    ^^^ THIS ONE MATCHES 'Test'!" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Feature folder NOT found" -ForegroundColor Red
}
