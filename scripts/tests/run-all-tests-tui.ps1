# ============================================================================
# Sitecore MCP Test Suite - Terminal.Gui TUI Runner
# ============================================================================
# Author: Gary Wenneker
# Date: October 20, 2025
# ============================================================================

. "$PSScriptRoot\..\wrappers\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

# ============================================================================
# Check and install dependencies
# ============================================================================

Write-Host "Checking dependencies..." -ForegroundColor Cyan

# Check NStack
$nstackPath = "$PSScriptRoot\NStack\lib\netstandard2.0\NStack.dll"
if (-not (Test-Path $nstackPath)) {
    Write-Host "  [INSTALL] NStack.Core not found, downloading..." -ForegroundColor Yellow
    if (-not (Test-Path "$PSScriptRoot\NStack")) { 
        New-Item -ItemType Directory -Path "$PSScriptRoot\NStack" | Out-Null 
    }
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/NStack.Core/1.1.1" -OutFile "$PSScriptRoot\NStack.zip"
    Expand-Archive -Path "$PSScriptRoot\NStack.zip" -DestinationPath "$PSScriptRoot\NStack" -Force
    Remove-Item "$PSScriptRoot\NStack.zip" -Force
    Write-Host "  [OK] NStack.Core installed" -ForegroundColor Green
} else {
    Write-Host "  [OK] NStack.Core found" -ForegroundColor Green
}

# Check Terminal.Gui
$terminalGuiPath = "$PSScriptRoot\Terminal.Gui\lib\net472\Terminal.Gui.dll"
if (-not (Test-Path $terminalGuiPath)) {
    Write-Host "  [INSTALL] Terminal.Gui not found, downloading..." -ForegroundColor Yellow
    if (-not (Test-Path "$PSScriptRoot\Terminal.Gui")) { 
        New-Item -ItemType Directory -Path "$PSScriptRoot\Terminal.Gui" | Out-Null 
    }
    Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Terminal.Gui/1.17.1" -OutFile "$PSScriptRoot\Terminal.Gui.zip"
    Expand-Archive -Path "$PSScriptRoot\Terminal.Gui.zip" -DestinationPath "$PSScriptRoot\Terminal.Gui" -Force
    Remove-Item "$PSScriptRoot\Terminal.Gui.zip" -Force
    Write-Host "  [OK] Terminal.Gui installed" -ForegroundColor Green
} else {
    Write-Host "  [OK] Terminal.Gui found" -ForegroundColor Green
}

Write-Host ""

# Load Terminal.Gui dependencies (.NET Framework 4.7.2 for Windows PowerShell)
Add-Type -Path "$PSScriptRoot\NStack\lib\netstandard2.0\NStack.dll"
Add-Type -Path "$PSScriptRoot\Terminal.Gui\lib\net472\Terminal.Gui.dll"

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

# Initialize Terminal.Gui
[Terminal.Gui.Application]::Init()

