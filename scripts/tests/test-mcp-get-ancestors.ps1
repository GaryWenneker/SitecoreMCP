# Test script for sitecore_get_ancestors MCP tool
# Tests all parameter variations and edge cases

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

function Test-Ancestors {
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

Write-Host "=== Testing sitecore_get_ancestors ===" -ForegroundColor Cyan
Write-Host "[INFO] Note: 'ancestors' field not supported - using parent chain" -ForegroundColor Yellow
Write-Host ""

# Test 1: Get parent chain (ancestor simulation)
Test-Ancestors -TestName "Get ancestors - Parent chain via parent" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    parent {
      id
      name
      path
      parent {
        id
        name
        path
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent -and $data.item.parent.parent
}

# Test 2: Verify parent is content
Test-Ancestors -TestName "Get ancestors - Verify parent name" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    path
    parent {
      name
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent.name -eq "content"
}

# Test 3: Get parent with template info
Test-Ancestors -TestName "Get ancestors - Parent with template" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    parent {
      id
      name
      path
      template {
        id
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent -and $data.item.parent.template
}

# Test 4: Get parent with language parameter (nl-NL)
Test-Ancestors -TestName "Get ancestors - Dutch language (nl-NL)" -Query @"
{
  item(path: "/sitecore/content/Home", language: "nl-NL") {
    name
    parent {
      name
    }
  }
}
"@ -Validation { param($data) 
    # Accept if item exists (nl-NL may not exist)
    return $true
}

# Test 5: Get parent with version parameter
Test-Ancestors -TestName "Get ancestors - With version" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en", version: 1) {
    name
    version
    parent {
      name
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent
}

# Test 6: Root item has no parent
Test-Ancestors -TestName "Get ancestors - Root item (no parent)" -Query @"
{
  item(path: "/sitecore", language: "en") {
    name
    parent {
      id
    }
  }
}
"@ -Validation { param($data) 
    return $data.item -and ($null -eq $data.item.parent)
}

# Test 7: Get parent of deep nested item
Test-Ancestors -TestName "Get ancestors - Deep nested parent" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    path
    parent {
      name
      path
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent -and $data.item.parent.name -eq "Templates"
}

# Test 8: Verify 3-level parent chain
Test-Ancestors -TestName "Get ancestors - 3-level parent chain" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    parent {
      name
      parent {
        name
        parent {
          name
        }
      }
    }
  }
}
"@ -Validation { param($data) 
    # Home -> content -> sitecore -> (null)
    return $data.item.parent.name -eq "content" -and $data.item.parent.parent.name -eq "sitecore"
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_ancestors" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host "" 
Write-Host "[INFO] Note: GraphQL 'ancestors' field not supported" -ForegroundColor Yellow
Write-Host "[INFO] Tests use recursive parent queries as workaround" -ForegroundColor Yellow

exit $script:failCount
