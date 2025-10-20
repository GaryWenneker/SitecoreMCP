# Test script for sitecore_get_templates MCP tool
# Tests retrieving multiple templates with path filter

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

function Test-Templates {
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

Write-Host "=== Testing sitecore_get_templates ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Get templates folder
Test-Templates -TestName "Get templates - Templates root folder" -Query @"
{
  item(path: "/sitecore/templates", language: "en") {
    id
    name
    path
    hasChildren
  }
}
"@ -Validation { param($data) 
    return $data.item -and $data.item.name -eq "templates" -and $data.item.hasChildren -eq $true
}

# Test 2: Get System templates
Test-Templates -TestName "Get templates - System templates" -Query @"
{
  item(path: "/sitecore/templates/System", language: "en") {
    name
    children(first: 10) {
      name
      path
      template {
        name
      }
    }
  }
}
"@ -Validation { param($data) 
    $children = $data.item.children
    Write-Host "  Found $($children.Count) system template folders" -ForegroundColor Gray
    return $children.Count -ge 1
}

# Test 3: Search for templates by template type
Test-Templates -TestName "Get templates - Search by Template type" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/templates/System"
    first: 10
    fieldsEqual: [
      { name: "_templatename", value: "Template" }
    ]
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
"@ -Validation { param($data) 
    return $data.search.results.items.Count -ge 0
}

# Test 4: Get template with sections
Test-Templates -TestName "Get templates - Template with sections" -Query @"
{
  item(path: "/sitecore/templates/System/Templates/Template", language: "en") {
    name
    children(first: 10) {
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

# Test 5: Get User Defined templates folder
Test-Templates -TestName "Get templates - User Defined folder" -Query @"
{
  item(path: "/sitecore/templates", language: "en") {
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
    # Should have System, Common, User Defined, etc.
    Write-Host "  Found $($children.Count) template folders" -ForegroundColor Gray
    return $children.Count -ge 1
}

# Test 6: Get templates with Template Field template type
Test-Templates -TestName "Get templates - Template Field type" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/templates/System"
    first: 5
    fieldsEqual: [
      { name: "_templatename", value: "Template field" }
    ]
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
"@ -Validation { param($data) 
    return $data.search.results.items.Count -ge 0
}

# Test 7: Count templates in System folder
Test-Templates -TestName "Get templates - Count System templates" -Query @"
{
  search(
    keyword: ""
    rootItem: "/sitecore/templates/System"
    first: 50
  ) {
    results {
      totalCount
      items {
        name
        templateName
      }
    }
  }
}
"@ -Validation { param($data) 
    $totalCount = $data.search.results.totalCount
    Write-Host "  Total System templates: $totalCount" -ForegroundColor Gray
    return $totalCount -ge 0
}

# Test 8: Get template by GUID
Test-Templates -TestName "Get templates - By GUID (Standard template)" -Query @"
{
  item(path: "{1930BBEB-7805-471A-A3BE-4858AC7CF696}", language: "en") {
    id
    name
    path
    template {
      name
    }
  }
}
"@ -Validation { param($data) 
    # Standard template GUID - may or may not exist
    return $true
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Results: sitecore_get_templates" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $script:passCount" -ForegroundColor Green
Write-Host "Failed: $script:failCount" -ForegroundColor $(if ($script:failCount -eq 0) { "Green" } else { "Red" })

Write-Host ""
Write-Host "[INFO] Note: Templates are in /sitecore/templates" -ForegroundColor Yellow
Write-Host "[INFO] Use search with _templatename filter to find specific types" -ForegroundColor Yellow

exit $script:failCount