try {
    # Get top-level view
    $top = [Terminal.Gui.Application]::Top
    
    # Set blue color scheme
    $blueScheme = New-Object Terminal.Gui.ColorScheme
    $white = [Terminal.Gui.Color]::White
    $blue = [Terminal.Gui.Color]::Blue
    $yellow = [Terminal.Gui.Color]::BrightYellow
    $brightCyan = [Terminal.Gui.Color]::BrightCyan
    
    $blueScheme.Normal = [Terminal.Gui.Application]::Driver.MakeAttribute($white, $blue)
    $blueScheme.Focus = [Terminal.Gui.Application]::Driver.MakeAttribute($yellow, $blue)
    $blueScheme.HotNormal = [Terminal.Gui.Application]::Driver.MakeAttribute($brightCyan, $blue)
    $blueScheme.HotFocus = [Terminal.Gui.Application]::Driver.MakeAttribute($yellow, $blue)
    
    # Create main window
    $win = New-Object Terminal.Gui.Window
    $win.Title = "Sitecore MCP Test Suite"
    $win.ColorScheme = $blueScheme
    
    # Create label for instructions
    $instrLabel = New-Object Terminal.Gui.Label
    $instrLabel.Text = "Press R to run tests | Press Q or Esc to quit | Or click RUN TESTS button"
    $instrLabel.X = 1
    $instrLabel.Y = 0
    $instrLabel.ColorScheme = $blueScheme
    $win.Add($instrLabel)
    
    # Create text view for output
    $textView = New-Object Terminal.Gui.TextView
    $textView.X = 1
    $textView.Y = 2
    $textView.Width = [Terminal.Gui.Dim]::Fill(1)
    $textView.Height = [Terminal.Gui.Dim]::Fill(4)
    $textView.ReadOnly = $true
    $textView.ColorScheme = $blueScheme
    $win.Add($textView)
    
    # Build initial display
    $output = [System.Text.StringBuilder]::new()
    $output.AppendLine("=== SITECORE MCP TEST SUITE ===") | Out-Null
    $output.AppendLine("") | Out-Null
    
    foreach ($g in $groups) {
        $output.AppendLine("[$($groups.IndexOf($g) + 1)] $($g.Name)") | Out-Null
        foreach ($t in $g.Tests) {
            $output.AppendLine("    $($t.Name.PadRight(40)) [WAIT]") | Out-Null
        }
        $output.AppendLine("") | Out-Null
    }
    
    $output.AppendLine("") | Out-Null
    $output.AppendLine("=== SUMMARY ===") | Out-Null
    $output.AppendLine("Total: 0 | Passed: 0 | Failed: 0 | Rate: 0%") | Out-Null
    
    $textView.Text = [NStack.ustring]::Make($output.ToString())
    
    # Summary label at bottom
    $summaryLabel = New-Object Terminal.Gui.Label
    $summaryLabel.Text = "Ready to run tests..."
    $summaryLabel.X = 1
    $summaryLabel.Y = [Terminal.Gui.Pos]::AnchorEnd(2)
    $summaryLabel.Width = [Terminal.Gui.Dim]::Fill(1)
    $summaryLabel.ColorScheme = $blueScheme
    $win.Add($summaryLabel)
    
    # Function to run tests
    $runTests = {
        $output.Clear() | Out-Null
        $output.AppendLine("=== SITECORE MCP TEST SUITE ===") | Out-Null
        $output.AppendLine("") | Out-Null
        $output.AppendLine("Running tests...") | Out-Null
        $output.AppendLine("") | Out-Null
        
        $totalPassed = 0
        $totalFailed = 0
        
        foreach ($g in $groups) {
            $output.AppendLine("[$($groups.IndexOf($g) + 1)] $($g.Name)") | Out-Null
            
            foreach ($t in $g.Tests) {
                $summaryLabel.Text = "Running: $($g.Name) - $($t.Name)..."
                $textView.Text = [NStack.ustring]::Make($output.ToString())
                [Terminal.Gui.Application]::Refresh()
                
                # Run test
                try {
                    $scriptPath = Join-Path $PSScriptRoot $t.Script
                    $null = & $scriptPath *>&1
                    $exitCode = $LASTEXITCODE
                    $testOutput = & $scriptPath 2>&1 | Out-String
                    
                    $passedMatch = $testOutput | Select-String -Pattern "Passed:\s*(\d+)" | Select-Object -Last 1
                    $failedMatch = $testOutput | Select-String -Pattern "Failed:\s*(\d+)" | Select-Object -Last 1
                    
                    $passed = if ($passedMatch) { [int]$passedMatch.Matches.Groups[1].Value } else { if ($exitCode -eq 0) { 1 } else { 0 } }
                    $failed = if ($failedMatch) { [int]$failedMatch.Matches.Groups[1].Value } else { if ($exitCode -eq 0) { 0 } else { 1 } }
                } catch {
                    $passed = 0
                    $failed = 1
                }
                
                $totalPassed += $passed
                $totalFailed += $failed
                
                # Update output
                $status = if ($failed -eq 0) { "[PASS] $passed/$($passed+$failed)" } else { "[FAIL] $passed/$($passed+$failed)" }
                $output.AppendLine("    $($t.Name.PadRight(40)) $status") | Out-Null
                
                $textView.Text = [NStack.ustring]::Make($output.ToString())
                [Terminal.Gui.Application]::Refresh()
            }
            $output.AppendLine("") | Out-Null
        }
        
        # Final summary
        $total = $totalPassed + $totalFailed
        $rate = if ($total -gt 0) { [math]::Round(($totalPassed / $total) * 100, 1) } else { 0 }
        
        $output.AppendLine("") | Out-Null
        $output.AppendLine("=== SUMMARY ===") | Out-Null
        $output.AppendLine("Total: $total | Passed: $totalPassed | Failed: $totalFailed | Rate: $rate%") | Out-Null
        
        if ($totalFailed -eq 0) {
            $output.AppendLine("") | Out-Null
            $output.AppendLine("ALL TESTS PASSED!") | Out-Null
        }
        
        $textView.Text = [NStack.ustring]::Make($output.ToString())
        $summaryLabel.Text = "Tests completed! Total: $total | Passed: $totalPassed | Failed: $totalFailed | Rate: $rate%"
        [Terminal.Gui.Application]::Refresh()
    }
    
    # Add run button
    $runButton = New-Object Terminal.Gui.Button
    $runButton.Text = "RUN TESTS"
    $runButton.X = [Terminal.Gui.Pos]::Center()
    $runButton.Y = [Terminal.Gui.Pos]::AnchorEnd(1)
    $runButton.ColorScheme = $blueScheme
    $runButton.add_Clicked({ & $runTests })
    $win.Add($runButton)
    
    # Add keyboard handler to window
    $win.add_KeyPress({
        param($e)
        $keyChar = $e.KeyEvent.KeyValue
        
        # Q or Esc to quit
        if ($keyChar -eq 113 -or $keyChar -eq 81 -or $keyChar -eq 27) {  # q, Q, Esc
            [Terminal.Gui.Application]::RequestStop()
            $e.Handled = $true
        }
        # R to run tests
        elseif ($keyChar -eq 114 -or $keyChar -eq 82) {  # r, R
            & $runTests
            $e.Handled = $true
        }
    })
    
    # Add window to top
    $top.Add($win)
    
    # Add global keyboard handler to application
    [Terminal.Gui.Application]::RootKeyEvent = [System.Func[Terminal.Gui.KeyEvent, bool]] {
        param($keyEvent)
        
        $keyChar = $keyEvent.KeyValue
        
        # Q or Esc to quit
        if ($keyChar -eq 113 -or $keyChar -eq 81 -or $keyChar -eq 27) {  # q, Q, Esc
            [Terminal.Gui.Application]::RequestStop()
            return $true
        }
        # R to run tests
        elseif ($keyChar -eq 114 -or $keyChar -eq 82) {  # r, R
            & $runTests
            return $true
        }
        
        return $false
    }
    
    # Run application (no arguments for v1.x)
    [Terminal.Gui.Application]::Run()
    
} finally {
    [Terminal.Gui.Application]::Shutdown()
}
