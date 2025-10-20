# Search for GaryTestFeature content item
. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$endpoint = $env:SITECORE_ENDPOINT
if (-not $endpoint -and $env:SITECORE_HOST) { $endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master" }
$apiKey = $env:SITECORE_API_KEY

$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

Write-Host "[INFO] Searching for GaryTestFeature..." -ForegroundColor Cyan

# Search in content tree
$query = @"
{
  search(
    keyword: "GaryTestFeature"
    rootItem: "/sitecore/content"
    language: "en"
    first: 10
  ) {
    results {
      items {
        id
        name
        path
        templateName
        language
      }
    }
  }
}
"@

$body = @{ query = $query } | ConvertTo-Json -Depth 10
$response = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $body -ContentType "application/json" -UseBasicParsing

if ($response.data.search.results.items -and $response.data.search.results.items.Count -gt 0) {
  $cnt = $response.data.search.results.items.Count
  Write-Host "[OK] Found $cnt item(s):" -ForegroundColor Green
    foreach ($item in $response.data.search.results.items) {
        Write-Host ""
        Write-Host "  Name: $($item.name)" -ForegroundColor Yellow
        Write-Host "  Path: $($item.path)" -ForegroundColor Gray
        Write-Host "  Template: $($item.templateName)" -ForegroundColor Gray
        Write-Host "  Language: $($item.language)" -ForegroundColor Gray
        Write-Host "  ID: $($item.id)" -ForegroundColor Gray
    }
} else {
    Write-Host "[WARN] No items found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Trying broader search (entire database)..." -ForegroundColor Cyan
    
    $query2 = @"
{
  search(
    keyword: "GaryTestFeature"
    language: "en"
    first: 10
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

    $body2 = @{ query = $query2 } | ConvertTo-Json -Depth 10
    $response2 = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $body2 -ContentType "application/json" -UseBasicParsing
    
  if ($response2.data.search.results.items -and $response2.data.search.results.items.Count -gt 0) {
    $cnt2 = $response2.data.search.results.items.Count
    Write-Host "[OK] Found $cnt2 item(s) in entire database:" -ForegroundColor Green
        foreach ($item in $response2.data.search.results.items) {
            Write-Host ""
            Write-Host "  Name: $($item.name)" -ForegroundColor Yellow
            Write-Host "  Path: $($item.path)" -ForegroundColor Gray
            Write-Host "  Template: $($item.templateName)" -ForegroundColor Gray
        }
    } else {
        Write-Host "[FAIL] Item not found anywhere" -ForegroundColor Red
    }
}
