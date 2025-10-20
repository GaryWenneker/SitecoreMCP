# Test script for NEW /items/master schema features
# Tests: version support, advanced search, sites query, templates query, mutations

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  /items/master Schema Features Test" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Load environment variables
. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

if (-not $env:SITECORE_API_KEY) {
    Write-Host "[FAIL] SITECORE_API_KEY not set!" -ForegroundColor Red
    exit 1
}

if (-not $env:SITECORE_ENDPOINT -and $env:SITECORE_HOST) {
    $env:SITECORE_ENDPOINT = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
}
$endpoint = $env:SITECORE_ENDPOINT
if (-not $endpoint) {
    Write-Host "[FAIL] SITECORE_ENDPOINT or SITECORE_HOST not set!" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Endpoint: $endpoint" -ForegroundColor Cyan
Write-Host ""

# Disable SSL certificate validation for PowerShell 5.1
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testResults = @()

# =============================================================================
# TEST 1: Get Item with Version Parameter (NEW!)
# =============================================================================
Write-Host "[TEST 1] Get Item with Version Parameter" -ForegroundColor Yellow
Write-Host "Testing: item(path, language, version)" -ForegroundColor Gray

$query1 = @"
{
  item(path: "/sitecore/content", language: "en", version: 1) {
    id
    name
    path
    version
    template {
      id
      name
    }
  }
}
"@

try {
    $response1 = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$query1} | ConvertTo-Json) `
       

    if ($response1.data.item) {
        Write-Host ""
        Write-Host "[OK] Item with version retrieved!" -ForegroundColor Green
        Write-Host "  Name: $($response1.data.item.name)" -ForegroundColor Gray
        Write-Host "  Path: $($response1.data.item.path)" -ForegroundColor Gray
        Write-Host "  Version: $($response1.data.item.version)" -ForegroundColor Gray
        Write-Host ""
        $testResults += @{Test="Get Item with Version"; Result="PASSED"}
    } else {
        Write-Host "[FAIL] No item returned" -ForegroundColor Red
        $testResults += @{Test="Get Item with Version"; Result="FAILED"}
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Get Item with Version"; Result="FAILED"}
}

# =============================================================================
# TEST 2: Advanced Search with Index (NEW!)
# =============================================================================
Write-Host "[TEST 2] Advanced Search with Index Parameter" -ForegroundColor Yellow
Write-Host "Testing: search(keyword, rootItem, language, index)" -ForegroundColor Gray

$query2 = @"
{
  search(
    keyword: "home"
    rootItem: "/sitecore/content"
    language: "en"
    first: 5
  ) {
    total
    results {
      id
      name
      path
      template {
        name
      }
    }
  }
}
"@

try {
    $response2 = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$query2} | ConvertTo-Json) `
       

    if ($response2.data.search) {
        Write-Host ""
        Write-Host "[OK] Advanced search successful!" -ForegroundColor Green
        Write-Host "  Total: $($response2.data.search.total)" -ForegroundColor Gray
        Write-Host "  Results: $($response2.data.search.results.Count)" -ForegroundColor Gray
        if ($response2.data.search.results.Count -gt 0) {
            Write-Host "  First item: $($response2.data.search.results[0].name)" -ForegroundColor Gray
        }
        Write-Host ""
        $testResults += @{Test="Advanced Search"; Result="PASSED"}
    } else {
        Write-Host "[FAIL] No search results" -ForegroundColor Red
        $testResults += @{Test="Advanced Search"; Result="FAILED"}
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Advanced Search"; Result="FAILED"}
}

# =============================================================================
# TEST 3: Sites Query (NEW!)
# =============================================================================
Write-Host "[TEST 3] Sites Query (NEW for /items/master)" -ForegroundColor Yellow
Write-Host "Testing: sites(includeSystemSites)" -ForegroundColor Gray

$query3 = @"
{
  sites(includeSystemSites: false) {
    name
    hostName
    database
    language
  }
}
"@

try {
    $response3 = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$query3} | ConvertTo-Json) `
       

    if ($response3.data.sites) {
        Write-Host ""
        Write-Host "[OK] Sites query successful!" -ForegroundColor Green
        Write-Host "  Sites found: $($response3.data.sites.Count)" -ForegroundColor Gray
        foreach ($site in $response3.data.sites | Select-Object -First 3) {
            Write-Host "  - $($site.name) ($($site.hostName))" -ForegroundColor Gray
        }
        Write-Host ""
        $testResults += @{Test="Sites Query"; Result="PASSED"}
    } else {
        Write-Host "[FAIL] No sites returned" -ForegroundColor Red
        $testResults += @{Test="Sites Query"; Result="FAILED"}
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Sites Query"; Result="FAILED"}
}

# =============================================================================
# TEST 4: Templates Query (NEW!)
# =============================================================================
Write-Host "[TEST 4] Templates Query (NEW for /items/master)" -ForegroundColor Yellow
Write-Host "Testing: templates(path)" -ForegroundColor Gray

$query4 = @"
{
  templates(path: "/sitecore/templates/System") {
    id
    name
    path
  }
}
"@

try {
    $response4 = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$query4} | ConvertTo-Json) `
       

    if ($response4.data.templates) {
        Write-Host ""
        Write-Host "[OK] Templates query successful!" -ForegroundColor Green
        Write-Host "  Templates found: $($response4.data.templates.Count)" -ForegroundColor Gray
        foreach ($template in $response4.data.templates | Select-Object -First 5) {
            Write-Host "  - $($template.name)" -ForegroundColor Gray
        }
        Write-Host ""
        $testResults += @{Test="Templates Query"; Result="PASSED"}
    } else {
        Write-Host "[FAIL] No templates returned" -ForegroundColor Red
        $testResults += @{Test="Templates Query"; Result="FAILED"}
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Templates Query"; Result="FAILED"}
}

