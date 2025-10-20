# MCP Tools Test Runner
# Interactive menu to run individual or all MCP tool tests

. "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\env"

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Sitecore MCP Tools Test Runner" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select tests to run:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " [1]  sitecore_get_item" -ForegroundColor White
    Write-Host " [2]  sitecore_get_children" -ForegroundColor White
    Write-Host " [3]  sitecore_get_field_value" -ForegroundColor White
    Write-Host " [4]  sitecore_get_item_fields" -ForegroundColor White
    Write-Host " [5]  sitecore_query" -ForegroundColor White
    Write-Host " [6]  sitecore_search" -ForegroundColor White
    Write-Host " [7]  sitecore_search_paginated" -ForegroundColor White
    Write-Host " [8]  sitecore_get_template" -ForegroundColor White
    Write-Host " [9]  sitecore_get_templates" -ForegroundColor White
    Write-Host " [10] sitecore_get_parent" -ForegroundColor White
    Write-Host " [11] sitecore_get_ancestors" -ForegroundColor White
    Write-Host " [12] sitecore_get_item_versions" -ForegroundColor White
    Write-Host " [13] sitecore_get_item_with_statistics" -ForegroundColor White
    Write-Host " [14] sitecore_get_layout" -ForegroundColor White
    Write-Host " [15] sitecore_get_sites" -ForegroundColor White
    Write-Host " [16] sitecore_create_item" -ForegroundColor White
    Write-Host " [17] sitecore_update_item" -ForegroundColor White
    Write-Host " [18] sitecore_delete_item" -ForegroundColor White
    Write-Host " [19] sitecore_discover_item_dependencies" -ForegroundColor White
    Write-Host " [20] sitecore_scan_schema" -ForegroundColor White
    Write-Host " [21] sitecore_command" -ForegroundColor White
    Write-Host ""
    Write-Host " [A]  Run ALL tests" -ForegroundColor Green
    Write-Host " [Q]  Quit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Run-Test {
    param(
        [string]$TestScript,
        [string]$TestName
    )
    
    $scriptPath = "$PSScriptRoot\$TestScript"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "[SKIP] Test script not found: $TestScript" -ForegroundColor Yellow
        Write-Host "       (Test not yet implemented)" -ForegroundColor Gray
        return @{ Status = "SKIP"; ExitCode = 0 }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Running: $TestName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        & $scriptPath
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host ""
            Write-Host "[SUCCESS] $TestName passed all tests" -ForegroundColor Green
            return @{ Status = "PASS"; ExitCode = 0 }
        } else {
            Write-Host ""
            Write-Host "[FAILED] $TestName had $exitCode failure(s)" -ForegroundColor Red
            return @{ Status = "FAIL"; ExitCode = $exitCode }
        }
    }
    catch {
        Write-Host ""
        Write-Host "[ERROR] $TestName threw exception: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Status = "ERROR"; ExitCode = 1 }
    }
}

