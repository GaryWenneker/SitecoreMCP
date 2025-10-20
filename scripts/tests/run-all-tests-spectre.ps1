# ============================================================================
# Sitecore MCP Test Suite - Spectre.Console Runner
# ============================================================================
# Author: Gary Wenneker
# Date: October 19, 2025
# ============================================================================

. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\..env"

# Load Spectre.Console (netstandard2.0 for compatibility)
Add-Type -Path "$PSScriptRoot\Spectre.Console\lib\netstandard2.0\Spectre.Console.dll"

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

# Create table
$table = [Spectre.Console.Table]::new()
$table.Border = [Spectre.Console.TableBorder]::Rounded
$table.Title = [Spectre.Console.TableTitle]::new("[yellow]SITECORE MCP TEST SUITE[/]")

# Add columns
$table.AddColumn([Spectre.Console.TableColumn]::new("[cyan]Group[/]")) | Out-Null
$table.AddColumn([Spectre.Console.TableColumn]::new("[cyan]Test[/]")) | Out-Null
$table.AddColumn([Spectre.Console.TableColumn]::new("[cyan]Status[/]")) | Out-Null
$table.AddColumn([Spectre.Console.TableColumn]::new("[cyan]Time[/]")) | Out-Null

# Add rows for all tests
foreach ($g in $groups) {
    $isFirst = $true
    foreach ($t in $g.Tests) {
        $groupName = if ($isFirst) { $g.Name } else { "" }
        $table.AddRow($groupName, $t.Name, "[grey]WAITING[/]", "") | Out-Null
        $isFirst = $false
    }
}

# Initial display
[Spectre.Console.AnsiConsole]::Clear()
[Spectre.Console.AnsiConsole]::Write($table)

# Run tests with live updates
$totalPassed = 0
$totalFailed = 0
$startTime = Get-Date
$rowIndex = 0

foreach ($g in $groups) {
    foreach ($t in $g.Tests) {
        # Update status to RUNNING
        $table.Rows[$rowIndex].Item(2) = [Spectre.Console.Markup]::new("[yellow]RUNNING[/]")
        [Spectre.Console.AnsiConsole]::Clear()
        [Spectre.Console.AnsiConsole]::Write($table)
        
        # Run test
        $testStart = Get-Date
        try {
            $scriptPath = Join-Path $PSScriptRoot $t.Script
            $null = & $scriptPath *>&1
            $exitCode = $LASTEXITCODE
            $output = & $scriptPath 2>&1 | Out-String
            
            $passedMatch = $output | Select-String -Pattern "Passed:\s*(\d+)" | Select-Object -Last 1
            $failedMatch = $output | Select-String -Pattern "Failed:\s*(\d+)" | Select-Object -Last 1
            
            $passed = if ($passedMatch) { [int]$passedMatch.Matches.Groups[1].Value } else { if ($exitCode -eq 0) { 1 } else { 0 } }
            $failed = if ($failedMatch) { [int]$failedMatch.Matches.Groups[1].Value } else { if ($exitCode -eq 0) { 0 } else { 1 } }
        } catch {
            $passed = 0
            $failed = 1
        }
        
        $duration = ((Get-Date) - $testStart).TotalSeconds
        $totalPassed += $passed
        $totalFailed += $failed
        
        # Update result
        if ($failed -eq 0) {
            $table.Rows[$rowIndex].Item(2) = [Spectre.Console.Markup]::new("[green]PASS[/]")
            $table.Rows[$rowIndex].Item(3) = [Spectre.Console.Markup]::new("$([math]::Round($duration,1))s")
        } else {
            $table.Rows[$rowIndex].Item(2) = [Spectre.Console.Markup]::new("[red]FAIL[/]")
            $table.Rows[$rowIndex].Item(3) = [Spectre.Console.Markup]::new("$([math]::Round($duration,1))s")
        }
        
        [Spectre.Console.AnsiConsole]::Clear()
        [Spectre.Console.AnsiConsole]::Write($table)
        
        $rowIndex++
    }
}

# Summary
$duration = ((Get-Date) - $startTime).TotalSeconds
$total = $totalPassed + $totalFailed
$rate = if ($total -gt 0) { [math]::Round(($totalPassed / $total) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Total Tests:     $total"
Write-Host "Passed:          " -NoNewline
Write-Host $totalPassed -ForegroundColor Green
Write-Host "Failed:          " -NoNewline
Write-Host $totalFailed -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })
Write-Host "Success Rate:    $rate%"
Write-Host "Duration:        $([math]::Round($duration,1))s"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($totalFailed -eq 0) {
    Write-Host "ALL TESTS PASSED! Press any key to exit..." -ForegroundColor Green
} else {
    Write-Host "TESTS FAILED! Press any key to exit..." -ForegroundColor Red
}

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit $totalFailed
