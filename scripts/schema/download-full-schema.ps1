# ========================================
# Download FULL GraphQL Schema via Introspection
# Gets complete type definitions with fields
# ========================================

param(
		[string]$ApiKey = $env:SITECORE_API_KEY,
		[string]$Endpoint = $env:SITECORE_ENDPOINT
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Full GraphQL Schema Downloader" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment
if (Test-Path "$PSScriptRoot\..\..\.env") {
		Get-Content "$PSScriptRoot\..\..\.env" | ForEach-Object {
				if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
						$key = $matches[1].Trim()
						$value = $matches[2].Trim()
						if ([string]::IsNullOrEmpty((Get-Item Env:$key -ErrorAction SilentlyContinue))) {
								[System.Environment]::SetEnvironmentVariable($key, $value)
						}
				}
		}
		$ApiKey = $env:SITECORE_API_KEY
		$Endpoint = $env:SITECORE_ENDPOINT
}

if ([string]::IsNullOrEmpty($ApiKey) -or [string]::IsNullOrEmpty($Endpoint)) {
		Write-Host "[FAIL] Missing SITECORE_API_KEY or SITECORE_ENDPOINT" -ForegroundColor Red
		exit 1
}

Write-Host "[INFO] Endpoint: $Endpoint" -ForegroundColor Cyan
Write-Host ""

$headers = @{
		"sc_apikey" = $ApiKey
		"Content-Type" = "application/json"
}

# Full introspection query
$introspectionQuery = @"
query IntrospectionQuery {
	__schema {
		queryType { name }
		mutationType { name }
		subscriptionType { name }
		types {
			...FullType
		}
		directives {
			name
			description
			locations
			args {
				...InputValue
			}
		}
	}
}

fragment FullType on __Type {
	kind
	name
	description
	fields(includeDeprecated: true) {
		name
		description
		args {
			...InputValue
		}
		type {
			...TypeRef
		}
		isDeprecated
		deprecationReason
	}
	inputFields {
		...InputValue
	}
	interfaces {
		...TypeRef
	}
	enumValues(includeDeprecated: true) {
		name
		description
		isDeprecated
		deprecationReason
	}
	possibleTypes {
		...TypeRef
	}
}

fragment InputValue on __InputValue {
	name
	description
	type { ...TypeRef }
	defaultValue
}

fragment TypeRef on __Type {
	kind
	name
	ofType {
		kind
		name
		ofType {
			kind
			name
			ofType {
				kind
				name
				ofType {
					kind
					name
					ofType {
						kind
						name
						ofType {
							kind
							name
							ofType {
								kind
								name
							}
						}
					}
				}
			}
		}
	}
}
"@

Write-Host "[INFO] Sending introspection query..." -ForegroundColor Cyan

try {
		$query = @{
				query = $introspectionQuery
		} | ConvertTo-Json -Depth 10

		$response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $query -ContentType "application/json"
    
		if ($response.errors) {
				Write-Host "[FAIL] GraphQL errors:" -ForegroundColor Red
				$response.errors | ForEach-Object {
						Write-Host "  $($_.message)" -ForegroundColor Red
				}
				exit 1
		}
    
		if ($response.data.__schema) {
				$schema = $response.data.__schema
        
				Write-Host "[OK] Schema received" -ForegroundColor Green
				Write-Host "  Query Type: $($schema.queryType.name)" -ForegroundColor Gray
				Write-Host "  Mutation Type: $($schema.mutationType.name)" -ForegroundColor Gray
				Write-Host "  Total Types: $($schema.types.Count)" -ForegroundColor Gray
				Write-Host ""
        
				# Save full schema
				$fullSchemaFile = ".github\introspectionSchema-FULL.json"
				$response.data | ConvertTo-Json -Depth 100 | Set-Content $fullSchemaFile
				Write-Host "[OK] Full schema saved: $fullSchemaFile" -ForegroundColor Green
				Write-Host ""
        
				# Extract specific types we care about
				Write-Host "[INFO] Extracting core types..." -ForegroundColor Cyan
        
				$coreTypeNames = @('Query', 'Mutation', 'Item', 'ItemTemplate', 'ItemField', 'ItemLanguage', 
													 'TextField', 'DateField', 'ImageField', 'LinkField', 'ContentSearchResults',
													 'ContentSearchResultConnection', 'PageInfo')
        
				$outputDir = ".\.schema-analysis"
				if (-not (Test-Path $outputDir)) {
						New-Item -ItemType Directory -Path $outputDir | Out-Null
				}
        
				foreach ($typeName in $coreTypeNames) {
						$type = $schema.types | Where-Object { $_.name -eq $typeName }
            
						if ($type) {
								$fileName = "$outputDir\type_$typeName.json"
								$type | ConvertTo-Json -Depth 100 | Set-Content $fileName
                
								Write-Host "  [OK] $typeName" -ForegroundColor Green
								if ($type.fields) {
										Write-Host "    Fields: $($type.fields.Count)" -ForegroundColor Gray
								}
								if ($type.interfaces) {
										Write-Host "    Implements: $($type.interfaces.Count) interface(s)" -ForegroundColor Gray
								}
						} else {
								Write-Host "  [WARN] $typeName not found" -ForegroundColor Yellow
						}
				}
        
				Write-Host ""
				Write-Host "[SUCCESS] Schema analysis complete!" -ForegroundColor Green
				Write-Host "Output directory: $outputDir" -ForegroundColor Cyan
        
		} else {
				Write-Host "[FAIL] No schema data received" -ForegroundColor Red
				exit 1
		}
    
} catch {
		Write-Host "[FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
		exit 1
}