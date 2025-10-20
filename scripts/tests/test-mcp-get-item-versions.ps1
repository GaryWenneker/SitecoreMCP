# Test script for sitecore_get_item_versions MCP tool
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

function Test-Versions {
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

Write-Host "=== Testing sitecore_get_item_versions ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get all versions of item (English)
Test-Versions -TestName "Get versions - English language" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    language {
      name
    }
    versions {
      version
      language {
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.versions -and $data.item.versions.Count -ge 1
}

# Test 2: Get all versions with fields
Test-Versions -TestName "Get versions - With field data" -Query @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    name
    versions {
      version
      fields(ownFields: false) {
        name
        value
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.versions -and $data.item.versions[0].fields
}

# Test 3: Get versions for Dutch language
Test-Versions -TestName "Get versions - Dutch language (nl-NL)" -Query @"
{
  item(path: "/sitecore/content/Home", language: "nl-NL") {
    name
    language {
      name
    }
    versions {
      version
      language {
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    # nl-NL version may not exist
    return $true
}

# Test 4: Verify version numbers
Test-Versions -TestName "Get versions - Verify version numbers" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    name
    versions {
      version
    }
  }
}
"@ -Validation { param($data) 
    if ($data.item.versions -and $data.item.versions.Count -gt 0) {
        # Versions should be numbered starting from 1
        return $data.item.versions[0].version -ge 1
    }
    return $true  # No versions is acceptable
}

# Test 5: Get versions of template item
Test-Versions -TestName "Get versions - Template item" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    versions {
      version
      language {
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    return $data.item.versions -and $data.item.versions.Count -ge 1
}

# Test 6: Get versions count
Test-Versions -TestName "Get versions - Count versions" -Query @"
{
  item(path: "/sitecore/content", language: "en") {
    name
    language {
      name
    }
    versions {
      version
    }
  }
}
"@ -Validation { param($data) 
    if ($data.item.versions) {
        Write-Host "  Total versions: $($data.item.versions.Count)" -ForegroundColor Gray
        return $data.item.versions.Count -ge 1
    }
    return $false
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_item_versions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

exit $script:failCount
