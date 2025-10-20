# Test All Schema Return Types
# Validates that all queries use correct access patterns

. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Schema Return Types Validation" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
$endpoint = $env:SITECORE_ENDPOINT
if (-not $endpoint -and $env:SITECORE_HOST) { $endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master" }
Write-Host "Endpoint: $endpoint" -ForegroundColor Yellow
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Test 1: item() - Returns Item (direct object)
Write-Host "[TEST 1] item() - Direct Item object" -ForegroundColor Cyan
try {
    $query = 'query { item(path: "/sitecore/content", language: "en") { id name path } }'
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri "$endpoint" -Method Post -Body $body -ContentType "application/json" -Headers @{ "sc_apikey" = $env:SITECORE_API_KEY }
    
    if ($response.data.item -and $response.data.item.id) {
        Write-Host "[PASS] item() returns direct object" -ForegroundColor Green
        Write-Host "       Access: result.item.id = $($response.data.item.id)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] item() should return direct object" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] item() query failed: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 2: item().children() - Returns [Item] (direct array, NO results)
Write-Host "[TEST 2] item().children() - Direct array (NO results)" -ForegroundColor Cyan
try {
    $query = 'query { item(path: "/sitecore/content", language: "en") { children(first: 5) { id name } } }'
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri "$endpoint" -Method Post -Body $body -ContentType "application/json" -Headers @{ "sc_apikey" = $env:SITECORE_API_KEY }
    
    if ($response.data.item.children -is [Array]) {
        Write-Host "[PASS] children() returns direct array (NO results wrapper)" -ForegroundColor Green
        Write-Host "       Access: result.item.children[0].name = $($response.data.item.children[0].name)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] children() should return direct array" -ForegroundColor Red
        $testsFailed++
    }
    
    # Verify .results doesn't exist
    if ($null -eq $response.data.item.children.results) {
        Write-Host "[PASS] Confirmed: children.results does NOT exist" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "[FAIL] Unexpected: children.results exists (should not!)" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] children() query failed: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 3: item().field() - Returns String (direct value)
Write-Host "[TEST 3] item().field() - Direct string value" -ForegroundColor Cyan
try {
    $query = 'query { item(path: "/sitecore/content/Home", language: "en") { field(name: "Title") } }'
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri "$endpoint" -Method Post -Body $body -ContentType "application/json" -Headers @{ "sc_apikey" = $env:SITECORE_API_KEY }
    
    if ($response.data.item.field -is [String] -or $null -eq $response.data.item.field) {
        Write-Host "[PASS] field() returns direct string value" -ForegroundColor Green
        Write-Host "       Access: result.item.field = '$($response.data.item.field)'" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] field() should return direct string" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] field() query failed: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 4: item().fields() - Returns [ItemField] (array)
Write-Host "[TEST 4] item().fields() - Array of ItemField objects" -ForegroundColor Cyan
try {
    $query = 'query { item(path: "/sitecore/content/Home", language: "en") { fields(ownFields: false) { name value } } }'
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri "$endpoint" -Method Post -Body $body -ContentType "application/json" -Headers @{ "sc_apikey" = $env:SITECORE_API_KEY }
    
    if ($response.data.item.fields -is [Array]) {
        Write-Host "[PASS] fields() returns array of objects" -ForegroundColor Green
        Write-Host "       Access: result.item.fields[0].name = '$($response.data.item.fields[0].name)'" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] fields() should return array" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] fields() query failed: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 5: search() - Returns ItemSearchResults (with .results!)
Write-Host "[TEST 5] search() - ItemSearchResults with .results wrapper" -ForegroundColor Cyan
try {
    $query = 'query { search(where: { name: "_path", value: "/sitecore/content", operator: CONTAINS }, first: 5) { results { id name } total } }'
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri "$endpoint" -Method Post -Body $body -ContentType "application/json" -Headers @{ "sc_apikey" = $env:SITECORE_API_KEY }
    
    if ($response.data.search.results -is [Array]) {
        Write-Host "[PASS] search() has .results wrapper" -ForegroundColor Green
        Write-Host "       Access: result.search.results[0].name = '$($response.data.search.results[0].name)'" -ForegroundColor Gray
        Write-Host "       Total: $($response.data.search.total)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] search() should have .results wrapper" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] search() query failed: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 6: item().template - Returns Template (direct object)
Write-Host "[TEST 6] item().template - Direct Template object" -ForegroundColor Cyan
try {
    $query = 'query { item(path: "/sitecore/content/Home", language: "en") { template { id name } } }'
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri "$env:SITECORE_ENDPOINT" -Method Post -Body $body -ContentType "application/json" -Headers @{ "sc_apikey" = $env:SITECORE_API_KEY }
    
    if ($response.data.item.template.id) {
        Write-Host "[PASS] template returns direct object" -ForegroundColor Green
        Write-Host "       Access: result.item.template.name = '$($response.data.item.template.name)'" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] template should return direct object" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] template query failed: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 7: Verify endpoint is /items/master
Write-Host "[TEST 7] Endpoint validation - Must be /items/master" -ForegroundColor Cyan
if ($env:SITECORE_ENDPOINT -match "/items/master") {
    Write-Host "[PASS] Using correct endpoint: /items/master" -ForegroundColor Green
    Write-Host "       Endpoint: $endpoint" -ForegroundColor Gray
    $testsPassed++
} elseif ($env:SITECORE_ENDPOINT -match "/edge") {
    Write-Host "[FAIL] Using WRONG endpoint: /edge (REMOVED!)" -ForegroundColor Red
    Write-Host "       Update your .env to use /items/master" -ForegroundColor Yellow
    $testsFailed++
} else {
    Write-Host "[WARN] Unknown endpoint: $env:SITECORE_ENDPOINT" -ForegroundColor Yellow
    Write-Host "       Expected: /items/master or /items/web" -ForegroundColor Yellow
}
Write-Host ""

# Test 8: Verify children(first: N) argument works
Write-Host "[TEST 8] children pagination - first argument" -ForegroundColor Cyan
try {
    $query = 'query { item(path: "/sitecore/content", language: "en") { children(first: 2) { id name } } }'
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri "$endpoint" -Method Post -Body $body -ContentType "application/json" -Headers @{ "sc_apikey" = $env:SITECORE_API_KEY }
    
    $childCount = $response.data.item.children.Count
    if ($childCount -le 2) {
        Write-Host "[PASS] children(first: 2) respects limit" -ForegroundColor Green
        Write-Host "       Returned: $childCount items" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] children(first: 2) returned $childCount items (expected <= 2)" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] children(first:) query failed: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Test Results Summary" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tests Passed: " -NoNewline -ForegroundColor Green
Write-Host "$testsPassed" -ForegroundColor White
Write-Host "Tests Failed: " -NoNewline -ForegroundColor Red
Write-Host "$testsFailed" -ForegroundColor White
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "[OK] ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Schema validation complete. All return types are correct:" -ForegroundColor Gray
    Write-Host "  - item() returns direct object" -ForegroundColor Gray
    Write-Host "  - item().children() returns direct array (NO .results)" -ForegroundColor Gray
    Write-Host "  - item().field() returns direct string" -ForegroundColor Gray
    Write-Host "  - item().fields() returns array" -ForegroundColor Gray
    Write-Host "  - search() returns object with .results array" -ForegroundColor Gray
    Write-Host "  - item().template returns direct object" -ForegroundColor Gray
    Write-Host "  - Endpoint is /items/master" -ForegroundColor Gray
    Write-Host "  - children(first: N) pagination works" -ForegroundColor Gray
} else {
    Write-Host "[FAIL] Some tests failed. Check output above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Using /edge endpoint (should be /items/master)" -ForegroundColor Yellow
    Write-Host "  - Trying to access .results on children (doesn't exist)" -ForegroundColor Yellow
    Write-Host "  - Wrong field/fields usage (singular vs plural)" -ForegroundColor Yellow
    exit 1
}
Write-Host ""
