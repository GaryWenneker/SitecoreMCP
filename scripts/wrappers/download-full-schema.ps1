Write-Host "[DEPRECATED] Use: scripts/schema/download-full-schema.ps1" -ForegroundColor Yellow
& "$PSScriptRoot\..\schema\download-full-schema.ps1"
exit $LASTEXITCODE
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
