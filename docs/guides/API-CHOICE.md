# Sitecore API Detection and Choice

GraphQL may not be available on your Sitecore instance (e.g., 404 or 500 errors during introspection).

## Available options

### Option 1: Sitecore Item Web API (Recommended for older versions)
The Item Web API is available from Sitecore 7.0+ and generally works stably.

Advantages:
- Works on older Sitecore versions (7.0+)
- RESTful API, easy to use
- No complex configuration
- Production-ready

Disadvantages:
- Requires API key/configuration
- Less flexible than GraphQL

Quick test (PowerShell):
```powershell
$uri = "https://your-sitecore-instance.com/sitecore/api/ssc/item/{110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}"
$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("sitecore\admin:c"))
$headers = @{ "Authorization" = "Basic $cred" }
Invoke-RestMethod -Uri $uri -Headers $headers
```

### Option 2: Sitecore Services Client (SSC)
More modern API from Sitecore 8.0+.

Quick test (PowerShell):
```powershell
$uri = "https://your-sitecore-instance.com/sitecore/api/ssc/aggregate/content/Items('{110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}')"
Invoke-RestMethod -Uri $uri -Headers $headers
```

### Option 3: SPE with saved scripts
Works, but requires scripts in Sitecore and is less suitable for production.

## Version check

GraphQL is typically available in:
- Sitecore 10.1+ (Built-in GraphQL)
- Sitecore JSS/Headless (GraphQL Edge API)
- XM Cloud (Experience Edge GraphQL)

If you have an older version (<10.1), Item Web API is often the best choice.

## Next step

Test which APIs are available on your instance and configure the MCP server accordingly. We can dynamically adjust the server to use the right API.
