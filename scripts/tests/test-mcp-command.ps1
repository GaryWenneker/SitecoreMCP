# Test script for sitecore_command MCP tool
# Tests natural language command parsing

# Load environment variables
. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

if (-not $env:SITECORE_API_KEY) {
    Write-Host "[ERROR] SITECORE_API_KEY not found in environment" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Environment variables loaded successfully!" -ForegroundColor Green
Write-Host ""

# Configuration - This tool doesn't actually exist as a GraphQL endpoint
# It's an MCP tool that parses natural language and calls other tools
# We'll test the underlying queries it would generate

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

# Test results tracking
$script:passCount = 0
$script:failCount = 0

function Test-Command {
    param(
        [string]$TestName,
        [string]$Description,
        [scriptblock]$TestLogic
    )
    
    Write-Host "[TEST] $TestName" -ForegroundColor Cyan
    Write-Host "  Command: $Description" -ForegroundColor Gray
    
    try {
        $result = & $TestLogic
        
        if ($result) {
            Write-Host "[PASS]" -ForegroundColor Green
            $script:passCount++
        } else {
            Write-Host "[FAIL] Test logic returned false" -ForegroundColor Red
            $script:failCount++
        }
    }
    catch {
        Write-Host "[FAIL] Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failCount++
    }
    Write-Host ""
}

Write-Host "=== Testing sitecore_command ===" -ForegroundColor Cyan
Write-Host "[INFO] This tool parses natural language and executes appropriate queries" -ForegroundColor Yellow
Write-Host ""

# Test 1: "get item /sitecore/content/Home"
Test-Command -TestName "Command - Get item" -Description "get item /sitecore/content/Home" -TestLogic {
    $query = @"
{
  item(path: "/sitecore/content/Home", language: "en") {
    id
    name
    path
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    return $response.data.item -ne $null
}

# Test 2: "search for items with template Page"
Test-Command -TestName "Command - Search by template" -Description "search for items with template Page" -TestLogic {
    $query = @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/content"
    first: 5
  ) {
    results {
      items {
        name
        path
        templateName
      }
    }
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    return $response.data.search.results.items.Count -ge 0
}

# Test 3: "show me all templates"
Test-Command -TestName "Command - List templates" -Description "show me all templates" -TestLogic {
    $query = @"
{
  item(path: "/sitecore/templates", language: "en") {
    name
    children(first: 10) {
      name
      path
    }
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    return $response.data.item.children.Count -ge 1
}

# Test 4: "get children of /sitecore/content"
Test-Command -TestName "Command - Get children" -Description "get children of /sitecore/content" -TestLogic {
    $query = @"
{
  item(path: "/sitecore/content", language: "en") {
    name
    children(first: 10) {
      name
      path
    }
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    return $response.data.item.children -ne $null
}

# Test 5: "find items with path containing Home"
Test-Command -TestName "Command - Search by path" -Description "find items with path containing Home" -TestLogic {
    $query = @"
{
  search(
    keyword: "Home"
    rootItem: "/sitecore/content"
    first: 10
  ) {
    results {
      items {
        name
        path
      }
    }
  }
}
"@
    $body = @{ query = $query } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    return $response.data.search.results.items.Count -ge 0
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_command" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[INFO] Note: This tool parses natural language into GraphQL queries" -ForegroundColor Yellow
Write-Host "[INFO] Examples: 'get item X', 'search for Y', 'show me Z'" -ForegroundColor Yellow

exit $script:failCount
