# Test script voor Sitecore MCP Server

# Set environment variables (load from .env if not already set)
if (-not $env:SITECORE_HOST) {
    $env:SITECORE_HOST = "https://your-sitecore-instance.com"
    Write-Host "WARNING: Using default SITECORE_HOST. Set environment variable for your instance." -ForegroundColor Yellow
}
$env:SITECORE_USERNAME = "admin"
$env:SITECORE_PASSWORD = "jouw_wachtwoord"

# Start the MCP server (dit zou normaal door de MCP client worden gedaan)
Write-Host "Starting Sitecore MCP Server..." -ForegroundColor Green
Write-Host "Server is configured for: $env:SITECORE_HOST" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available tools:" -ForegroundColor Yellow
Write-Host "  - sitecore_get_item: Haal een item op via path of ID" -ForegroundColor White
Write-Host "  - sitecore_get_children: Haal child items op" -ForegroundColor White
Write-Host "  - sitecore_query: Voer Sitecore queries uit" -ForegroundColor White
Write-Host "  - sitecore_search: Zoek items op naam" -ForegroundColor White
Write-Host "  - sitecore_get_field_value: Haal field waarde op" -ForegroundColor White
Write-Host "  - sitecore_get_template: Haal template info op" -ForegroundColor White
Write-Host ""
Write-Host "De server draait nu en kan gebruikt worden door MCP clients zoals Claude Desktop" -ForegroundColor Green

node .\dist\index.js
