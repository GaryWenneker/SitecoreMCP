# Test script for sitecore_get_item MCP tool
# Tests all parameters and edge cases

# Load environment variables
. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Write-Host "`n=== Testing sitecore_get_item ===" -ForegroundColor Cyan
Write-Host "Testing all parameters and scenarios..." -ForegroundColor Yellow
Write-Host ""

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testResults = @{
    Passed = 0
    Failed = 0
    Tests = @()
}

function Test-GraphQLQuery {
    param(
        [string]$TestName,
        [string]$Query,
        [scriptblock]$Validation
    )
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    
    try {
        $body = @{ query = $Query } | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body -Headers $headers -ErrorAction Stop
        
        if ($response.errors) {
            Write-Host "[FAIL] GraphQL errors: $($response.errors | ConvertTo-Json)" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests += @{ Name = $TestName; Status = "FAIL"; Error = $response.errors }
            return $false
        }
        
        $validationResult = & $Validation $response.data
        
        if ($validationResult) {
            Write-Host "[PASS] $TestName" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests += @{ Name = $TestName; Status = "PASS" }
            return $true
        } else {
            Write-Host "[FAIL] Validation failed" -ForegroundColor Red
            Write-Host "  Response: $($response.data | ConvertTo-Json -Depth 3 -Compress)" -ForegroundColor Gray
            $testResults.Failed++
            $testResults.Tests += @{ Name = $TestName; Status = "FAIL"; Error = "Validation failed" }
            return $false
        }
    }
    catch {
        Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests += @{ Name = $TestName; Status = "FAIL"; Error = $_.Exception.Message }
        return $false
    }
}

# Test 1: Basic item retrieval (en language)
Test-GraphQLQuery -TestName "Get item - Basic (en)" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    id
    name
    path
    displayName
    template {
      id
      name
    }
    hasChildren
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.name -eq "content"
}

# Test 2: Get item with Dutch language (may return null if language doesn't exist)
Test-GraphQLQuery -TestName "Get item - Dutch language (nl-NL)" -Query @"
{
  item(path: "/sitecore/content", language: "nl-NL") {
    id
    name
    displayName
    language {
      name
    }
  }
}
"@ -Validation {
    param($data)
    # Test passes if query executes (item may be null if language doesn't exist)
    return $true
}

# Test 3: Get item with version parameter
Test-GraphQLQuery -TestName "Get item - With version" -Query @"
{
  item(path: "/sitecore/content", language: "en", version: 1) {
    id
    name
    version
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.version -ge 1
}

# Test 4: Get item by ID (GUID format)
$contentId = "{0DE95AE4-41AB-4D01-9EB0-67441B7C2450}" # /sitecore/content
Test-GraphQLQuery -TestName "Get item - By GUID" -Query @"
{
  item(path: "$contentId", language: "en") {
    id
    name
    path
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.path -eq "/sitecore/content"
}

# Test 5: Get template item
Test-GraphQLQuery -TestName "Get item - Template item" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    id
    name
    template {
      name
    }
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.name -eq "Template"
}

# Test 6: Get item with all fields
Test-GraphQLQuery -TestName "Get item - With fields" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    id
    name
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.fields.Count -gt 0
}

# Test 7: Get item with parent
Test-GraphQLQuery -TestName "Get item - With parent" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    id
    name
    parent {
      name
      path
    }
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.parent.name -eq "content"
}

# Test 8: Get item with children
Test-GraphQLQuery -TestName "Get item - With children" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    id
    name
    hasChildren
    children(first: 5) {
      id
      name
    }
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.hasChildren
}

# Test 9: Non-existent item (should return null)
Test-GraphQLQuery -TestName "Get item - Non-existent path" -Query @"
{
  item(path: "/sitecore/content/DoesNotExist12345", language: "en") {
    id
    name
  }
}
"@ -Validation {
    param($data)
    return $data.item -eq $null
}

# Test 10: Get item with URL
Test-GraphQLQuery -TestName "Get item - With URL" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    id
    name
    url
  }
}
"@ -Validation {
    param($data)
    return $data.item -and $data.item.url
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Results: sitecore_get_item" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($testResults.Passed + $testResults.Failed)" -ForegroundColor Yellow
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""

if ($testResults.Failed -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    $testResults.Tests | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Error)" -ForegroundColor Red
    }
}

Write-Host ""
exit $testResults.Failed
