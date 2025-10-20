# ============================================================================
# Sitecore MCP Test Suite - Console Runner (Module-Based)
# ============================================================================
# Author: Gary Wenneker
# Date: October 19, 2025
# ============================================================================

. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

Import-Module "$PSScriptRoot\ConsoleUI.psm1" -Force

# Test groups
$groups = @(
    @{ 
        Name = "Basic Queries"
        Tests = @(
            @{ Name = "Get Item"; Script = "test-mcp-get-item.ps1" }
            @{ Name = "Get Children"; Script = "test-mcp-get-children.ps1" }
            @{ Name = "Get Item Fields"; Script = "test-mcp-get-item-fields.ps1" }
            @{ Name = "Search Items"; Script = "test-mcp-search.ps1" }
            @{ Name = "Get Template"; Script = "test-mcp-get-template.ps1" }
            @{ Name = "Execute Query"; Script = "test-mcp-query.ps1" }
        )
    }
    @{ 
        Name = "Navigation & Hierarchy"
        Tests = @(
            @{ Name = "Get Parent"; Script = "test-mcp-get-parent.ps1" }
            @{ Name = "Get Ancestors"; Script = "test-mcp-get-ancestors.ps1" }
            @{ Name = "Get Versions"; Script = "test-mcp-get-item-versions.ps1" }
            @{ Name = "Get Statistics"; Script = "test-mcp-get-item-with-statistics.ps1" }
        )
    }
    @{ 
        Name = "Advanced Search"
        Tests = @(
            @{ Name = "Search Paginated"; Script = "test-mcp-search-paginated.ps1" }
            @{ Name = "Get Layout"; Script = "test-mcp-get-layout.ps1" }
            @{ Name = "Get Sites"; Script = "test-mcp-get-sites.ps1" }
            @{ Name = "Get Templates"; Script = "test-mcp-get-templates.ps1" }
            @{ Name = "Discover Dependencies"; Script = "test-mcp-discover-item-dependencies.ps1" }
        )
    }
    @{ 
        Name = "Utilities"
        Tests = @(
            @{ Name = "NL Command"; Script = "test-mcp-command.ps1" }
            @{ Name = "Schema Scan"; Script = "test-mcp-scan-schema.ps1" }
        )
    }
)

# Test runner scriptblock
$testRunner = {
    param($Group, $Test)
    
    $scriptPath = Join-Path $PSScriptRoot $Test.Script
    
    try {
        $null = & $scriptPath *>&1
        $exitCode = $LASTEXITCODE
        $output = & $scriptPath 2>&1 | Out-String
        
        $passedMatch = $output | Select-String -Pattern "Passed:\s*(\d+)" | Select-Object -Last 1
        $failedMatch = $output | Select-String -Pattern "Failed:\s*(\d+)" | Select-Object -Last 1
        
        $passed = if ($passedMatch) { [int]$passedMatch.Matches.Groups[1].Value } else { if ($exitCode -eq 0) { 1 } else { 0 } }
        $failed = if ($failedMatch) { [int]$failedMatch.Matches.Groups[1].Value } else { if ($exitCode -eq 0) { 0 } else { 1 } }
        
        return @{ Passed = $passed; Failed = $failed }
    } catch {
        return @{ Passed = 0; Failed = 1 }
    }
}

# Run tests with progress table
$result = Show-ProgressTable -Title "SITECORE MCP TEST SUITE" -Groups $groups -TestRunner $testRunner

# Final message
Write-Host ""
if ($result.Failed -eq 0) {
    Write-Host "ALL TESTS PASSED! Press any key to exit..." -ForegroundColor Green
} else {
    Write-Host "TESTS FAILED! Press any key to exit..." -ForegroundColor Red
}

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit $result.Failed
