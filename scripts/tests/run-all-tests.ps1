# ============================================================================
# Sitecore MCP Test Suite - Console Runner
# ============================================================================
# Complete test suite with progress bars and grouped execution
# Author: Gary Wenneker
# Date: October 19, 2025
# ============================================================================

# Load environment variables
. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\..env"

# ============================================================================
# UI Helper Functions
# ============================================================================

function Write-Header {
    param([string]$Title)
    Clear-Host
    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host "                                                                         " -ForegroundColor Cyan
    Write-Host "          SITECORE MCP TEST SUITE - COMPREHENSIVE RUNNER                " -ForegroundColor Cyan
    Write-Host "                                                                         " -ForegroundColor Cyan
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host ""
}

function Write-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity,
        [string]$Status
    )
    
    $percent = [math]::Round(($Current / $Total) * 100, 0)
    $barLength = 50
    $filledLength = [math]::Round(($percent / 100) * $barLength)
    $emptyLength = $barLength - $filledLength
    
    $bar = "#" * $filledLength + "." * $emptyLength
    
    Write-Host -NoNewline "`r  ["
    Write-Host -NoNewline $bar -ForegroundColor Green
    Write-Host -NoNewline "] $percent% "
    Write-Host -NoNewline "($Current/$Total) " -ForegroundColor Yellow
    Write-Host -NoNewline $Status -ForegroundColor Gray
}

function Write-GroupHeader {
    param([string]$GroupName, [int]$TestCount)
    Write-Host ""
    Write-Host "-----------------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  " -ForegroundColor DarkCyan -NoNewline
    Write-Host $GroupName -ForegroundColor White
    Write-Host "  " -ForegroundColor DarkCyan -NoNewline
    Write-Host "Tests: $TestCount" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-TestResult {
    param(
        [string]$TestName,
        [int]$Passed,
        [int]$Failed,
        [double]$Duration
    )
    
    $total = $Passed + $Failed
    $status = if ($Failed -eq 0) { "[PASS]" } else { "[FAIL]" }
    $statusColor = if ($Failed -eq 0) { "Green" } else { "Red" }
    
    Write-Host "  " -NoNewline
    Write-Host $status.PadRight(8) -ForegroundColor $statusColor -NoNewline
    Write-Host $TestName.PadRight(40) -ForegroundColor White -NoNewline
    Write-Host "$Passed/$total".PadLeft(8) -ForegroundColor $(if ($Failed -eq 0) { "Green" } else { "Yellow" }) -NoNewline
    Write-Host "  $([math]::Round($Duration, 2))s".PadLeft(8) -ForegroundColor Gray
}

function Write-GroupSummary {
    param([int]$Passed, [int]$Failed, [double]$Duration)
    
    $total = $Passed + $Failed
    $successRate = if ($total -gt 0) { [math]::Round(($Passed / $total) * 100, 1) } else { 0 }
    
    Write-Host ""
    Write-Host "  -------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Group Summary: " -ForegroundColor Cyan -NoNewline
    Write-Host "$Passed passed, " -ForegroundColor Green -NoNewline
    Write-Host "$Failed failed" -ForegroundColor $(if ($Failed -eq 0) { "Green" } else { "Red" }) -NoNewline
    Write-Host "  |  " -NoNewline
    $rateText = "$successRate" + "% success"
    Write-Host $rateText -ForegroundColor $(if ($successRate -eq 100) { "Green" } else { "Yellow" }) -NoNewline
    Write-Host "  |  " -NoNewline
    $durationText = [math]::Round($Duration, 2).ToString() + "s"
    Write-Host $durationText -ForegroundColor Gray
    Write-Host ""
}

function Write-FinalSummary {
    param(
        [hashtable]$Results,
        [double]$TotalDuration
    )
    
    $totalTests = 0
    $totalPassed = 0
    $totalFailed = 0
    
    foreach ($group in $Results.Keys) {
        $totalPassed += $Results[$group].Passed
        $totalFailed += $Results[$group].Failed
        $totalTests += ($Results[$group].Passed + $Results[$group].Failed)
    }
    
    $successRate = if ($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 1) } else { 0 }
    
    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host "                        FINAL TEST RESULTS                               " -ForegroundColor Cyan
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Total Tests:     " -ForegroundColor White -NoNewline
    Write-Host $totalTests -ForegroundColor Yellow
    Write-Host "  Passed:          " -ForegroundColor White -NoNewline
    Write-Host $totalPassed -ForegroundColor Green
    Write-Host "  Failed:          " -ForegroundColor White -NoNewline
    Write-Host $totalFailed -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })
    Write-Host "  Success Rate:    " -ForegroundColor White -NoNewline
    Write-Host "$successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } else { "Yellow" })
    Write-Host "  Total Duration:  " -ForegroundColor White -NoNewline
    Write-Host "$([math]::Round($TotalDuration, 2))s" -ForegroundColor Gray
    Write-Host ""
    
    if ($totalFailed -eq 0) {
        Write-Host "  ===================================================================" -ForegroundColor Green
        Write-Host "                     ALL TESTS PASSED!                             " -ForegroundColor Green
        Write-Host "  ===================================================================" -ForegroundColor Green
    } else {
        Write-Host "  ===================================================================" -ForegroundColor Red
        Write-Host "              SOME TESTS FAILED - REVIEW REQUIRED                  " -ForegroundColor Red
        Write-Host "  ===================================================================" -ForegroundColor Red
    }
    Write-Host ""
}

