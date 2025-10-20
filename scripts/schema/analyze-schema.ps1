# Test GraphQL Schema Analysis
# This script will fetch and analyze the GraphQL schema

$endpoint = $env:SITECORE_ENDPOINT
$apiKey = $env:SITECORE_API_KEY

if (-not $endpoint) {
		. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
		Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"
		$endpoint = $env:SITECORE_ENDPOINT
		$apiKey = $env:SITECORE_API_KEY
}

Write-Host "=== GraphQL Schema Analysis ===" -ForegroundColor Cyan
Write-Host "Endpoint: $endpoint" -ForegroundColor Gray
Write-Host ""

$headers = @{
		"sc_apikey" = $apiKey
		"Content-Type" = "application/json"
}

# Test 1: Try introspection query
Write-Host "[TEST 1] Introspection Query" -ForegroundColor Yellow
$introspectionQuery = @{
		query = @"
{
	__schema {
		queryType {
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
				type {
					name
					kind
				}
			}
		}
	}
}
"@
} | ConvertTo-Json

try {
		$response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $introspectionQuery -Headers $headers -ErrorAction Stop
		Write-Host "[OK] Introspection succeeded!" -ForegroundColor Green
		Write-Host "Query type fields available:" -ForegroundColor Cyan
		$response.data.__schema.queryType.fields | ForEach-Object {
				Write-Host "  - $($_.name)" -ForegroundColor Gray
				if ($_.description) {
						Write-Host "    $($_.description)" -ForegroundColor DarkGray
				}
		}
    
		# Save full schema
		$response | ConvertTo-Json -Depth 100 | Out-File "schema-analysis-full.json"
		Write-Host ""
		Write-Host "[OK] Full schema saved to: schema-analysis-full.json" -ForegroundColor Green
}
catch {
		Write-Host "[FAIL] Introspection failed: $($_.Exception.Message)" -ForegroundColor Red
		Write-Host "[INFO] This is expected if introspection is disabled" -ForegroundColor Yellow
}

Write-Host ""

# Test 2: Try to get item with all possible fields
Write-Host "[TEST 2] Get Item Query (discover fields)" -ForegroundColor Yellow
$itemQuery = @{
		query = @"
{
	item(path: "/sitecore/content", language: "en") {
		id
		name
		displayName
		path
		language
		version
		template {
			id
			name
		}
		fields {
			name
			value
		}
		children {
			total
		}
		parent {
			id
			name
		}
	}
}
"@
} | ConvertTo-Json

try {
		$response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $itemQuery -Headers $headers -ErrorAction Stop
		Write-Host "[OK] Item query succeeded!" -ForegroundColor Green
		Write-Host "Item retrieved: $($response.data.item.name)" -ForegroundColor Cyan
		Write-Host "Available item properties:" -ForegroundColor Cyan
		$response.data.item.PSObject.Properties | ForEach-Object {
				Write-Host "  - $($_.Name): $($_.TypeNameOfValue)" -ForegroundColor Gray
		}
}
catch {
		Write-Host "[FAIL] Item query failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Check available top-level queries
Write-Host "[TEST 3] Available Top-Level Queries" -ForegroundColor Yellow
$queries = @(
		"item",
		"search", 
		"layout",
		"site",
		"contextItem",
		"route",
		"placeholder"
)

foreach ($queryName in $queries) {
		$testQuery = @{
				query = "{ __type(name: \"Query\") { fields { name } } }"
		} | ConvertTo-Json
    
		Write-Host "  Testing: $queryName" -ForegroundColor Gray -NoNewline
    
		# Simple test query
		$simpleTest = @{
				query = "{ $queryName }"
		} | ConvertTo-Json
    
		try {
				$null = Invoke-RestMethod -Uri $endpoint -Method Post -Body $simpleTest -Headers $headers -ErrorAction Stop
				Write-Host " - [OK]" -ForegroundColor Green
		}
		catch {
				if ($_.Exception.Message -match "Field.*not found") {
						Write-Host " - [NOT AVAILABLE]" -ForegroundColor DarkGray
				}
				elseif ($_.Exception.Message -match "required") {
						Write-Host " - [AVAILABLE] (requires args)" -ForegroundColor Yellow
				}
				else {
						Write-Host " - [UNKNOWN] $($_.Exception.Message)" -ForegroundColor Red
				}
		}
}

Write-Host ""
Write-Host "=== Analysis Complete ===" -ForegroundColor Cyan