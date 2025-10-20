# Test: Can we search templates at all?

. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "[TEST 1] Search templates with keyword 'Template'" -ForegroundColor Cyan
$query1 = @"
{
  search(
    keyword: "Template"
    rootItem: "/sitecore/templates"
    language: "en"
    first: 10
  ) {
    results {
      items {
        id
        name
        path
      }
    }
  }
}
"@

$response1 = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body (@{ query = $query1 } | ConvertTo-Json) -ContentType "application/json"

if ($response1.data.search.results.items) {
    Write-Host "[OK] Found $($response1.data.search.results.items.Count) items" -ForegroundColor Green
    $response1.data.search.results.items | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.name) [$($_.id)]" -ForegroundColor Gray
        Write-Host "    $($_.path)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[FAIL] No results" -ForegroundColor Red
}

Write-Host ""
Write-Host "[TEST 2] Search templates with keyword 'TestFeature'" -ForegroundColor Cyan
$query2 = @"
{
  search(
    keyword: "TestFeature"
    rootItem: "/sitecore/templates"
    language: "en"
    first: 10
  ) {
    results {
      items {
        id
        name
        path
      }
    }
  }
}
"@

$response2 = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body (@{ query = $query2 } | ConvertTo-Json) -ContentType "application/json"

if ($response2.data.search.results.items) {
    Write-Host "[OK] Found $($response2.data.search.results.items.Count) items" -ForegroundColor Green
    $response2.data.search.results.items | ForEach-Object {
        Write-Host "  - $($_.name) [$($_.id)]" -ForegroundColor Gray
        Write-Host "    $($_.path)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[FAIL] No results" -ForegroundColor Red
}

Write-Host ""
Write-Host "[TEST 3] Search ALL items (no rootItem filter)" -ForegroundColor Cyan
$query3 = @"
{
  search(
    keyword: "TestFeature"
    language: "en"
    first: 10
  ) {
    results {
      items {
        id
        name
        path
      }
    }
  }
}
"@

$response3 = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body (@{ query = $query3 } | ConvertTo-Json) -ContentType "application/json"

if ($response3.data.search.results.items) {
    Write-Host "[OK] Found $($response3.data.search.results.items.Count) items" -ForegroundColor Green
    $response3.data.search.results.items | ForEach-Object {
        Write-Host "  - $($_.name) [$($_.id)]" -ForegroundColor Gray
        Write-Host "    $($_.path)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[FAIL] No results" -ForegroundColor Red
}
