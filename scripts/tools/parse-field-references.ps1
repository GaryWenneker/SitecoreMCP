# Field Reference Parser
# Parses Sitecore field values for item references (GUIDs, paths)

# Load environment variables from .env file (canonical location)
. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Write-Host "" 
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Field Reference Parser" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Parse-FieldReferences {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Fields
    )
    
    $references = @{
        GuidReferences = @()
        PathReferences = @()
        MultiValueReferences = @()
    }
    
    # GUID pattern: {XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
    $guidPattern = '\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\}'
    
    # Path pattern: /sitecore/...
    $pathPattern = '(/sitecore/[^\s\|\}]+)'
    
    foreach ($field in $Fields) {
        if (-not $field.value) { continue }
        
        $value = $field.value
        
        Write-Host "[FIELD] $($field.name)" -ForegroundColor Yellow
        Write-Host "  Value: $($value.Substring(0, [Math]::Min(100, $value.Length)))$(if ($value.Length -gt 100) { '...' })" -ForegroundColor Gray
        
        # Check for GUID references
        $guidMatches = [regex]::Matches($value, $guidPattern)
        if ($guidMatches.Count -gt 0) {
            Write-Host "  [GUID] Found $($guidMatches.Count) GUID reference(s)" -ForegroundColor Green
            
            foreach ($match in $guidMatches) {
                $guid = $match.Value
                Write-Host "    -> $guid" -ForegroundColor Cyan
                
                $references.GuidReferences += @{
                    Field = $field.name
                    Guid = $guid
                    IsMultiValue = $guidMatches.Count -gt 1
                }
            }
        }
        
        # Check for path references
        $pathMatches = [regex]::Matches($value, $pathPattern)
        if ($pathMatches.Count -gt 0) {
            Write-Host "  [PATH] Found $($pathMatches.Count) path reference(s)" -ForegroundColor Green
            
            foreach ($match in $pathMatches) {
                $path = $match.Groups[1].Value
                Write-Host "    -> $path" -ForegroundColor Cyan
                
                $references.PathReferences += @{
                    Field = $field.name
                    Path = $path
                    IsMultiValue = $pathMatches.Count -gt 1
                }
            }
        }
        
        # Check for multi-value format (pipe-separated GUIDs)
        if ($value -match '\|' -and $value -match $guidPattern) {
            Write-Host "  [MULTI] Multi-value field detected" -ForegroundColor Magenta
            $ids = $value -split '\|'
            
            foreach ($id in $ids) {
                if ($id -match $guidPattern) {
                    $references.MultiValueReferences += @{
                        Field = $field.name
                        Guid = $id
                    }
                }
            }
        }
        
        if ($guidMatches.Count -eq 0 -and $pathMatches.Count -eq 0) {
            Write-Host "  [INFO] No references found" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    return $references
}

# Helper usage notes
Write-Host "[INFO] Usage in other scripts:" -ForegroundColor Yellow
Write-Host "  . '$PSScriptRoot\parse-field-references.ps1'" -ForegroundColor Gray
Write-Host "  `$refs = Parse-FieldReferences -Fields `$item.fields" -ForegroundColor Gray
Write-Host ""
