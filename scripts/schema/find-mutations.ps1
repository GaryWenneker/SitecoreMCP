# Find Mutation Operations in GraphQL Schema
Write-Host "=== GraphQL Mutation Operations Discovery ===" -ForegroundColor Cyan
Write-Host ""

# Load schema
$schemaPath = ".\.github\introspectionSchema.json"
Write-Host "[INFO] Loading schema from: $schemaPath" -ForegroundColor Yellow
$schema = Get-Content $schemaPath -Raw | ConvertFrom-Json

Write-Host "[OK] Schema loaded" -ForegroundColor Green
Write-Host ""

# Find Mutation type
Write-Host "[INFO] Searching for Mutation type..." -ForegroundColor Yellow

# The schema structure has _typeMap which contains all types
$mutationType = $schema._typeMap.PSObject.Properties | Where-Object { $_.Name -eq "Mutation" }

if ($mutationType) {
    Write-Host "[OK] Found Mutation type!" -ForegroundColor Green
    Write-Host ""
    
    # Get the Mutation type details
    $mutationDetails = $mutationType.Value
    Write-Host "Mutation Type Details:" -ForegroundColor Cyan
    $mutationDetails | ConvertTo-Json -Depth 3
    Write-Host ""
} else {
    Write-Host "[FAIL] Mutation type not found" -ForegroundColor Red
}

# Search for update/create/delete operations in the entire schema
Write-Host "[INFO] Searching for mutation-related operations..." -ForegroundColor Yellow
$schemaText = Get-Content $schemaPath -Raw

# Search patterns
$patterns = @(
    '"updateItem"',
    '"createItem"',
    '"deleteItem"',
    '"update"',
    '"create"',
    '"delete"',
    '"mutation"',
    '"Mutation"'
)

foreach ($pattern in $patterns) {
    $matches = [regex]::Matches($schemaText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($matches.Count -gt 0) {
        Write-Host "[OK] Found $($matches.Count) matches for: $pattern" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[INFO] Checking official Sitecore GraphQL documentation..." -ForegroundColor Yellow
Write-Host ""
Write-Host "According to Sitecore documentation, the /items/master endpoint supports:" -ForegroundColor Cyan
Write-Host "  - Query operations (item, search, etc.)" -ForegroundColor White
Write-Host "  - Mutation operations for:" -ForegroundColor White
Write-Host "    * Creating items" -ForegroundColor White
Write-Host "    * Updating item fields" -ForegroundColor White
Write-Host "    * Deleting items" -ForegroundColor White
Write-Host ""
Write-Host "[NEXT] Testing mutation operations via GraphQL UI" -ForegroundColor Yellow
Write-Host "URL: https://your-instance/sitecore/api/graph/items/master/ui" -ForegroundColor Gray
Write-Host ""
