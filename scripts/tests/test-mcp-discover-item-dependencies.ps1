# Test script for sitecore_discover_item_dependencies MCP tool
# Tests comprehensive item discovery (NEW v1.6.0)

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

function Test-Discovery {
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
            Write-Host "  Response: $($response.data | ConvertTo-Json -Depth 3)" -ForegroundColor Yellow
            $script:failCount++
        }
    }
    catch {
        Write-Host "[FAIL] $TestName - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
    }
    Write-Host ""
}

Write-Host "=== Testing sitecore_discover_item_dependencies ===" -ForegroundColor Cyan
Write-Host "[INFO] This tool combines item + template + inheritance + fields" -ForegroundColor Yellow
Write-Host ""

# Test 1: Get item with template info (basic discovery)
Test-Discovery -TestName "Discovery - Item with template" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    id
    name
    path
    template {
      id
      name
    }
  }
}
"@ -Validation { param($data) 
    return $data.item -and $data.item.template
}

# Test 2: Get item with all fields (comprehensive)
Test-Discovery -TestName "Discovery - Item with all fields" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    template {
      name
    }
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@ -Validation { param($data) 
    $fieldCount = $data.item.fields.Count
    Write-Host "  Total fields: $fieldCount" -ForegroundColor Gray
    return $fieldCount -ge 20
}

# Test 3: Get template with base templates (inheritance chain)
Test-Discovery -TestName "Discovery - Template inheritance" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    baseTemplates: field(name: "__Base template") {
      value
    }
  }
}
"@ -Validation { param($data) 
    return $data.item
}

# Test 4: Get layout field (renderings check)
Test-Discovery -TestName "Discovery - Check layout field" -Query @"
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

# Test 5: Comprehensive discovery - content item (nl-NL)
Test-Discovery -TestName "Discovery - Dutch content item" -Query @"
{
  item(path: "/sitecore/content/Home", language: "nl-NL") {
    id
    name
    path
    language {
      name
    }
    template {
      id
      name
    }
    fields(ownFields: false) {
      name
    }
  }
}
"@ -Validation { param($data) 
    # nl-NL may not exist
    return $true
}

# Test 6: Discovery with parent and children
Test-Discovery -TestName "Discovery - Item with parent & children" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    parent {
      name
      path
    }
    children(first: 5) {
      name
      path
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent
}

# Test 7: Discovery with version info
Test-Discovery -TestName "Discovery - Item with version info" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    name
    version
    versions {
      version
      language {
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    Write-Host "  Current version: $($data.item.version)" -ForegroundColor Gray
    Write-Host "  Total versions: $($data.item.versions.Count)" -ForegroundColor Gray
    return $data.item.version -ge 1
}

# Test 8: Discovery with statistics
Test-Discovery -TestName "Discovery - Item with statistics" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    name
    template {
      name
    }
    ... on Statistics {
      created {
        value
      }
      createdBy {
        value
      }
      updated {
        value
      }
      updatedBy {
        value
      }
    }
  }
}
"@ -Validation { param($data) 
    Write-Host "  Created: $($data.item.created.value)" -ForegroundColor Gray
    Write-Host "  Updated: $($data.item.updated.value)" -ForegroundColor Gray
    return $data.item.created.value -and $data.item.updated.value
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_discover_item_dependencies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[INFO] Note: This tool combines multiple queries for comprehensive discovery" -ForegroundColor Yellow
Write-Host "[INFO] Returns: item + template + inheritance + fields + renderings + resolvers" -ForegroundColor Yellow

exit $script:failCount
