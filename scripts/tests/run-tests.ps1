# ============================================================================
# Sitecore MCP Test Suite - Launcher
# ============================================================================
# Launches the Terminal.Gui TUI runner in a separate window
# Uses .NET Framework 4.7.2 for Windows PowerShell compatibility
# Author: Gary Wenneker
# Date: October 20, 2025
# ============================================================================

$scriptPath = Join-Path $PSScriptRoot "run-all-tests-tui.ps1"

# Launch in new PowerShell window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '$scriptPath'"
