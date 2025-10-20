# ============================================================================
# ConsoleUI Module - Simple Console Display (No Classes)
# ============================================================================
# Author: Gary Wenneker
# Date: October 19, 2025
# ============================================================================

function Write-ColorLine {
    param([int]$Y, [string]$Text, [int]$Width = 100)
    
    # Move cursor to position
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $Y)
    
    # Pad text to exact width
    if ($Text.Length -gt $Width) {
        $paddedText = $Text.Substring(0, $Width)
    } else {
        $paddedText = $Text.PadRight($Width)
    }
    
    # Color coding with NO newline
    if ($Text -like "*[PASS]*") {
        Write-Host $paddedText -ForegroundColor Green -NoNewline
    } elseif ($Text -like "*[FAIL]*") {
        Write-Host $paddedText -ForegroundColor Red -NoNewline
    } elseif ($Text -like "*[RUNNING]*") {
        Write-Host $paddedText -ForegroundColor Yellow -NoNewline
    } elseif ($Text -like "*[WAIT]*") {
        Write-Host $paddedText -ForegroundColor Gray -NoNewline
    } elseif ($Text -match "^\[") {
        Write-Host $paddedText -ForegroundColor Cyan -NoNewline
    } else {
        Write-Host $paddedText -NoNewline
    }
    
    # Force cursor back to start of line to prevent newline
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates(0, $Y)
}

function Show-ProgressTable {
    param(
        [string]$Title,
        [hashtable[]]$Groups,
        [scriptblock]$TestRunner
    )
    
    $width = 100
    Clear-Host
    
    # Build display structure
    $lines = @()
    $lines += "Status: Initializing..."
    $lines += ""
    
    $testIndex = @{}
    $lineIndex = 2
    
    foreach ($g in $Groups) {
        $groupNum = $Groups.IndexOf($g) + 1
        $lines += "[$groupNum] $($g.Name)"
        $lineIndex++
        
        foreach ($t in $g.Tests) {
            $testIndex["$($g.Name)::$($t.Name)"] = $lineIndex
            $lines += "    $($t.Name.PadRight(30)) [WAIT]"
            $lineIndex++
        }
        
        $lines += ""
        $lineIndex++
    }
    
    # Summary section
    $summaryStart = $lineIndex
    $lines += ("-" * $width)
    $lines += "SUMMARY:"
    $lines += ""
    $lines += "  Total Tests:     0"
    $lines += "  Passed:          0"
    $lines += "  Failed:          0"
    $lines += "  Success Rate:    0%"
    
    # Initial render
    Write-Host ""
    Write-Host ("=" * $width) -ForegroundColor Cyan
    Write-Host $Title.PadLeft(($width + $Title.Length) / 2) -ForegroundColor Yellow
    Write-Host ("=" * $width) -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        Write-ColorLine -Y ($i + 4) -Text $lines[$i] -Width $width
    }
    
    Write-Host ""
    Write-Host ("=" * $width) -ForegroundColor Cyan
    
    # Run tests
    $totalPassed = 0
    $totalFailed = 0
    $startTime = Get-Date
    
    foreach ($g in $Groups) {
        foreach ($t in $g.Tests) {
            # Update status line
            $lines[0] = "Status: Running $($g.Name) - $($t.Name)..."
            Write-ColorLine -Y 4 -Text $lines[0] -Width $width
            
            # Update test line to RUNNING
            $idx = $testIndex["$($g.Name)::$($t.Name)"]
            $lines[$idx] = "    $($t.Name.PadRight(30)) [RUNNING]"
            Write-ColorLine -Y ($idx + 4) -Text $lines[$idx] -Width $width
            
            # Run test
            $testStart = Get-Date
            $result = & $TestRunner -Group $g -Test $t
            $duration = ((Get-Date) - $testStart).TotalSeconds
            
            $totalPassed += $result.Passed
            $totalFailed += $result.Failed
            
            # Update test result
            if ($result.Failed -eq 0) {
                $status = "[PASS] $($result.Passed)/$($result.Passed + $result.Failed) ($([math]::Round($duration,1))s)"
            } else {
                $status = "[FAIL] $($result.Passed)/$($result.Passed + $result.Failed) ($([math]::Round($duration,1))s)"
            }
            $lines[$idx] = "    $($t.Name.PadRight(30)) $status"
            Write-ColorLine -Y ($idx + 4) -Text $lines[$idx] -Width $width
            
            # Update summary
            $total = $totalPassed + $totalFailed
            $rate = if ($total -gt 0) { [math]::Round(($totalPassed / $total) * 100, 1) } else { 0 }
            
            $lines[$summaryStart + 3] = "  Total Tests:     $total"
            $lines[$summaryStart + 4] = "  Passed:          $totalPassed"
            $lines[$summaryStart + 5] = "  Failed:          $totalFailed"
            $lines[$summaryStart + 6] = "  Success Rate:    $rate%"
            
            Write-ColorLine -Y ($summaryStart + 7) -Text $lines[$summaryStart + 3] -Width $width
            Write-ColorLine -Y ($summaryStart + 8) -Text $lines[$summaryStart + 4] -Width $width
            Write-ColorLine -Y ($summaryStart + 9) -Text $lines[$summaryStart + 5] -Width $width
            Write-ColorLine -Y ($summaryStart + 10) -Text $lines[$summaryStart + 6] -Width $width
        }
    }
    
    # Final status
    $duration = ((Get-Date) - $startTime).TotalSeconds
    $lines[0] = "Status: All tests completed in $([math]::Round($duration,1))s"
    Write-ColorLine -Y 4 -Text $lines[0] -Width $width
    
    return @{
        Passed = $totalPassed
        Failed = $totalFailed
        Duration = $duration
    }
}

Export-ModuleMember -Function Show-ProgressTable
