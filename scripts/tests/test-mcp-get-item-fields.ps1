# Test script for sitecore_get_item_fields MCP tool
# Tests field retrieval with all options

. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Write-Host "`n=== Testing sitecore_get_item_fields ===" -ForegroundColor Cyan

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testResults = @{ Passed = 0; Failed = 0 }

function Test-Fields {
    param([string]$TestName, [string]$Query, [scriptblock]$Validation)
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    try {
        $body = @{ query = $Query } | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body -Headers $headers
        
        if ($response.errors) {
            Write-Host "[FAIL] $($response.errors[0].message)" -ForegroundColor Red
            $testResults.Failed++
            return $false
        }
        
        if (& $Validation $response.data) {
            Write-Host "[PASS]" -ForegroundColor Green
            $testResults.Passed++
            return $true
        }
        Write-Host "[FAIL] Validation failed" -ForegroundColor Red
        $testResults.Failed++
        return $false
    }
    catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $testResults.Failed++
        return $false
    }
}

# Test 1: Get all fields (including inherited)
Test-Fields -TestName "Get fields - All fields (ownFields: false)" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.fields.Count -gt 10 }

# Test 2: Get only own fields
Test-Fields -TestName "Get fields - Own fields only (ownFields: true)" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    fields(ownFields: true) {
      name
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.fields.Count -ge 0 }

# Test 3: Get specific field by name
Test-Fields -TestName "Get field - Specific field (__Created)" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    created: field(name: "__Created") {
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.created }

# Test 4: Get multiple standard fields
Test-Fields -TestName "Get fields - Standard system fields" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    created: field(name: "__Created") {
      value
    }
    updated: field(name: "__Updated") {
      value
    }
    owner: field(name: "__Owner") {
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.created -and $data.item.updated }

# Test 5: Get fields with version
Test-Fields -TestName "Get fields - With version parameter" -Query @"
{
  item(path: "/sitecore/content", language: "en", version: 1) {
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.fields.Count -gt 0 }

# Test 6: Get fields in different language
Test-Fields -TestName "Get fields - Dutch language (nl-NL)" -Query @"
{
  item(path: "/sitecore/content", language: "nl-NL") {
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.fields.Count -ge 0 }

# Test 7: Get template fields
Test-Fields -TestName "Get fields - Template item fields" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.fields.Count -gt 0 }

# Test 8: Count total fields
Test-Fields -TestName "Get fields - Verify field count >20" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    allFields: fields(ownFields: false) {
      name
    }
  }
}
"@ -Validation { 
    param($data) 
    Write-Host "  Total fields found: $($data.item.allFields.Count)" -ForegroundColor Gray
    return $data.item.allFields.Count -gt 20 
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_item_fields" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""
exit $testResults.Failed
