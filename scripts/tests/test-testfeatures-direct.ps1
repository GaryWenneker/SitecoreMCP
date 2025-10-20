# Test: Get TestFeatures folder directly

. "$PSScriptRoot\Load-DotEnv.ps1"

$endpoint = "$env:SITECORE_HOST/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "Testing TestFeatures folder access..." -ForegroundColor Cyan

$query = @"
{
  item(path: "/sitecore/templates/Feature/TestFeatures", language: "en") {
    id
    name
    displayName
    path
    hasChildren
    template {
      id
      name
    }
    children(first: 100) {
      id
      name
      displayName
      path
      hasChildren
      template {
        name
      }
    }
  }
}
"@

$body = @{ query = $query } | ConvertTo-Json
$response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body

Write-Host ""
Write-Host "Raw response:" -ForegroundColor Yellow
$response.data | ConvertTo-Json -Depth 5

Write-Host ""
if ($response.data.item) {
    Write-Host "TestFeatures folder found!" -ForegroundColor Green
    Write-Host "  ID: $($response.data.item.id)" -ForegroundColor Gray
    Write-Host "  Name: $($response.data.item.name)" -ForegroundColor Gray
    Write-Host "  Path: $($response.data.item.path)" -ForegroundColor Gray
    Write-Host "  HasChildren: $($response.data.item.hasChildren)" -ForegroundColor Gray
    Write-Host "  Children count: $($response.data.item.children.Count)" -ForegroundColor Gray
    
    if ($response.data.item.children) {
        Write-Host ""
        Write-Host "Children:" -ForegroundColor Yellow
        foreach ($child in $response.data.item.children) {
            Write-Host "  - $($child.name) [$($child.template.name)]" -ForegroundColor Cyan
            Write-Host "    Path: $($child.path)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "TestFeatures folder NOT found or NULL" -ForegroundColor Red
}

if ($response.errors) {
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    $response.errors | ConvertTo-Json -Depth 3
}
