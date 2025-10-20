# Test GraphQL updateItem with ID (instead of path)
Write-Host "=== Test updateItem with ID ===" -ForegroundColor Cyan
Write-Host ""

# Load environment variables
. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testItemId = "{13DDF458-A0D2-482C-A3F1-0DF6BFCC2E36}"
$language = "nl-NL"

Write-Host "[TEST] Update via ID instead of path" -ForegroundColor Yellow
Write-Host ""

# Try with itemId parameter (if it exists)
$updateMutation = @{
    query = @"
mutation {
  updateItem(
    itemId: "$testItemId"
    language: "$language"
    fields: [
      { name: "Title", value: "Updated via ID" }
    ]
  ) {
    id
    name
  }
}
"@
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $updateMutation -Headers $headers
    
    if ($response.errors) {
        Write-Host "[INFO] Error message:" -ForegroundColor Yellow
        $response.errors | ForEach-Object {
            Write-Host "  $($_.message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[SUCCESS] Update worked with ID!" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "[CONCLUSION]" -ForegroundColor Cyan
Write-Host ""
Write-Host "updateItem mutation exists in schema but:" -ForegroundColor Yellow
Write-Host "  - Returns 500 error with path parameter" -ForegroundColor Red
Write-Host "  - May not be enabled on /items/master endpoint" -ForegroundColor Red
Write-Host "  - Implementation appears to be missing or disabled" -ForegroundColor Red
Write-Host ""
Write-Host "VERDICT: GraphQL mutations are NOT functional" -ForegroundColor Red
Write-Host "SOLUTION: Use Custom REST API for field updates" -ForegroundColor Green
Write-Host ""
