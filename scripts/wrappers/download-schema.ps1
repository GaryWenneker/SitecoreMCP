Write-Host "[DEPRECATED] Use: scripts/schema/download-schema.ps1" -ForegroundColor Yellow
& "$PSScriptRoot\..\schema\download-schema.ps1"
exit $LASTEXITCODE

# Full introspection query
$introspectionQuery = @{
    query = @"
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
  type {
    ...TypeRef
  }
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
} | ConvertTo-Json -Depth 10

Write-Host "[INFO] Sending introspection query..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $introspectionQuery -Headers $headers -ErrorAction Stop
    
    if ($response.errors) {
        Write-Host "[FAIL] Errors returned:" -ForegroundColor Red
        $response.errors | ForEach-Object { Write-Host "  - $($_.message)" -ForegroundColor Red }
        exit 1
    }
    
    Write-Host "[OK] Schema downloaded successfully!" -ForegroundColor Green
    
    # Save full schema
    $response | ConvertTo-Json -Depth 100 | Out-File "graphql-schema-full.json" -Encoding UTF8
    Write-Host "[OK] Saved to: graphql-schema-full.json" -ForegroundColor Green
    
    $fileSize = (Get-Item "graphql-schema-full.json").Length
    Write-Host "[INFO] File size: $($fileSize) bytes ($([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Cyan
    
    # Analyze schema
    Write-Host ""
    Write-Host "=== Schema Analysis ===" -ForegroundColor Cyan
    
    $schema = $response.data.__schema
    
    Write-Host "Query Type: $($schema.queryType.name)" -ForegroundColor Yellow
    Write-Host "Mutation Type: $($schema.mutationType.name)" -ForegroundColor Yellow
    Write-Host "Subscription Type: $($schema.subscriptionType.name)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Total Types: $($schema.types.Count)" -ForegroundColor Cyan
    
    # Find Query type
    $queryType = $schema.types | Where-Object { $_.name -eq $schema.queryType.name }
    
    if ($queryType) {
        Write-Host ""
        Write-Host "=== Available Queries ===" -ForegroundColor Cyan
        $queryType.fields | Sort-Object name | ForEach-Object {
            Write-Host "  $($_.name)" -ForegroundColor Green
            if ($_.description) {
                Write-Host "    $($_.description)" -ForegroundColor Gray
            }
            if ($_.args.Count -gt 0) {
                Write-Host "    Args: $($_.args.name -join ', ')" -ForegroundColor DarkGray
            }
        }
    }
    
    # Save summary
    $summary = @{
        endpoint = $endpoint
        queryType = $schema.queryType.name
        mutationType = $schema.mutationType.name
        totalTypes = $schema.types.Count
        queries = $queryType.fields | ForEach-Object {
            @{
                name = $_.name
                description = $_.description
                args = $_.args | ForEach-Object { 
                    @{
                        name = $_.name
                        type = $_.type.name
                        required = $_.type.kind -eq "NON_NULL"
                    }
                }
            }
        }
    }
    
    $summary | ConvertTo-Json -Depth 10 | Out-File "graphql-schema-summary.json" -Encoding UTF8
    Write-Host ""
    Write-Host "[OK] Summary saved to: graphql-schema-summary.json" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Failed to download schema: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "[INFO] Details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
    exit 1
}

Write-Host ""
Write-Host "=== Complete ===" -ForegroundColor Cyan
