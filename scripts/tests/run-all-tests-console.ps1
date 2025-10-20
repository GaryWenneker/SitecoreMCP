# ============================================================================
# Sitecore MCP Test Suite - Console Runner (Simple, No Scroll)
# ============================================================================

. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\\..\\..\.env"

$width = 100
$height = 40

try {
    $size = New-Object System.Management.Automation.Host.Size($width, $height)
    $Host.UI.RawUI.BufferSize = $size
    $Host.UI.RawUI.WindowSize = $size
} catch {}

$Host.UI.RawUI.WindowTitle = "Sitecore MCP Test Suite"
Clear-Host

$groups = @(
    @{ Name = "Basic Queries"; Tests = @(
        @{ Name = "Get Item"; Script = "test-mcp-get-item.ps1" }
        @{ Name = "Get Children"; Script = "test-mcp-get-children.ps1" }
        @{ Name = "Get Item Fields"; Script = "test-mcp-get-item-fields.ps1" }
        @{ Name = "Search Items"; Script = "test-mcp-search.ps1" }
        @{ Name = "Get Template"; Script = "test-mcp-get-template.ps1" }
        @{ Name = "Execute Query"; Script = "test-mcp-query.ps1" }
    )}
    @{ Name = "Navigation & Hierarchy"; Tests = @(
        @{ Name = "Get Parent"; Script = "test-mcp-get-parent.ps1" }
        @{ Name = "Get Ancestors"; Script = "test-mcp-get-ancestors.ps1" }
        @{ Name = "Get Versions"; Script = "test-mcp-get-item-versions.ps1" }
        @{ Name = "Get Statistics"; Script = "test-mcp-get-item-with-statistics.ps1" }
    )}
    @{ Name = "Advanced Search"; Tests = @(
        @{ Name = "Search Paginated"; Script = "test-mcp-search-paginated.ps1" }
        @{ Name = "Get Layout"; Script = "test-mcp-get-layout.ps1" }
        @{ Name = "Get Sites"; Script = "test-mcp-get-sites.ps1" }
        @{ Name = "Get Templates"; Script = "test-mcp-get-templates.ps1" }
        @{ Name = "Discover Dependencies"; Script = "test-mcp-discover-item-dependencies.ps1" }
    )}
    @{ Name = "Utilities"; Tests = @(
        @{ Name = "NL Command"; Script = "test-mcp-command.ps1" }
        @{ Name = "Schema Scan"; Script = "test-mcp-scan-schema.ps1" }
    )}
)

function Write-Line {
    param([int]$Y, [string]$Text)
    
    # Ensure text fits exactly in width
    $paddedText = $Text.PadRight($width)
    if ($paddedText.Length -gt $width) {
        $paddedText = $paddedText.Substring(0, $width)
    }
    
    # Move cursor and write in one operation
    $pos = $Host.UI.RawUI.CursorPosition
    $pos.X = 0
    $pos.Y = $Y
    $Host.UI.RawUI.CursorPosition = $pos
    
    # Write without newline
    [Console]::Write($paddedText)
}

Write-Line 0 ("=" * $width)
Write-Line 1 "SITECORE MCP TEST SUITE".PadLeft(62)
Write-Line 2 ("=" * $width)
Write-Line 3 ""
Write-Line 4 "Status: Initializing..."

$line = 6
foreach ($g in $groups) {
    Write-Line $line "[$($groups.IndexOf($g) + 1)] $($g.Name)"
    $line++
    foreach ($t in $g.Tests) {
        Write-Line $line "    $($t.Name.PadRight(30)) ..."
        $line++
    }
    $line++
}

$summaryLine = $height - 8
Write-Line $summaryLine ("-" * $width)
Write-Line ($summaryLine + 1) "SUMMARY:"
Write-Line ($summaryLine + 3) "  Total Tests:     0"
Write-Line ($summaryLine + 4) "  Passed:          0"
Write-Line ($summaryLine + 5) "  Failed:          0"
Write-Line ($summaryLine + 6) "  Success Rate:    0%"
Write-Line ($height - 1) ("=" * $width)

Start-Sleep -Milliseconds 500

$totalPassed = 0
$totalFailed = 0
$startTime = Get-Date

$testLine = 7
foreach ($g in $groups) {
    $testLine++
    foreach ($t in $g.Tests) {
        Write-Line 4 "Status: Running $($g.Name) - $($t.Name)..."
        
        $ts = Get-Date
        try {
            $null = & (Join-Path $PSScriptRoot $t.Script) *>&1
            $exit = $LASTEXITCODE
            $out = & (Join-Path $PSScriptRoot $t.Script) 2>&1 | Out-String
            
            $pm = $out | Select-String -Pattern "Passed:\s*(\d+)" | Select-Object -Last 1
            $fm = $out | Select-String -Pattern "Failed:\s*(\d+)" | Select-Object -Last 1
            
            $p = if ($pm) { [int]$pm.Matches.Groups[1].Value } else { if ($exit -eq 0) { 1 } else { 0 } }
            $f = if ($fm) { [int]$fm.Matches.Groups[1].Value } else { if ($exit -eq 0) { 0 } else { 1 } }
        } catch {
            $p = 0
            $f = 1
        }
        
        $dur = ((Get-Date) - $ts).TotalSeconds
        $totalPassed += $p
        $totalFailed += $f
        
        $status = if ($f -eq 0) { "[PASS] $p/$($p+$f) ($([math]::Round($dur,1))s)" } else { "[FAIL] $p/$($p+$f) ($([math]::Round($dur,1))s)" }
        Write-Line $testLine "    $($t.Name.PadRight(30)) $status"
        
        $total = $totalPassed + $totalFailed
        $rate = if ($total -gt 0) { [math]::Round(($totalPassed / $total) * 100, 1) } else { 0 }
        Write-Line ($summaryLine + 3) "  Total Tests:     $total"
        Write-Line ($summaryLine + 4) "  Passed:          $totalPassed"
        Write-Line ($summaryLine + 5) "  Failed:          $totalFailed"
        Write-Line ($summaryLine + 6) "  Success Rate:    $rate%"
        
        $testLine++
    }
    $testLine++
}

$duration = ((Get-Date) - $startTime).TotalSeconds
Write-Line 4 "Status: All tests completed in $([math]::Round($duration,1))s"

$msg = if ($totalFailed -eq 0) { "ALL TESTS PASSED! Press any key to exit..." } else { "TESTS FAILED! Press any key to exit..." }
Write-Line ($height - 2) "  $msg"

$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit $totalFailed

