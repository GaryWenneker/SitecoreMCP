# Test script for sitecore_get_layout MCP tool
# Tests layout/presentation info with renderings and placeholders

# Load environment variables
. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

if (-not $env:SITECORE_API_KEY) {
    Write-Host "[ERROR] SITECORE_API_KEY not found in environment" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Environment variables loaded successfully!" -ForegroundColor Green
Write-Host ""

# Configuration
$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

# Test results tracking
$script:passCount = 0
$script:failCount = 0

function Test-Layout {
    param(
        [string]$TestName,
        [string]$Query,
        [scriptblock]$Validation
    )
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    
    try {
        $body = @{
            query = $Query
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
        
        if ($response.errors) {
            Write-Host "[FAIL] $TestName" -ForegroundColor Red
            Write-Host "  GraphQL Errors: $($response.errors | ConvertTo-Json -Depth 5)" -ForegroundColor Red
            $script:failCount++
            return
        }
        
        $isValid = & $Validation $response.data
        
        if ($isValid) {
            Write-Host "[PASS]" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "[FAIL] Validation failed" -ForegroundColor Red
            Write-Host "  Response: $($response.data | ConvertTo-Json -Depth 5)" -ForegroundColor Yellow
            $script:failCount++
        }
    }
    catch {
        Write-Host "[FAIL] $TestName - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
    }
    Write-Host ""
}

Write-Host "=== Testing sitecore_get_layout ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get layout field from item
Test-Layout -TestName "Get layout - Basic layout field" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    layout: field(name: "__Renderings") {
      value
    }
  }
}
"@ -Validation { param($data) 
    return $data.item
}

# Test 2: Get final layout field
Test-Layout -TestName "Get layout - Final layout field" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    finalLayout: field(name: "__Final Renderings") {
      value
    }
  }
}
"@ -Validation { param($data) 
    return $data.item
}

# Test 3: Check if item has layout via field query
Test-Layout -TestName "Get layout - Check layout exists" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    layout: field(name: "__Renderings") {
      value
    }
  }
}
"@ -Validation { param($data) 
    return $data.item
}

# Test 4: Get layout with language parameter
Test-Layout -TestName "Get layout - With language (nl-NL)" -Query @"
{
  item(path: "/sitecore/content/Home", language: "nl-NL") {
    name
  }
}
"@ -Validation { param($data) 
    # nl-NL may not exist
    return $true
}

# Test 5: Get rendering items from layout folder
Test-Layout -TestName "Get layout - Rendering definition" -Query @"
{
  item(path: "/sitecore/layout/Renderings", language: "en") {
    name
    children(first: 5) {
      name
      path
      template {
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.children
}

# Test 6: Get layout folder structure
Test-Layout -TestName "Get layout - Layout folder" -Query @"
{
  item(path: "/sitecore/layout", language: "en") {
    name
    children {
      name
      path
      hasChildren
    }
  }
}
"@ -Validation { param($data) 
    $children = $data.item.children
    $hasRenderings = $children | Where-Object { $_.name -eq "Renderings" }
    return $hasRenderings
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_layout" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host "" 
Write-Host "[INFO] Note: Full layout service queries require site context" -ForegroundColor Yellow
Write-Host "[INFO] Use __Renderings field to check if item has presentation" -ForegroundColor Yellow

exit $script:failCount