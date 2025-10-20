# Test script voor nieuwe GraphQL functies: Layout en Site queries
$apiKey = if ($env:SITECORE_API_KEY) { $env:SITECORE_API_KEY } else { "{YOUR-API-KEY}" }
$endpoint = if ($env:SITECORE_ENDPOINT) { $env:SITECORE_ENDPOINT } else { "https://your-sitecore-instance.com/sitecore/api/graph/items/master" }

if ($apiKey -eq "{YOUR-API-KEY}") {
    Write-Host "ERROR: SITECORE_API_KEY environment variable is required" -ForegroundColor Red
    exit 1
}

$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

Write-Host "`n=== Test 1: Get Layout ===" -ForegroundColor Green
$query1 = @"
{
  layout(path: "/sitecore/content") {
    item {
      id
      name
      path
      displayName
    }
  }
}
"@

$body1 = @{ query = $query1 } | ConvertTo-Json
try {
    $response1 = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body1 -Headers $headers
    Write-Host "Result:" -ForegroundColor Yellow
    $response1 | ConvertTo-Json -Depth 10
    Write-Host "`nTest 1: PASSED" -ForegroundColor Green
} catch {
    Write-Host "Test 1: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test 2: Get Site by Name ===" -ForegroundColor Green
$query2 = @"
{
  site(name: "website") {
    name
    hostName
    rootPath
    startItem
    language
    database
  }
}
"@

$body2 = @{ query = $query2 } | ConvertTo-Json
try {
    $response2 = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body2 -Headers $headers
    Write-Host "Result:" -ForegroundColor Yellow
    $response2 | ConvertTo-Json -Depth 10
    Write-Host "`nTest 2: PASSED" -ForegroundColor Green
} catch {
    Write-Host "Test 2: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test 3: Get All Sites ===" -ForegroundColor Green
$query3 = @"
{
  __type(name: "Query") {
    fields {
      name
      description
      args {
        name
        type {
          name
          kind
        }
      }
    }
  }
}
"@

$body3 = @{ query = $query3 } | ConvertTo-Json
try {
    $response3 = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body3 -Headers $headers
    Write-Host "Available Query fields:" -ForegroundColor Yellow
    $response3.data.__type.fields | Where-Object { $_.name -in @('layout', 'site', 'item', 'search') } | 
        Format-Table name, description -Wrap
    Write-Host "`nTest 3: PASSED" -ForegroundColor Green
} catch {
    Write-Host "Test 3: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== All Tests Complete ===" -ForegroundColor Cyan
