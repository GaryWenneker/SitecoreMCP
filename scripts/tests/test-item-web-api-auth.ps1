# Test Item Web API with Basic Authentication
Write-Host "=== Test Item Web API with Basic Auth ===" -ForegroundColor Cyan
Write-Host ""

# Load environment variables
. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

if (-not $env:SITECORE_USERNAME -or -not $env:SITECORE_PASSWORD) {
    Write-Host "[ERROR] SITECORE_USERNAME or SITECORE_PASSWORD not found in .env" -ForegroundColor Red
    exit 1
}

$baseUrl = $env:SITECORE_HOST
$testItemId = "{13DDF458-A0D2-482C-A3F1-0DF6BFCC2E36}"
$itemUrl = "$baseUrl/sitecore/api/ssc/item/$testItemId"

Write-Host "[INFO] Testing Item Web API with Basic authentication" -ForegroundColor Yellow
Write-Host "Base URL: $baseUrl" -ForegroundColor Gray
Write-Host "Item ID: $testItemId" -ForegroundColor Gray
Write-Host ""

# Prepare Basic auth header
$credentials = "$($env:SITECORE_USERNAME):$($env:SITECORE_PASSWORD)"
$encodedCreds = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes($credentials))

$headers = @{
    "Authorization" = "Basic $encodedCreds"
    "Content-Type" = "application/json"
}

# Test 1: GET item
Write-Host "[TEST 1] GET item with Basic auth" -ForegroundColor Cyan
Write-Host "URL: $itemUrl" -ForegroundColor Gray
Write-Host ""

try {
    Write-Host "[INFO] Sending GET request..." -ForegroundColor Yellow
    $item = Invoke-RestMethod -Uri $itemUrl -Method GET -Headers $headers
    
    Write-Host "[OK] Item retrieved successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Item Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($item.ItemName)" -ForegroundColor White
    Write-Host "  ID: $($item.ItemID)" -ForegroundColor White
    Write-Host "  Path: $($item.ItemPath)" -ForegroundColor White
    Write-Host "  Language: $($item.ItemLanguage)" -ForegroundColor White
    Write-Host ""
    
    if ($item.Fields) {
        Write-Host "  Fields (first 10):" -ForegroundColor White
        $item.Fields | Select-Object -First 10 | ForEach-Object {
            Write-Host "    - $($_.Name): $($_.Value)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Store current Title value
    $currentTitle = ($item.Fields | Where-Object { $_.Name -eq "Title" }).Value
    Write-Host "  Current Title: $currentTitle" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "[FAIL] GET request failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "Access forbidden (403). Possible reasons:" -ForegroundColor Yellow
        Write-Host "  1. Item Web API not enabled" -ForegroundColor White
        Write-Host "  2. User lacks permissions" -ForegroundColor White
        Write-Host "  3. Different URL pattern required" -ForegroundColor White
    } elseif ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "Authentication failed (401). Possible reasons:" -ForegroundColor Yellow
        Write-Host "  1. Incorrect username/password" -ForegroundColor White
        Write-Host "  2. Different auth method required" -ForegroundColor White
    } elseif ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "Endpoint not found (404). Item Web API may not be available." -ForegroundColor Yellow
    }
    Write-Host ""
    exit 1
}

# Test 2: PATCH item (update field) - DRY RUN
Write-Host "[TEST 2] PATCH item (update field) - DRY RUN" -ForegroundColor Cyan
Write-Host ""

$updatePayload = @{
    ItemID = $testItemId
    Language = "nl-NL"
    Fields = @(
        @{
            Name = "Title"
            Value = "Updated via Item Web API - TEST"
        }
    )
} | ConvertTo-Json -Depth 5

Write-Host "Update Payload:" -ForegroundColor Yellow
Write-Host $updatePayload -ForegroundColor Gray
Write-Host ""

Write-Host "[INFO] This would send PATCH request to: $itemUrl" -ForegroundColor Yellow
Write-Host "[INFO] Not executing to avoid accidental changes" -ForegroundColor Yellow
Write-Host ""

Write-Host "[INFO] To execute the update, uncomment the code below:" -ForegroundColor Yellow
Write-Host @"
# Uncomment to execute:
# try {
#     `$response = Invoke-RestMethod -Uri `$itemUrl ``
#         -Method PATCH ``
#         -Headers `$headers ``
#         -Body `$updatePayload
#     
#     Write-Host "[OK] Field updated successfully!" -ForegroundColor Green
#     `$response | ConvertTo-Json -Depth 5
# } catch {
#     Write-Host "[FAIL] PATCH request failed: `$(`$_.Exception.Message)" -ForegroundColor Red
# }
"@ -ForegroundColor Gray

Write-Host ""
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""

if ($item) {
    Write-Host "[INFO] Item Web API Status:" -ForegroundColor Yellow
    Write-Host "  Endpoint: Available" -ForegroundColor Green
    Write-Host "  Authentication: Basic auth with username/password" -ForegroundColor Green
    Write-Host "  GET operations: Working" -ForegroundColor Green
    Write-Host "  PATCH operations: Not tested (dry-run only)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[NEXT STEPS]" -ForegroundColor Yellow
    Write-Host "  1. Uncomment PATCH code to test actual field update" -ForegroundColor White
    Write-Host "  2. Verify field was updated in Sitecore" -ForegroundColor White
    Write-Host "  3. Implement sitecore_update_field MCP tool" -ForegroundColor White
    Write-Host "  4. Test via Claude Desktop with real field update" -ForegroundColor White
    Write-Host ""
    Write-Host "[RECOMMENDATION]" -ForegroundColor Green
    Write-Host "  Use Item Web API for field mutations in MCP server" -ForegroundColor White
    Write-Host "  - Same authentication as used here" -ForegroundColor Gray
    Write-Host "  - RESTful API design" -ForegroundColor Gray
    Write-Host "  - Standard HTTP methods" -ForegroundColor Gray
    Write-Host ""
}