# ============================================================================
# Test Execution Function
# ============================================================================

function Invoke-TestScript {
    param(
        [string]$ScriptPath,
        [string]$TestName
    )
    
    $startTime = Get-Date
    
    try {
        # Execute test and capture output (suppress all output)
        $null = & $ScriptPath 2>&1
        $exitCode = $LASTEXITCODE
        
        # Read the last few lines of output for result parsing
        $output = & $ScriptPath 2>&1 | Out-String
        
        # Parse results from output
        $passedMatch = $output | Select-String -Pattern "Passed:\s*(\d+)" | Select-Object -Last 1
        $failedMatch = $output | Select-String -Pattern "Failed:\s*(\d+)" | Select-Object -Last 1
        
        $passed = if ($passedMatch) { [int]$passedMatch.Matches.Groups[1].Value } else { 0 }
        $failed = if ($failedMatch) { [int]$failedMatch.Matches.Groups[1].Value } else { 0 }
        
        # If no explicit counts, use exit code
        if ($passed -eq 0 -and $failed -eq 0) {
            if ($exitCode -eq 0) {
                $passed = 1
                $failed = 0
            } else {
                $passed = 0
                $failed = $exitCode
            }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        return @{
            Passed = $passed
            Failed = $failed
            Duration = $duration
            ExitCode = $exitCode
        }
    }
    catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        return @{
            Passed = 0
            Failed = 1
            Duration = $duration
            ExitCode = 1
        }
    }
}

# ============================================================================
# Test Groups Definition
# ============================================================================

$testGroups = @{
    "Basic Queries" = @(
        @{ Name = "Get Item"; Script = "test-mcp-get-item.ps1" }
        @{ Name = "Get Children"; Script = "test-mcp-get-children.ps1" }
        @{ Name = "Get Item Fields"; Script = "test-mcp-get-item-fields.ps1" }
        @{ Name = "Search Items"; Script = "test-mcp-search.ps1" }
        @{ Name = "Get Template"; Script = "test-mcp-get-template.ps1" }
        @{ Name = "Execute Query"; Script = "test-mcp-query.ps1" }
    )
    "Navigation & Hierarchy" = @(
        @{ Name = "Get Parent"; Script = "test-mcp-get-parent.ps1" }
        @{ Name = "Get Ancestors"; Script = "test-mcp-get-ancestors.ps1" }
        @{ Name = "Get Item Versions"; Script = "test-mcp-get-item-versions.ps1" }
        @{ Name = "Get Statistics"; Script = "test-mcp-get-item-with-statistics.ps1" }
    )
    "Advanced Search & Discovery" = @(
        @{ Name = "Search Paginated"; Script = "test-mcp-search-paginated.ps1" }
        @{ Name = "Get Layout"; Script = "test-mcp-get-layout.ps1" }
        @{ Name = "Get Sites"; Script = "test-mcp-get-sites.ps1" }
        @{ Name = "Get Templates"; Script = "test-mcp-get-templates.ps1" }
        @{ Name = "Discover Dependencies"; Script = "test-mcp-discover-item-dependencies.ps1" }
    )
    "Utilities & Extensions" = @(
        @{ Name = "Natural Language Command"; Script = "test-mcp-command.ps1" }
        @{ Name = "Schema Scanner"; Script = "test-mcp-scan-schema.ps1" }
    )
}

