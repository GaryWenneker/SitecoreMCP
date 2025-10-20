# Test Sitecore GraphQL Mutations
Write-Host "=== Test Sitecore GraphQL Mutations ===" -ForegroundColor Cyan
Write-Host ""

# Load environment variables
. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

if (-not $env:SITECORE_API_KEY) {
    Write-Host "[ERROR] SITECORE_API_KEY not found in .env" -ForegroundColor Red
    exit 1
}

$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

Write-Host "[INFO] Testing GraphQL Mutations" -ForegroundColor Yellow
Write-Host "Endpoint: $endpoint" -ForegroundColor Gray
Write-Host ""

# Test 1: Query Mutation type via introspection
Write-Host "[TEST 1] Query Mutation type fields..." -ForegroundColor Cyan
$introspectionQuery = @"
{
  __type(name: "Mutation") {
    name
    fields {
      name
      description
      args {
        name
        type {
          name
          kind
        }
      }
    }
  }
}
"@

try {
    $body = @{ query = $introspectionQuery } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
    
    if ($response.data.__type) {
        Write-Host "[OK] Mutation type found!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Available Mutations:" -ForegroundColor Yellow
        foreach ($field in $response.data.__type.fields) {
            Write-Host "  - $($field.name)" -ForegroundColor White
            if ($field.description) {
                Write-Host "    Description: $($field.description)" -ForegroundColor Gray
            }
            if ($field.args.Count -gt 0) {
                Write-Host "    Arguments:" -ForegroundColor Gray
                foreach ($arg in $field.args) {
                    Write-Host "      * $($arg.name): $($arg.type.name)" -ForegroundColor DarkGray
                }
            }
        }
        Write-Host ""
    } else {
        Write-Host "[FAIL] No Mutation type found" -ForegroundColor Red
        if ($response.errors) {
            Write-Host "Errors:" -ForegroundColor Red
            $response.errors | ConvertTo-Json -Depth 5
        }
    }
} catch {
    Write-Host "[ERROR] Introspection query failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

# Test 2: Try common mutation operations
Write-Host "[TEST 2] Testing common mutation patterns..." -ForegroundColor Cyan
Write-Host ""

$mutationPatterns = @(
    @{
        Name = "updateItem"
        Query = @"
mutation {
  updateItem(path: "/sitecore/content/test", language: "en", fields: [{name: "Title", value: "Test"}]) {
    item {
      id
      name
    }
  }
}
"@
    },
    @{
        Name = "updateItemField"
        Query = @"
mutation {
  updateItemField(itemId: "{11111111-1111-1111-1111-111111111111}", language: "en", fieldName: "Title", fieldValue: "Test") {
    id
    name
  }
}
"@
    },
    @{
        Name = "setFieldValue"
        Query = @"
mutation {
  setFieldValue(itemId: "{11111111-1111-1111-1111-111111111111}", language: "en", fieldName: "Title", value: "Test")
}
"@
    }
)

foreach ($pattern in $mutationPatterns) {
    Write-Host "[INFO] Testing: $($pattern.Name)" -ForegroundColor Yellow
    try {
        $body = @{ query = $pattern.Query } | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body
        
        if ($response.errors) {
            Write-Host "  Result: Operation not supported (expected)" -ForegroundColor DarkGray
            $errorMsg = $response.errors[0].message
            if ($errorMsg -like "*Unknown field*" -or $errorMsg -like "*Cannot query field*") {
                Write-Host "  Reason: Field does not exist in schema" -ForegroundColor DarkGray
            } else {
                Write-Host "  Error: $errorMsg" -ForegroundColor Red
            }
        } else {
            Write-Host "  [OK] Operation supported!" -ForegroundColor Green
            $response.data | ConvertTo-Json -Depth 3
        }
    } catch {
        Write-Host "  [ERROR] Request failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[INFO] According to Sitecore documentation:" -ForegroundColor Yellow
Write-Host ""
Write-Host "The /items/master endpoint DOES support mutations via:" -ForegroundColor White
Write-Host "  1. Sitecore Experience Editor" -ForegroundColor Gray
Write-Host "  2. REST API: /sitecore/api/ssc/item/{id}" -ForegroundColor Gray
Write-Host "" 
Write-Host "  [BANNED] Sitecore PowerShell Extensions (SPE)" -ForegroundColor Red
Write-Host "    - Remote code execution risk" -ForegroundColor DarkGray
Write-Host "    - Not allowed in production" -ForegroundColor DarkGray
Write-Host ""
Write-Host "GraphQL /items/master endpoint is primarily READ-ONLY for:" -ForegroundColor White
Write-Host "  - Query operations (item, search, children, etc.)" -ForegroundColor Gray
Write-Host "  - Layout Service queries" -ForegroundColor Gray
Write-Host ""
Write-Host "For WRITE operations (create/update/delete), use:" -ForegroundColor Yellow
Write-Host "  1. Sitecore Services Client (SSC) REST API" -ForegroundColor White
Write-Host "     POST /sitecore/api/ssc/item/{itemId}" -ForegroundColor Gray
Write-Host "  2. Custom REST API Controller" -ForegroundColor White
Write-Host "     Secure endpoint with API key authentication" -ForegroundColor Gray
Write-Host "  3. Sitecore Experience Editor" -ForegroundColor White
Write-Host "     UI-based editing" -ForegroundColor Gray
Write-Host ""
Write-Host "  [BANNED] Sitecore PowerShell Extensions (SPE)" -ForegroundColor Red
Write-Host "    - Security risk: Remote code execution" -ForegroundColor DarkGray
Write-Host "    - Not recommended for production" -ForegroundColor DarkGray
Write-Host ""
Write-Host "[RECOMMENDATION] Add MCP tools using SSC REST API for mutations" -ForegroundColor Green
Write-Host ""
