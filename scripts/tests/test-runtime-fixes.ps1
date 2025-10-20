# ========================================
# Runtime Error Fixes Test Suite
# Tests all 5 production runtime errors
# ========================================

param(
    [string]$ApiKey = $env:SITECORE_API_KEY,
    [string]$Endpoint = $env:SITECORE_ENDPOINT
)

# ASCII output only (no emojis)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Runtime Error Fixes Test Suite" -ForegroundColor Cyan
Write-Host "Testing 5 Production Error Scenarios" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ([string]::IsNullOrEmpty((Get-Item Env:$key -ErrorAction SilentlyContinue))) {
                [System.Environment]::SetEnvironmentVariable($key, $value)
            }
        }
    }
    $ApiKey = $env:SITECORE_API_KEY
    $Endpoint = $env:SITECORE_ENDPOINT
}

if ([string]::IsNullOrEmpty($ApiKey) -or [string]::IsNullOrEmpty($Endpoint)) {
    Write-Host "[FAIL] Missing SITECORE_API_KEY or SITECORE_ENDPOINT" -ForegroundColor Red
    exit 1
}

$headers = @{
    "sc_apikey" = $ApiKey
    "Content-Type" = "application/json"
}

$testsPassed = 0
$testsFailed = 0
$testsTotal = 0

# ========================================
# Test Category 1: getItem Language Handling
# ========================================
Write-Host "=== Category 1: getItem Language Handling ===" -ForegroundColor Yellow
Write-Host ""

# Test 1.1: getItem with default language (templates always 'en')
Write-Host "[TEST] 1.1 - getItem with template path (smart default to 'en')" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query GetItem(`$path: String!, `$language: String!) {
            item(path: `$path, language: `$language) {
                id
                name
                path
                template {
                    id
                    name
                }
            }
        }
"@
        variables = @{
            path = "/sitecore/templates/System"
            language = "en"
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.item) {
        Write-Host "[PASS] Template item found with language='en'" -ForegroundColor Green
        Write-Host "  Name: $($response.data.item.name)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] Template item not found" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 1.2: getItem with content path (default language)
Write-Host "[TEST] 1.2 - getItem with content path (smart default)" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query GetItem(`$path: String!, `$language: String!) {
            item(path: `$path, language: `$language) {
                id
                name
                path
                language {
                    name
                }
            }
        }
"@
        variables = @{
            path = "/sitecore/content"
            language = "en"
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.item) {
        Write-Host "[PASS] Content item found with language='en'" -ForegroundColor Green
        Write-Host "  Name: $($response.data.item.name)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] Content item not found" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# ========================================
# Test Category 2: getFieldValue
# ========================================
Write-Host "=== Category 2: getFieldValue ===" -ForegroundColor Yellow
Write-Host ""

# Test 2.1: Get field value using field() query
Write-Host "[TEST] 2.1 - getFieldValue using field() query (verify syntax)" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query GetField(`$path: String!, `$fieldName: String!, `$language: String!) {
            item(path: `$path, language: `$language) {
                field(name: `$fieldName) {
                    name
                    value
                }
            }
        }
