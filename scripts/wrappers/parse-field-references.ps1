Write-Host "[DEPRECATED] Use: scripts/tools/parse-field-references.ps1" -ForegroundColor Yellow
& "$PSScriptRoot\..\tools\parse-field-references.ps1"
exit $LASTEXITCODE
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "       Sample Data Test (Fallback)" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        $sampleFields = @(
            @{ name = "RelatedItem"; value = "{CFFDFAFA-317F-4E54-9898-8D16E6BB1E68}" }
            @{ name = "ItemPath"; value = "/sitecore/content/Home/Products" }
            @{ name = "MultiList"; value = "{12345678-1234-1234-1234-123456789012}|{ABCDEFAB-ABCD-ABCD-ABCD-ABCDEFABCDEF}" }
            @{ name = "Text"; value = "Just regular text with no references" }
            @{ name = "Mixed"; value = "Item at /sitecore/content/Data with ID {11111111-1111-1111-1111-111111111111}" }
        )
        
        $testRefs = Parse-FieldReferences -Fields $sampleFields
    }
} catch {
    Write-Host "[ERROR] Failed to query Sitecore: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[INFO] Falling back to sample data test" -ForegroundColor Yellow
    Write-Host ""
    
    # Fallback to sample data
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       Sample Data Test (Fallback)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $sampleFields = @(
        @{ name = "RelatedItem"; value = "{CFFDFAFA-317F-4E54-9898-8D16E6BB1E68}" }
        @{ name = "ItemPath"; value = "/sitecore/content/Home/Products" }
        @{ name = "MultiList"; value = "{12345678-1234-1234-1234-123456789012}|{ABCDEFAB-ABCD-ABCD-ABCD-ABCDEFABCDEF}" }
        @{ name = "Text"; value = "Just regular text with no references" }
        @{ name = "Mixed"; value = "Item at /sitecore/content/Data with ID {11111111-1111-1111-1111-111111111111}" }
    )
    
    $testRefs = Parse-FieldReferences -Fields $sampleFields
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "           Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "GUID References: $(@($testRefs.GuidReferences).Count)" -ForegroundColor Yellow
foreach ($ref in $testRefs.GuidReferences) {
    Write-Host "  Field: $($ref.Field)" -ForegroundColor Gray
    Write-Host "  GUID: $($ref.Guid)" -ForegroundColor Cyan
    Write-Host "  Multi-Value: $($ref.IsMultiValue)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Path References: $(@($testRefs.PathReferences).Count)" -ForegroundColor Yellow
foreach ($ref in $testRefs.PathReferences) {
    Write-Host "  Field: $($ref.Field)" -ForegroundColor Gray
    Write-Host "  Path: $($ref.Path)" -ForegroundColor Cyan
    Write-Host "  Multi-Value: $($ref.IsMultiValue)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Multi-Value References: $(@($testRefs.MultiValueReferences).Count)" -ForegroundColor Yellow
foreach ($ref in $testRefs.MultiValueReferences) {
    Write-Host "  Field: $($ref.Field)" -ForegroundColor Gray
    Write-Host "  GUID: $($ref.Guid)" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "         Test Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[INFO] Usage in other scripts:" -ForegroundColor Yellow
Write-Host "  . '$PSScriptRoot\parse-field-references.ps1'" -ForegroundColor Gray
Write-Host ""
Write-Host "[NOTE] For production use:" -ForegroundColor Yellow
Write-Host "  1. Use MCP sitecore_get_item_fields tool" -ForegroundColor Gray
Write-Host "  2. Pass result.fields to Parse-FieldReferences" -ForegroundColor Gray
Write-Host "  3. Process refs.GuidReferences and refs.PathReferences" -ForegroundColor Gray
Write-Host ""
