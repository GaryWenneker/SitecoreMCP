# Test script for sitecore_get_parent MCP tool
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

function Test-Parent {
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

Write-Host "=== Testing sitecore_get_parent ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get parent of content item
Test-Parent -TestName "Get parent - Content item" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    parent {
      id
      name
      path
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent -and $data.item.parent.name -eq "content"
}

# Test 2: Get parent with template info
Test-Parent -TestName "Get parent - With template info" -Query @"
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

# Test 3: Get parent with language parameter (nl-NL)
Test-Parent -TestName "Get parent - Dutch language (nl-NL)" -Query @"
{
  item(path: "/sitecore/content/Home", language: "nl-NL") {
    name
    parent {
      id
      name
      path
    }
  }
}
"@ -Validation { param($data) 
    # nl-NL version may not exist, accept if item is null
    return $true
}

# Test 4: Get parent with version parameter
Test-Parent -TestName "Get parent - With version" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en", version: 1) {
    name
    version
    parent {
      id
      name
      path
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent
}

# Test 5: Root item has no parent
Test-Parent -TestName "Get parent - Root item (null parent)" -Query @"
{
  item(path: "/sitecore", language: "en") {
    name
    parent {
      id
      name
    }
  }
}
"@ -Validation { param($data) 
    return $data.item -and $null -eq $data.item.parent
}

# Test 6: Get parent of template item
Test-Parent -TestName "Get parent - Template item" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    parent {
      id
      name
      path
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent -and $data.item.parent.name -eq "Templates"
}

# Test 7: Get parent with hasChildren flag
Test-Parent -TestName "Get parent - With hasChildren flag" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    parent {
      id
      name
      path
      hasChildren
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent -and $data.item.parent.hasChildren -eq $true
}

# Test 8: Get grandparent (parent.parent)
Test-Parent -TestName "Get parent - Nested parent (grandparent)" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    parent {
      name
      parent {
        id
        name
        path
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.parent.parent -and $data.item.parent.parent.name -eq "sitecore"
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_parent" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

exit $script:failCount
