# Test: Get template as regular item using GUID without curly braces

. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Template as Item Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test different formats
$formats = @(
    @{ Name = "With curly braces"; Id = "{CFFDFAFA-317F-4E54-9898-8D16E6BB1E68}" },
    @{ Name = "Without curly braces"; Id = "CFFDFAFA-317F-4E54-9898-8D16E6BB1E68" },
    @{ Name = "With curly braces (lowercase)"; Id = "{cffdfafa-317f-4e54-9898-8d16e6bb1e68}" }
)

foreach ($format in $formats) {
    Write-Host "[TEST] $($format.Name): $($format.Id)" -ForegroundColor Cyan
    
    $query = @"
{
  item(path: "$($format.Id)", language: "en") {
    id
    name
    displayName
    path
    template { id name }
    hasChildren
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@

    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body (@{ query = $query } | ConvertTo-Json) -ContentType "application/json"
        
        if ($response.errors) {
            Write-Host "  [FAIL] GraphQL errors:" -ForegroundColor Red
            $response.errors | ForEach-Object { Write-Host "    $($_.message)" -ForegroundColor Red }
        }
        elseif ($response.data.item) {
            Write-Host "  [OK] Template found!" -ForegroundColor Green
            Write-Host "    ID: $($response.data.item.id)" -ForegroundColor Gray
            Write-Host "    Name: $($response.data.item.name)" -ForegroundColor Gray
            Write-Host "    Path: $($response.data.item.path)" -ForegroundColor Gray
            Write-Host "    Fields: $($response.data.item.fields.Count)" -ForegroundColor Gray
            
            # Check for base template
            $baseField = $response.data.item.fields | Where-Object { $_.name -eq "__Base template" }
            if ($baseField) {
                Write-Host "    Base Template: $($baseField.value)" -ForegroundColor Yellow
            }
            
            Write-Host ""
            Write-Host "  [SUCCESS] This format WORKS!" -ForegroundColor Green
            break
        }
        else {
            Write-Host "  [FAIL] Item returned null" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Request failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}
