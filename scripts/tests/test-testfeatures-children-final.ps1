# Test: Get TestFeatures folder and its direct children
. "$PSScriptRoot\Load-DotEnv.ps1"

$endpoint = $env:SITECORE_ENDPOINT
$apiKey = $env:SITECORE_API_KEY

$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

# First: Get Feature folder and find TestFeatures
$query1 = @"
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
    }
  }
}
"@

Write-Host "[INFO] Getting Feature folder to find TestFeatures..." -ForegroundColor Cyan

$body1 = @{ query = $query1 } | ConvertTo-Json -Depth 10
$response1 = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $body1 -ContentType "application/json" -UseBasicParsing

$testFeatures = $response1.data.item.children | Where-Object { $_.name -eq "TestFeatures" }

if ($testFeatures) {
    Write-Host "[OK] Found TestFeatures:" -ForegroundColor Green
    Write-Host "  ID: $($testFeatures.id)" -ForegroundColor Yellow
    Write-Host "  Path: $($testFeatures.path)" -ForegroundColor Yellow
    Write-Host "  Has Children: $($testFeatures.hasChildren)" -ForegroundColor Yellow
    Write-Host ""
    
    # Now get TestFeatures and its children
    $query2 = @"
{
  item(
    path: "$($testFeatures.path)"
    language: "en"
  ) {
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

    Write-Host "[INFO] Getting children of TestFeatures..." -ForegroundColor Cyan
    
    $body2 = @{ query = $query2 } | ConvertTo-Json -Depth 10
    try {
        $response2 = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $body2 -ContentType "application/json" -UseBasicParsing -TimeoutSec 15
        
        if ($response2.data.item) {
            Write-Host "[OK] TestFeatures item retrieved!" -ForegroundColor Green
            Write-Host "  Has Children: $($response2.data.item.hasChildren)" -ForegroundColor Yellow
            
            if ($response2.data.item.children) {
                Write-Host "[OK] Found $($response2.data.item.children.Count) children:" -ForegroundColor Green
                foreach ($child in $response2.data.item.children) {
                    Write-Host "  - $($child.name)" -ForegroundColor Gray
                    Write-Host "    Path: $($child.path)" -ForegroundColor DarkGray
                    Write-Host "    Template: $($child.template.name)" -ForegroundColor DarkGray
                    Write-Host "    Has Children: $($child.hasChildren)" -ForegroundColor DarkGray
                    Write-Host ""
                }
            } else {
                Write-Host "[WARN] No children array returned" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[FAIL] Item query returned null" -ForegroundColor Red
            Write-Host "Response:" -ForegroundColor Yellow
            $response2.data | ConvertTo-Json -Depth 10
        }
    } catch {
        Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[FAIL] TestFeatures not found in Feature children" -ForegroundColor Red
}