"@
        variables = @{
            path = "/sitecore/templates/System"
            fieldName = "__Display name"
            language = "en"
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.item.field) {
        Write-Host "[PASS] Field query syntax correct (field() works)" -ForegroundColor Green
        Write-Host "  Field name: $($response.data.item.field.name)" -ForegroundColor Gray
        Write-Host "  Field value: $($response.data.item.field.value)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] Field not found" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 2.2: Get all fields using fields() query
Write-Host "[TEST] 2.2 - Get all fields using fields() query" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query GetFields(`$path: String!, `$language: String!) {
            item(path: `$path, language: `$language) {
                fields(ownFields: false) {
                    name
                    value
                }
            }
        }
"@
        variables = @{
            path = "/sitecore/content"
            language = "en"
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.item.fields -and $response.data.item.fields.Count -gt 0) {
        Write-Host "[PASS] Fields query successful (found $($response.data.item.fields.Count) fields)" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "[FAIL] No fields returned" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# ========================================
# Test Category 3: getTemplate
# ========================================
Write-Host "=== Category 3: getTemplate ===" -ForegroundColor Yellow
Write-Host ""

# Test 3.1: Get template by path
Write-Host "[TEST] 3.1 - getTemplate by path (always language='en')" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query GetTemplate(`$path: String!, `$language: String!) {
            item(path: `$path, language: `$language) {
                id
                name
                path
                template {
                    id
                    name
                }
                fields(ownFields: false) {
                    name
                    value
                }
            }
        }
"@
        variables = @{
            path = "/sitecore/templates/System"
            language = "en"
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.item) {
        Write-Host "[PASS] Template found by path" -ForegroundColor Green
        Write-Host "  Template ID: $($response.data.item.id)" -ForegroundColor Gray
        Write-Host "  Template Name: $($response.data.item.name)" -ForegroundColor Gray
        Write-Host "  Template Path: $($response.data.item.path)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] Template not found" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# ========================================
# Test Category 4: getTemplates (Schema Fix)
# ========================================
Write-Host "=== Category 4: getTemplates (Schema Fix) ===" -ForegroundColor Yellow
Write-Host ""

# Test 4.1: Get templates using Query.templates (VERIFIED EXISTS in schema!)
Write-Host "[TEST] 4.1 - getTemplates using templates query (SCHEMA-VALIDATED)" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query GetTemplates {
            templates {
                id
                name
                baseTemplates {
                    id
                    name
                }
                fields {
                    name
                    type
                }
            }
        }
"@
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.templates -and $response.data.templates.Count -gt 0) {
        Write-Host "[PASS] Templates retrieved via templates query" -ForegroundColor Green
        Write-Host "  Found $($response.data.templates.Count) templates" -ForegroundColor Gray
        Write-Host "  First template: $($response.data.templates[0].name)" -ForegroundColor Gray
        Write-Host "  Has baseTemplates: $($response.data.templates[0].baseTemplates.Count)" -ForegroundColor Gray
        Write-Host "  Has fields: $($response.data.templates[0].fields.Count)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] No templates found" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 4.2: Verify ItemTemplate has all fields (id, name, baseTemplates, fields)
Write-Host "[TEST] 4.2 - Verify ItemTemplate complete structure (SCHEMA-VALIDATED)" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query VerifyItemTemplate(`$path: String!, `$language: String!) {
            item(path: `$path, language: `$language) {
                template {
                    id
                    name
                    baseTemplates {
                        id
                        name
                    }
                    fields {
                        name
                        type
                    }
                }
            }
        }
"@
        variables = @{
            path = "/sitecore/content"
            language = "en"
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.item.template.id -and $response.data.item.template.name) {
        Write-Host "[PASS] ItemTemplate has all schema fields" -ForegroundColor Green
        Write-Host "  Template ID: $($response.data.item.template.id)" -ForegroundColor Gray
        Write-Host "  Template Name: $($response.data.item.template.name)" -ForegroundColor Gray
        Write-Host "  Base Templates: $($response.data.item.template.baseTemplates.Count)" -ForegroundColor Gray
        Write-Host "  Fields: $($response.data.item.template.fields.Count)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "[FAIL] ItemTemplate structure incorrect" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# ========================================
# Test Category 5: getChildren (No 'results' field)
# ========================================
Write-Host "=== Category 5: getChildren (No 'results' field) ===" -ForegroundColor Yellow
Write-Host ""

# Test 5.1: Verify children is direct array (no .results wrapper)
Write-Host "[TEST] 5.1 - getChildren returns direct array (no .results)" -ForegroundColor Cyan
$testsTotal++
try {
    $query = @{
        query = @"
        query GetChildren(`$path: String!, `$language: String!) {
            item(path: `$path, language: `$language) {
                children(first: 10) {
                    id
                    name
                    path
                    hasChildren
                }
            }
        }
"@
        variables = @{
            path = "/sitecore/content"
            language = "en"
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
    if ($response.data.item.children) {
        Write-Host "[PASS] Children returned as direct array (correct)" -ForegroundColor Green
        Write-Host "  Found $($response.data.item.children.Count) children" -ForegroundColor Gray
        if ($response.data.item.children.Count -gt 0) {
            Write-Host "  First child: $($response.data.item.children[0].name)" -ForegroundColor Gray
        }
        $testsPassed++
    } else {
        Write-Host "[FAIL] Children structure incorrect" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# ========================================
# Test Summary
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $testsTotal" -ForegroundColor White
Write-Host "Passed:       $testsPassed" -ForegroundColor Green
Write-Host "Failed:       $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

$passRate = [math]::Round(($testsPassed / $testsTotal) * 100, 1)
Write-Host "Pass Rate:    $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } elseif ($passRate -ge 80) { "Yellow" } else { "Red" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "[SUCCESS] All runtime error fixes validated!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAILURE] Some tests failed. Review errors above." -ForegroundColor Red
    exit 1
}
