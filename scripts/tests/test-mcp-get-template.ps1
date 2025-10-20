# Test script for sitecore_get_template MCP tool
# Tests template retrieval and field definitions

. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Write-Host "`n=== Testing sitecore_get_template ===" -ForegroundColor Cyan

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testResults = @{ Passed = 0; Failed = 0 }

function Test-Template {
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

# Test 1: Get template basic info
Test-Template -TestName "Get template - Basic info" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    id
    name
    path
    template {
      name
    }
  }
}
"@ -Validation { param($data) return $data.item.name -eq "Template" }

# Test 2: Get template with base templates
Test-Template -TestName "Get template - With base templates" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    baseTemplates: field(name: "__Base template") {
      value
    }
  }
}
"@ -Validation { param($data) return $data.item }

# Test 3: Get template with sections
Test-Template -TestName "Get template - With children (sections)" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    children(first: 20) {
      name
      template {
        name
      }
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -gt 0 }

# Test 4: Get template field definitions
Test-Template -TestName "Get template - Field definitions" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    fields(ownFields: true) {
      name
      value
    }
  }
}
"@ -Validation { param($data) return $data.item.fields.Count -ge 0 }

# Test 5: Get template by ID
$templateId = "{AB86861A-6030-46C5-B394-E8F99E8B87DB}" # Template template
Test-Template -TestName "Get template - By GUID" -Query @"
{
  item(path: "$templateId", language: "en") {
    id
    name
    path
  }
}
"@ -Validation { param($data) return $data.item.path -like "*/Template" }

# Test 6: Get custom template (if exists)
Test-Template -TestName "Get template - From templates folder" -Query @"
{
  item(path: "/sitecore/templates", language: "en") {
    children(first: 10) {
      name
      template {
        name
      }
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -gt 0 }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_template" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""
exit $testResults.Failed
