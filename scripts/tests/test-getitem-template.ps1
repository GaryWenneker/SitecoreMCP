# Test getItem() for template ID
# Check if getItem works with template ID {CFFDFAFA317F4E5498988D16E6BB1E68}

# Load environment variables from .env file
. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "[TEST] Get template via getItem() pattern..." -ForegroundColor Cyan

$templateId = "{CFFDFAFA317F4E5498988D16E6BB1E68}"

$query = @"
{
  item(path: "$templateId", language: "en") {
    id
    name
    displayName
    path
    template { id name }
  }
}
"@

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body (@{ query = $query } | ConvertTo-Json) -ContentType "application/json"
    
    if ($response.errors) {
        Write-Host "[FAIL] GraphQL errors:" -ForegroundColor Red
        $response.errors | ForEach-Object { Write-Host "  $($_.message)" -ForegroundColor Red }
    }
    elseif ($response.data.item) {
        Write-Host "[OK] Template found via ID!" -ForegroundColor Green
        Write-Host "  Name: $($response.data.item.name)" -ForegroundColor Gray
        Write-Host "  Path: $($response.data.item.path)" -ForegroundColor Gray
    }
    else {
        Write-Host "[FAIL] Template not found (null result)" -ForegroundColor Red
        Write-Host "Full response:" -ForegroundColor Yellow
        $response.data | ConvertTo-Json -Depth 5
    }
} catch {
    Write-Host "[FAIL] Request failed: $($_.Exception.Message)" -ForegroundColor Red
}
