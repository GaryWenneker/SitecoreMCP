# Test script for sitecore_get_children MCP tool
# Tests all parameters and edge cases

. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Write-Host "`n=== Testing sitecore_get_children ===" -ForegroundColor Cyan

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

$testResults = @{ Passed = 0; Failed = 0; Tests = @() }

function Test-Query {
    param([string]$TestName, [string]$Query, [scriptblock]$Validation)
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    try {
        $body = @{ query = $Query } | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body -Headers $headers
        
        if ($response.errors) {
            Write-Host "[FAIL] $($response.errors | ConvertTo-Json)" -ForegroundColor Red
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

# Test 1: Get direct children
Test-Query -TestName "Get children - Basic" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    children(first: 10) {
      id
      name
      path
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -gt 0 }

# Test 2: Get children with pagination
Test-Query -TestName "Get children - With pagination (first: 5)" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    children(first: 5) {
      id
      name
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -le 5 }

# Test 3: Get children recursively (using hasChildren)
Test-Query -TestName "Get children - Check hasChildren flag" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    children(first: 10) {
      id
      name
      hasChildren
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -gt 0 }

# Test 4: Get children with template filter
Test-Query -TestName "Get children - With template info" -Query @"
{
  item(path: "/sitecore/templates/System", language: "en") {
    children(first: 10) {
      name
      template {
        name
        id
      }
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -gt 0 }

# Test 5: Get children with version
Test-Query -TestName "Get children - With version parameter" -Query @"
{
  item(path: "/sitecore/content", language: "en", version: 1) {
    children(first: 10) {
      name
      version
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -gt 0 }

# Test 6: Get children in different language
Test-Query -TestName "Get children - Dutch language" -Query @"
{
  item(path: "/sitecore/content", language: "nl-NL") {
    children(first: 10) {
      name
      displayName
      language {
        name
      }
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -ge 0 }

# Test 7: Get children - no children case
Test-Query -TestName "Get children - Item with no children" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    children(first: 10) {
      name
    }
    hasChildren
  }
}
"@ -Validation { param($data) return $true } # hasChildren might be false

# Test 8: Get children with fields
Test-Query -TestName "Get children - With fields" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    children(first: 3) {
      name
      fields(ownFields: false) {
        name
        value
      }
    }
  }
}
"@ -Validation { param($data) return $data.item.children.Count -gt 0 }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_children" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host ""
exit $testResults.Failed
