# Test: Get Feature folder with nested children navigation
. "$PSScriptRoot\Load-DotEnv.ps1"

$endpoint = $env:SITECORE_ENDPOINT
$apiKey = $env:SITECORE_API_KEY

$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

# Get Feature folder with ALL nested children (TestFeatures + its children)
$query = @"
{
  item(
    path: "/sitecore/templates/Feature"
    language: "en"
  ) {
    id
    name
    children(first: 100) {
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
}
"@

Write-Host "[INFO] Getting Feature folder with nested children (Feature > TestFeatures > _TestFeature)..." -ForegroundColor Cyan

$body = @{ query = $query } | ConvertTo-Json -Depth 10
$response = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $body -ContentType "application/json" -UseBasicParsing

if ($response.data.item) {
    Write-Host "[OK] Feature folder retrieved!" -ForegroundColor Green
    Write-Host ""
    
    $testFeatures = $response.data.item.children | Where-Object { $_.name -eq "TestFeatures" }
    
    if ($testFeatures) {
        Write-Host "[OK] Found TestFeatures folder:" -ForegroundColor Green
        Write-Host "  ID: $($testFeatures.id)" -ForegroundColor Yellow
        Write-Host "  Path: $($testFeatures.path)" -ForegroundColor Yellow
        Write-Host "  Has Children: $($testFeatures.hasChildren)" -ForegroundColor Yellow
        Write-Host ""
        
        if ($testFeatures.children) {
            Write-Host "[OK] Found $($testFeatures.children.Count) children of TestFeatures:" -ForegroundColor Green
            foreach ($child in $testFeatures.children) {
                Write-Host "  - $($child.name)" -ForegroundColor Gray
                Write-Host "    Path: $($child.path)" -ForegroundColor DarkGray
                Write-Host "    Template: $($child.template.name)" -ForegroundColor DarkGray
                Write-Host "    Has Children: $($child.hasChildren)" -ForegroundColor DarkGray
                
                if ($child.hasChildren -and $child.children) {
                    Write-Host "    Nested children: $($child.children.Count)" -ForegroundColor DarkGray
                }
                Write-Host ""
            }
        } else {
            Write-Host "[WARN] No children found under TestFeatures" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[FAIL] TestFeatures not found in Feature children" -ForegroundColor Red
    }
} else {
    Write-Host "[FAIL] Feature folder not found" -ForegroundColor Red
}
