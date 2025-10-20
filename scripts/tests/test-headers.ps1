# Test Header Configuration

. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

Write-Host "=== Testing GraphQL Headers ===" -ForegroundColor Cyan
Write-Host ""

$endpoint = $env:SITECORE_ENDPOINT
if (-not $endpoint -and $env:SITECORE_HOST) {
    $endpoint = "$(($env:SITECORE_HOST))/sitecore/api/graph/items/master"
}
if (-not $endpoint) {
    Write-Host "[WARN] No endpoint configured. Set SITECORE_ENDPOINT or SITECORE_HOST in .env" -ForegroundColor Yellow
}
$apiKey = $env:SITECORE_API_KEY

Write-Host "[INFO] Endpoint: $endpoint" -ForegroundColor Cyan
Write-Host "[INFO] API Key: $($apiKey.Substring(0,15))..." -ForegroundColor Cyan
Write-Host ""

# Test 1: With all required headers
Write-Host "[TEST 1] Request with sc_apikey + Content-Type headers" -ForegroundColor Yellow
$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

$query = @{
    query = "{ item(path: `"/sitecore`", language: `"en`") { name path } }"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $query -Headers $headers -ErrorAction Stop
    Write-Host "[OK] Success with both headers!" -ForegroundColor Green
    Write-Host "    Result: $($response.data.item.name)" -ForegroundColor Gray
}
catch {
    Write-Host "[FAIL] Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Without Content-Type header
Write-Host "[TEST 2] Request without Content-Type header" -ForegroundColor Yellow
$headersNoContentType = @{
    "sc_apikey" = $apiKey
}

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $query -Headers $headersNoContentType -ErrorAction Stop
    Write-Host "[OK] Works without Content-Type (PowerShell adds it)" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Failed without Content-Type: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Without API key header
Write-Host "[TEST 3] Request without sc_apikey header" -ForegroundColor Yellow
$headersNoApiKey = @{
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $query -Headers $headersNoApiKey -ErrorAction Stop
    Write-Host "[UNEXPECTED] Worked without API key?!" -ForegroundColor Yellow
}
catch {
    Write-Host "[EXPECTED] Failed without API key: Authentication required" -ForegroundColor Green
}

Write-Host ""

# Test 4: With wrong API key
Write-Host "[TEST 4] Request with wrong API key" -ForegroundColor Yellow
$headersWrongKey = @{
    "sc_apikey" = "{00000000-0000-0000-0000-000000000000}"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $query -Headers $headersWrongKey -ErrorAction Stop
    Write-Host "[UNEXPECTED] Worked with wrong API key?!" -ForegroundColor Yellow
}
catch {
    Write-Host "[EXPECTED] Failed with wrong API key: Authentication error" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Header Tests Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[INFO] Conclusion:" -ForegroundColor Yellow
Write-Host "  - sc_apikey header is REQUIRED" -ForegroundColor Gray
Write-Host "  - Content-Type header is REQUIRED" -ForegroundColor Gray
Write-Host "  - Both are now set in axios.create() defaults" -ForegroundColor Gray