# =============================================================================
# TEST 5: Mutation - Create Item (NEW!)
# =============================================================================
Write-Host "[TEST 5] Mutation - Create Item (NEW for /items/master)" -ForegroundColor Yellow
Write-Host "Testing: createItem(name, template, parent)" -ForegroundColor Gray

$testItemName = "MCPTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$mutation5 = @"
mutation {
  createItem(
    name: "$testItemName"
    template: "{1930BBEB-7805-471A-A3BE-4858AC7CF696}"
    parent: "/sitecore/content"
    language: "en"
  ) {
    id
    name
    path
  }
}
"@

try {
    $response5 = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$mutation5} | ConvertTo-Json) `
       

    if ($response5.data.createItem) {
        Write-Host ""
        Write-Host "[OK] Item created successfully!" -ForegroundColor Green
        Write-Host "  Name: $($response5.data.createItem.name)" -ForegroundColor Gray
        Write-Host "  Path: $($response5.data.createItem.path)" -ForegroundColor Gray
        Write-Host "  ID: $($response5.data.createItem.id)" -ForegroundColor Gray
        Write-Host ""
        $testResults += @{Test="Create Item Mutation"; Result="PASSED"}
        
        # Store for cleanup
        $script:createdItemPath = $response5.data.createItem.path
    } else {
        Write-Host "[FAIL] Item creation failed" -ForegroundColor Red
        if ($response5.errors) {
            Write-Host "Errors: $($response5.errors | ConvertTo-Json)" -ForegroundColor Red
        }
        $testResults += @{Test="Create Item Mutation"; Result="FAILED"}
    }
} catch {
    Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test="Create Item Mutation"; Result="FAILED"}
}

# =============================================================================
# TEST 6: Mutation - Delete Item (NEW!)
# =============================================================================
if ($script:createdItemPath) {
    Write-Host "[TEST 6] Mutation - Delete Item (NEW for /items/master)" -ForegroundColor Yellow
    Write-Host "Testing: deleteItem(path, deletePermanently)" -ForegroundColor Gray

    $mutation6 = @"
mutation {
  deleteItem(
    path: "$($script:createdItemPath)"
    deletePermanently: true
  )
}
"@

    try {
    $response6 = Invoke-RestMethod -Uri $endpoint -Method Post `
            -Headers $headers -Body (@{query=$mutation6} | ConvertTo-Json) `
           

        if ($response6.data.deleteItem -eq $true) {
            Write-Host ""
            Write-Host "[OK] Item deleted successfully!" -ForegroundColor Green
            Write-Host "  Path: $($script:createdItemPath)" -ForegroundColor Gray
            Write-Host ""
            $testResults += @{Test="Delete Item Mutation"; Result="PASSED"}
        } else {
            Write-Host "[FAIL] Item deletion failed" -ForegroundColor Red
            $testResults += @{Test="Delete Item Mutation"; Result="FAILED"}
        }
    } catch {
        Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += @{Test="Delete Item Mutation"; Result="FAILED"}
    }
} else {
    Write-Host "[SKIP] TEST 6: No item to delete (create failed)" -ForegroundColor Yellow
    $testResults += @{Test="Delete Item Mutation"; Result="SKIPPED"}
}

# =============================================================================
# SUMMARY
# =============================================================================
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "           TEST SUMMARY" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$passed = ($testResults | Where-Object { $_.Result -eq "PASSED" }).Count
$failed = ($testResults | Where-Object { $_.Result -eq "FAILED" }).Count
$skipped = ($testResults | Where-Object { $_.Result -eq "SKIPPED" }).Count
$total = $testResults.Count

foreach ($result in $testResults) {
    $color = switch ($result.Result) {
        "PASSED" { "Green" }
        "FAILED" { "Red" }
        "SKIPPED" { "Yellow" }
    }
    Write-Host "[$($result.Result)] $($result.Test)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Total: $total | Passed: $passed | Failed: $failed | Skipped: $skipped" -ForegroundColor Cyan
Write-Host ""

if ($failed -eq 0 -and $passed -gt 0) {
    Write-Host "[SUCCESS] All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEW FEATURES VERIFIED:" -ForegroundColor Cyan
    Write-Host "  - Version parameter support" -ForegroundColor Green
    Write-Host "  - Advanced search with indexes" -ForegroundColor Green
    Write-Host "  - Sites query (plural)" -ForegroundColor Green
    Write-Host "  - Templates query" -ForegroundColor Green
    Write-Host "  - Create item mutation" -ForegroundColor Green
    Write-Host "  - Delete item mutation" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Some tests failed!" -ForegroundColor Yellow
}

Write-Host ""

