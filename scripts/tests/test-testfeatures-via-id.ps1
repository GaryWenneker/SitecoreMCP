# Test: Get TestFeatures via parent's children

. "$PSScriptRoot\Load-DotEnv.ps1"

$endpoint = "$env:SITECORE_HOST/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "Getting TestFeatures via Feature folder children..." -ForegroundColor Cyan

# First get Feature folder
$query1 = @"
{
  item(path: "/sitecore/templates/Feature", language: "en") {
    children(first: 100) {
      id
      name
      path
    }
  }
}
"@

$body1 = @{ query = $query1 } | ConvertTo-Json
$response1 = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body1

$testFeaturesChild = $response1.data.item.children | Where-Object { $_.name -eq "TestFeatures" }

if ($testFeaturesChild) {
    Write-Host "Found TestFeatures child!" -ForegroundColor Green
    Write-Host "  ID: $($testFeaturesChild.id)" -ForegroundColor Gray
    Write-Host "  Path: $($testFeaturesChild.path)" -ForegroundColor Gray
    
    # Now get children by ID
    Write-Host ""
    Write-Host "Getting children of TestFeatures by ID..." -ForegroundColor Cyan
    
    $query2 = @"
{
  item(itemId: "$($testFeaturesChild.id)", language: "en") {
    id
    name
    path
    hasChildren
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
    
    $body2 = @{ query = $query2 } | ConvertTo-Json
    $response2 = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body2
    
    if ($response2.data.item) {
        Write-Host "TestFeatures folder details:" -ForegroundColor Yellow
        Write-Host "  HasChildren: $($response2.data.item.hasChildren)" -ForegroundColor Gray
        Write-Host "  Children count: $($response2.data.item.children.Count)" -ForegroundColor Gray
        
        if ($response2.data.item.children) {
            Write-Host ""
            Write-Host "Children found:" -ForegroundColor Green
            foreach ($child in $response2.data.item.children) {
                Write-Host "  - $($child.name) [$($child.template.name)]" -ForegroundColor Cyan
                Write-Host "    Path: $($child.path)" -ForegroundColor Gray
                Write-Host "    HasChildren: $($child.hasChildren)" -ForegroundColor Gray
            }
        }
    }
} else {
    Write-Host "TestFeatures not found in Feature children" -ForegroundColor Red
}