# ============================================================================
# Main Execution
# ============================================================================

Write-Header "Initializing Test Suite..."
Start-Sleep -Milliseconds 500

$totalStartTime = Get-Date
$globalResults = @{}

# Calculate total test count
$totalTestScripts = 0
foreach ($group in $testGroups.Keys) {
    $totalTestScripts += $testGroups[$group].Count
}

$currentTestIndex = 0

# Execute each group
foreach ($groupName in $testGroups.Keys | Sort-Object) {
    $groupTests = $testGroups[$groupName]
    
    Write-Header "Running Group: $groupName"
    Write-GroupHeader -GroupName $groupName -TestCount $groupTests.Count
    
    $groupPassed = 0
    $groupFailed = 0
    $groupStartTime = Get-Date
    
    foreach ($test in $groupTests) {
        $currentTestIndex++
        
        # Update progress bar
        Write-ProgressBar -Current $currentTestIndex -Total $totalTestScripts -Activity "Running Tests" -Status $test.Name
        Start-Sleep -Milliseconds 200
        
        # Execute test
        $scriptPath = Join-Path $PSScriptRoot $test.Script
        $result = Invoke-TestScript -ScriptPath $scriptPath -TestName $test.Name
        
        # Update group counters
        $groupPassed += $result.Passed
        $groupFailed += $result.Failed
        
        # Clear progress bar line
        Write-Host "`r" -NoNewline
        Write-Host (" " * 120) -NoNewline
        Write-Host "`r" -NoNewline
        
        # Show test result
        Write-TestResult -TestName $test.Name -Passed $result.Passed -Failed $result.Failed -Duration $result.Duration
        
        Start-Sleep -Milliseconds 50
    }
    
    $groupEndTime = Get-Date
    $groupDuration = ($groupEndTime - $groupStartTime).TotalSeconds
    
    # Store group results
    $globalResults[$groupName] = @{
        Passed = $groupPassed
        Failed = $groupFailed
        Duration = $groupDuration
    }
    
    # Show group summary
    Write-GroupSummary -Passed $groupPassed -Failed $groupFailed -Duration $groupDuration
    
    Start-Sleep -Milliseconds 300
}

$totalEndTime = Get-Date
$totalDuration = ($totalEndTime - $totalStartTime).TotalSeconds

# Show final summary
Write-Header "Test Suite Complete"
Write-FinalSummary -Results $globalResults -TotalDuration $totalDuration

# Detailed breakdown by group
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "                      RESULTS BY GROUP                                   " -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($groupName in $testGroups.Keys | Sort-Object) {
    $result = $globalResults[$groupName]
    $total = $result.Passed + $result.Failed
    $rate = if ($total -gt 0) { [math]::Round(($result.Passed / $total) * 100, 1) } else { 0 }
    
    Write-Host "  $groupName".PadRight(35) -ForegroundColor White -NoNewline
    Write-Host "$($result.Passed)/$total".PadLeft(10) -ForegroundColor $(if ($result.Failed -eq 0) { "Green" } else { "Yellow" }) -NoNewline
    Write-Host "  $rate%".PadLeft(8) -ForegroundColor $(if ($rate -eq 100) { "Green" } else { "Yellow" }) -NoNewline
    Write-Host "  $([math]::Round($result.Duration, 2))s".PadLeft(10) -ForegroundColor Gray
}

Write-Host ""
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ""

# Set exit code based on results
$totalFailed = ($globalResults.Values | ForEach-Object { $_.Failed } | Measure-Object -Sum).Sum
exit $totalFailed
