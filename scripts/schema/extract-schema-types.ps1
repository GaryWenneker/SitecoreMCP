# ========================================
# Schema Type Extractor
# Extracts specific types from introspectionSchema.json
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Schema Type Extractor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load schema
Write-Host "[INFO] Loading introspectionSchema.json..." -ForegroundColor Cyan
$schema = Get-Content "$PSScriptRoot\..\..\.github\introspectionSchema.json" -Raw | ConvertFrom-Json

Write-Host "[OK] Schema loaded" -ForegroundColor Green
Write-Host "  Query Type: $($schema._queryType)" -ForegroundColor Gray
Write-Host "  Mutation Type: $($schema._mutationType)" -ForegroundColor Gray
Write-Host "  Subscription Type: $($schema._subscriptionType)" -ForegroundColor Gray
Write-Host ""

# Get type map
$typeMap = $schema._typeMap

# Core types we need to verify
$coreTypeNames = @(
	'Query',
	'Mutation',
	'Item',
	'ItemTemplate',
	'ItemField',
	'ItemLanguage',
	'TextField',
	'DateField',
	'ImageField',
	'LinkField',
	'FileField',
	'CheckboxField',
	'IntegerField',
	'NumberField',
	'MultilistField',
	'LookupField',
	'ReferenceField',
	'LayoutField',
	'NameValueListField',
	'ContentSearchResults',
	'ContentSearchResultConnection',
	'ContentSearchResult',
	'PageInfo',
	'ItemTemplateField',
	'ItemWorkflow',
	'ItemWorkflowState',
	'SiteGraphType'
)

Write-Host "[INFO] Extracting $($coreTypeNames.Count) core types..." -ForegroundColor Cyan
Write-Host ""

# Output directory
$outputDir = "$PSScriptRoot\..\..\.schema-analysis"
if (-not (Test-Path $outputDir)) {
	New-Item -ItemType Directory -Path $outputDir | Out-Null
	Write-Host "[OK] Created output directory: $outputDir" -ForegroundColor Green
}

# Extract each type
$found = 0
$notFound = 0

foreach ($typeName in $coreTypeNames) {
	Write-Host "[EXTRACT] $typeName..." -ForegroundColor Yellow
    
	# Check if type exists in typeMap
	if ($typeMap.PSObject.Properties.Name -contains $typeName) {
		$typeData = $typeMap.$typeName
        
		# Save to individual file
		$fileName = "$outputDir\type_$typeName.json"
		$typeData | ConvertTo-Json -Depth 100 | Set-Content $fileName
        
		# Get type info
		if ($typeData -is [string]) {
			Write-Host "  [WARN] Type is string reference: $typeData" -ForegroundColor Yellow
		} else {
			$fields = $typeData._fields
			$interfaces = $typeData._interfaces
            
			Write-Host "  [OK] Extracted" -ForegroundColor Green
			if ($fields) {
				Write-Host "    Fields: $($fields.PSObject.Properties.Name.Count)" -ForegroundColor Gray
			}
			if ($interfaces) {
				Write-Host "    Interfaces: $($interfaces.Count)" -ForegroundColor Gray
			}
		}
        
		$found++
	} else {
		Write-Host "  [FAIL] Type not found in schema!" -ForegroundColor Red
		$notFound++
	}
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Extraction Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Types: $($coreTypeNames.Count)" -ForegroundColor White
Write-Host "Found: $found" -ForegroundColor Green
Write-Host "Not Found: $notFound" -ForegroundColor $(if ($notFound -eq 0) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Output: $outputDir" -ForegroundColor Cyan
Write-Host ""

# Generate field analysis
Write-Host "[INFO] Generating field analysis..." -ForegroundColor Cyan

$fieldAnalysis = @()

foreach ($typeName in $coreTypeNames) {
	if ($typeMap.PSObject.Properties.Name -contains $typeName) {
		$typeData = $typeMap.$typeName
        
		if ($typeData -isnot [string] -and $typeData._fields) {
			$fields = $typeData._fields
            
			foreach ($fieldName in $fields.PSObject.Properties.Name) {
				$field = $fields.$fieldName
                
				$fieldAnalysis += [PSCustomObject]@{
					Type = $typeName
					Field = $fieldName
					FieldType = $field.type.name
					NonNull = $field.type.kind -eq 'NON_NULL'
					IsList = $field.type.ofType.kind -eq 'LIST'
				}
			}
		}
	}
}

# Save field analysis
$fieldAnalysisFile = "$outputDir\field_analysis.csv"
$fieldAnalysis | Export-Csv $fieldAnalysisFile -NoTypeInformation
Write-Host "[OK] Field analysis saved: $fieldAnalysisFile" -ForegroundColor Green
Write-Host "  Total fields: $($fieldAnalysis.Count)" -ForegroundColor Gray
Write-Host ""

if ($notFound -eq 0) {
	Write-Host "[SUCCESS] All types extracted successfully!" -ForegroundColor Green
} else {
	Write-Host "[WARNING] Some types were not found" -ForegroundColor Yellow
}