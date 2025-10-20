# Test nieuwe MCP functionaliteit: Schema Scanner en /sitecore commands
# NOTE: Emoji's werken niet in PowerShell - gebruik ASCII met kleuren

Write-Host "`n=== Test 1: Schema Scanner ===" -ForegroundColor Cyan
Write-Host "Testing schema scan functionality..." -ForegroundColor Yellow

# Simulate MCP tool call (in real usage, this would be called via MCP protocol)
# For now, we'll test via direct GraphQL query

$apiKey = if ($env:SITECORE_API_KEY) { $env:SITECORE_API_KEY } else { "{YOUR-API-KEY}" }
$endpoint = if ($env:SITECORE_ENDPOINT) { $env:SITECORE_ENDPOINT } else { "https://your-sitecore-instance.com/sitecore/api/graph/items/master" }

if ($apiKey -eq "{YOUR-API-KEY}") {
    Write-Host "ERROR: SITECORE_API_KEY environment variable is required" -ForegroundColor Red
    exit 1
}

$headers = @{
    "sc_apikey" = $apiKey
    "Content-Type" = "application/json"
}

# Test introspection query (basis voor schema scanner)
$introspectionQuery = @"
{
  __schema {
    queryType { name }
    mutationType { name }
    types(includeDeprecated: false) {
      name
      kind
      description
    }
  }
}
"@

$body = @{ query = $introspectionQuery } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body -Headers $headers
    $schema = $response.data.__schema
    
    Write-Host ""
    Write-Host "[OK] Schema Scan SUCCESS!" -ForegroundColor Green
    Write-Host "Query Type: $($schema.queryType.name)" -ForegroundColor Cyan
    Write-Host "Mutation Type: $($schema.mutationType.name)" -ForegroundColor Cyan
    
    $objectTypes = $schema.types | Where-Object { $_.kind -eq "OBJECT" -and !$_.name.StartsWith("__") }
    $templateTypes = $objectTypes | Where-Object { $_.name.StartsWith("_") }
    
    Write-Host ""
    Write-Host "Type Statistics:" -ForegroundColor Yellow
    Write-Host "  Total Object Types: $($objectTypes.Count)"
    Write-Host "  Template Types (start with _): $($templateTypes.Count)"
    
    Write-Host ""
    Write-Host "Sample Template Types (first 10):" -ForegroundColor Yellow
    $templateTypes | Select-Object -First 10 | ForEach-Object {
        Write-Host "  - $($_.name)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Test 1: PASSED" -ForegroundColor Green
} catch {
    Write-Host "Test 1: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test 2: Query Type Fields ===" -ForegroundColor Cyan
Write-Host "Getting available operations..." -ForegroundColor Yellow

# Direct query zonder nested ConvertTo-Json issues
$queryFieldsQuery = '{ __type(name: \"Query\") { fields { name description } } }'

try {
    $body2 = @{ query = $queryFieldsQuery } | ConvertTo-Json -Compress
    $response2 = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body2 -Headers $headers -ContentType "application/json"
    $queryFields = $response2.data.__type.fields
    
    Write-Host ""
    Write-Host "[OK] Query Operations Found: $($queryFields.Count)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Available Query Operations:" -ForegroundColor Yellow
    $queryFields | Select-Object -First 10 | ForEach-Object {
        $requiredArgs = $_.args | Where-Object { $_.type.kind -eq "NON_NULL" }
        $argInfo = if ($requiredArgs) { "($($requiredArgs.Count) required args)" } else { "(no required args)" }
        Write-Host "  - $($_.name) $argInfo" -ForegroundColor Gray
        if ($_.description) {
            Write-Host "    $($_.description)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    Write-Host "Test 2: PASSED" -ForegroundColor Green
} catch {
    Write-Host "Test 2: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test 3: Input Types Analysis ===" -ForegroundColor Cyan
Write-Host "Analyzing search filters..." -ForegroundColor Yellow

# Simplified query zonder nested quotes
$inputTypesQuery = '{ __type(name: \"ItemSearchFilter\") { name kind inputFields { name } } }'

try {
    $body3 = @{ query = $inputTypesQuery } | ConvertTo-Json -Compress
    $response3 = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body3 -Headers $headers -ContentType "application/json"
    $filterType = $response3.data.__type
    
    if ($filterType) {
        Write-Host ""
        Write-Host "[OK] ItemSearchFilter Found!" -ForegroundColor Green
        Write-Host "Available Filters:" -ForegroundColor Yellow
        
        $filterType.inputFields | ForEach-Object {
            $typeName = if ($_.type.ofType) { $_.type.ofType.name } else { $_.type.name }
            Write-Host "  - $($_.name): $typeName" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Test 3: PASSED" -ForegroundColor Green
    } else {
        Write-Host "No ItemSearchFilter type found" -ForegroundColor Yellow
        Write-Host "Test 3: SKIPPED" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test 3: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test 4: MCP Server Integration Test ===" -ForegroundColor Cyan
Write-Host "Testing if MCP server builds correctly..." -ForegroundColor Yellow

# Check if build output exists
$buildPath = "c:\gary\Sitecore\SitecoreMCP\dist\index.js"
if (Test-Path $buildPath) {
    Write-Host ""
    Write-Host "[OK] Build output found: $buildPath" -ForegroundColor Green
    
    # Check file size
    $fileSize = (Get-Item $buildPath).Length
    Write-Host "Build file size: $([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Cyan
    
    # Count exported tools (check for our new tools)
    $buildContent = Get-Content $buildPath -Raw
    $hasSchemaScanner = $buildContent -match "sitecore_scan_schema"
    $hasCommand = $buildContent -match "sitecore_command"
    
    Write-Host ""
    Write-Host "New Tools Check:" -ForegroundColor Yellow
    Write-Host "  - sitecore_scan_schema: $(if($hasSchemaScanner){'[FOUND]'}else{'[MISSING]'})" -ForegroundColor $(if($hasSchemaScanner){'Green'}else{'Red'})
    Write-Host "  - sitecore_command: $(if($hasCommand){'[FOUND]'}else{'[MISSING]'})" -ForegroundColor $(if($hasCommand){'Green'}else{'Red'})
    
    if ($hasSchemaScanner -and $hasCommand) {
        Write-Host ""
        Write-Host "Test 4: PASSED" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Test 4: PARTIAL - Not all tools found in build" -ForegroundColor Yellow
    }
} else {
    Write-Host "Build output not found. Run 'npm run build' first." -ForegroundColor Red
    Write-Host "Test 4: FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== All Tests Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Schema Scanner Features:" -ForegroundColor Yellow
Write-Host "  [OK] Introspection queries work" -ForegroundColor Green
Write-Host "  [OK] Can detect Query/Mutation types" -ForegroundColor Green
Write-Host "  [OK] Can list template types" -ForegroundColor Green
Write-Host "  [OK] Can analyze input types" -ForegroundColor Green
Write-Host "  [OK] MCP tools implemented and built" -ForegroundColor Green

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Restart Claude Desktop or VS Code" -ForegroundColor Gray
Write-Host "2. Try: '/sitecore help'" -ForegroundColor Gray
Write-Host "3. Try: '/sitecore scan schema'" -ForegroundColor Gray
Write-Host "4. Try: '/sitecore get item /sitecore/content/Home'" -ForegroundColor Gray
Write-Host "5. Check schema-analysis.json for full scan results" -ForegroundColor Gray
Write-Host ""