function Run-AllTests {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Running ALL MCP Tool Tests" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $tests = @(
        @{ Script = "test-mcp-get-item.ps1"; Name = "sitecore_get_item" }
        @{ Script = "test-mcp-get-children.ps1"; Name = "sitecore_get_children" }
        @{ Script = "test-mcp-get-field-value.ps1"; Name = "sitecore_get_field_value" }
        @{ Script = "test-mcp-get-item-fields.ps1"; Name = "sitecore_get_item_fields" }
        @{ Script = "test-mcp-query.ps1"; Name = "sitecore_query" }
        @{ Script = "test-mcp-search.ps1"; Name = "sitecore_search" }
        @{ Script = "test-mcp-search-paginated.ps1"; Name = "sitecore_search_paginated" }
        @{ Script = "test-mcp-get-template.ps1"; Name = "sitecore_get_template" }
        @{ Script = "test-mcp-get-templates.ps1"; Name = "sitecore_get_templates" }
        @{ Script = "test-mcp-get-parent.ps1"; Name = "sitecore_get_parent" }
        @{ Script = "test-mcp-get-ancestors.ps1"; Name = "sitecore_get_ancestors" }
        @{ Script = "test-mcp-get-item-versions.ps1"; Name = "sitecore_get_item_versions" }
        @{ Script = "test-mcp-get-item-with-statistics.ps1"; Name = "sitecore_get_item_with_statistics" }
        @{ Script = "test-mcp-get-layout.ps1"; Name = "sitecore_get_layout" }
        @{ Script = "test-mcp-get-sites.ps1"; Name = "sitecore_get_sites" }
        @{ Script = "test-mcp-create-item.ps1"; Name = "sitecore_create_item" }
        @{ Script = "test-mcp-update-item.ps1"; Name = "sitecore_update_item" }
        @{ Script = "test-mcp-delete-item.ps1"; Name = "sitecore_delete_item" }
        @{ Script = "test-mcp-discover-item-dependencies.ps1"; Name = "sitecore_discover_item_dependencies" }
        @{ Script = "test-mcp-scan-schema.ps1"; Name = "sitecore_scan_schema" }
        @{ Script = "test-mcp-command.ps1"; Name = "sitecore_command" }
    )
    
    $results = @()
    $totalPassed = 0
    $totalFailed = 0
    $totalSkipped = 0
    
    foreach ($test in $tests) {
        $result = Run-Test -TestScript $test.Script -TestName $test.Name
        $results += @{
            Name = $test.Name
            Status = $result.Status
            ExitCode = $result.ExitCode
        }
        
        switch ($result.Status) {
            "PASS" { $totalPassed++ }
            "FAIL" { $totalFailed++ }
            "ERROR" { $totalFailed++ }
            "SKIP" { $totalSkipped++ }
        }
        
        Write-Host ""
        Write-Host "Press any key to continue to next test..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # Summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  FINAL TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Tests: $($tests.Count)" -ForegroundColor Yellow
    Write-Host "Passed: $totalPassed" -ForegroundColor Green
    Write-Host "Failed: $totalFailed" -ForegroundColor Red
    Write-Host "Skipped: $totalSkipped" -ForegroundColor Gray
    Write-Host ""
    
    if ($totalFailed -gt 0) {
        Write-Host "Failed Tests:" -ForegroundColor Red
        $results | Where-Object { $_.Status -in @("FAIL", "ERROR") } | ForEach-Object {
            Write-Host "  - $($_.Name) (Exit Code: $($_.ExitCode))" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    if ($totalSkipped -gt 0) {
        Write-Host "Skipped Tests (not yet implemented):" -ForegroundColor Yellow
        $results | Where-Object { $_.Status -eq "SKIP" } | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "Press any key to return to menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice"
    
    switch ($choice.ToUpper()) {
        "1"  { Run-Test -TestScript "test-mcp-get-item.ps1" -TestName "sitecore_get_item"; Read-Host "`nPress Enter to continue" }
        "2"  { Run-Test -TestScript "test-mcp-get-children.ps1" -TestName "sitecore_get_children"; Read-Host "`nPress Enter to continue" }
        "3"  { Run-Test -TestScript "test-mcp-get-field-value.ps1" -TestName "sitecore_get_field_value"; Read-Host "`nPress Enter to continue" }
        "4"  { Run-Test -TestScript "test-mcp-get-item-fields.ps1" -TestName "sitecore_get_item_fields"; Read-Host "`nPress Enter to continue" }
        "5"  { Run-Test -TestScript "test-mcp-query.ps1" -TestName "sitecore_query"; Read-Host "`nPress Enter to continue" }
        "6"  { Run-Test -TestScript "test-mcp-search.ps1" -TestName "sitecore_search"; Read-Host "`nPress Enter to continue" }
        "7"  { Run-Test -TestScript "test-mcp-search-paginated.ps1" -TestName "sitecore_search_paginated"; Read-Host "`nPress Enter to continue" }
        "8"  { Run-Test -TestScript "test-mcp-get-template.ps1" -TestName "sitecore_get_template"; Read-Host "`nPress Enter to continue" }
        "9"  { Run-Test -TestScript "test-mcp-get-templates.ps1" -TestName "sitecore_get_templates"; Read-Host "`nPress Enter to continue" }
        "10" { Run-Test -TestScript "test-mcp-get-parent.ps1" -TestName "sitecore_get_parent"; Read-Host "`nPress Enter to continue" }
        "11" { Run-Test -TestScript "test-mcp-get-ancestors.ps1" -TestName "sitecore_get_ancestors"; Read-Host "`nPress Enter to continue" }
        "12" { Run-Test -TestScript "test-mcp-get-item-versions.ps1" -TestName "sitecore_get_item_versions"; Read-Host "`nPress Enter to continue" }
        "13" { Run-Test -TestScript "test-mcp-get-item-with-statistics.ps1" -TestName "sitecore_get_item_with_statistics"; Read-Host "`nPress Enter to continue" }
        "14" { Run-Test -TestScript "test-mcp-get-layout.ps1" -TestName "sitecore_get_layout"; Read-Host "`nPress Enter to continue" }
        "15" { Run-Test -TestScript "test-mcp-get-sites.ps1" -TestName "sitecore_get_sites"; Read-Host "`nPress Enter to continue" }
        "16" { Run-Test -TestScript "test-mcp-create-item.ps1" -TestName "sitecore_create_item"; Read-Host "`nPress Enter to continue" }
        "17" { Run-Test -TestScript "test-mcp-update-item.ps1" -TestName "sitecore_update_item"; Read-Host "`nPress Enter to continue" }
        "18" { Run-Test -TestScript "test-mcp-delete-item.ps1" -TestName "sitecore_delete_item"; Read-Host "`nPress Enter to continue" }
        "19" { Run-Test -TestScript "test-mcp-discover-item-dependencies.ps1" -TestName "sitecore_discover_item_dependencies"; Read-Host "`nPress Enter to continue" }
        "20" { Run-Test -TestScript "test-mcp-scan-schema.ps1" -TestName "sitecore_scan_schema"; Read-Host "`nPress Enter to continue" }
        "21" { Run-Test -TestScript "test-mcp-command.ps1" -TestName "sitecore_command"; Read-Host "`nPress Enter to continue" }
        "A"  { Run-AllTests }
        "Q"  { Write-Host "`nExiting..." -ForegroundColor Yellow; break }
        default { Write-Host "`nInvalid choice. Press Enter to continue..." -ForegroundColor Red; Read-Host }
    }
} while ($choice.ToUpper() -ne "Q")

Write-Host ""
Write-Host "Test runner closed." -ForegroundColor Cyan
Write-Host ""
