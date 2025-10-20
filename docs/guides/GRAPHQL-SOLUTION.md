# Sitecore GraphQL API - Modern Solution

GraphQL is the recommended modern way to communicate with Sitecore, especially for JSS/Headless implementations.

## Why GraphQL
- Modern and flexible: request exactly the data you need
- Type-safe: schema-driven
- Fewer round-trips: better performance

## Endpoints
- Experience Edge (XM Cloud): https://edge.sitecorecloud.io/api/graphql/v1
- Connected GraphQL (On-prem/Managed Cloud): https://your-sitecore-instance.com/sitecore/api/graph/items/master

Note: in this project the Edge endpoint has been removed; use only /sitecore/api/graph/items/master.

## Schema hints (/items/master)
- children is a direct array (no results wrapper)
- field(name) returns a direct string
- search uses results.items (no total/totalCount in this environment)
- Always specify language parameter (templates/layout/system: en)

## PowerShell test pattern
- Endpoint: $env:SITECORE_HOST/sitecore/api/graph/items/master
- Headers: sc_apikey + Content-Type: application/json
- Keep queries short and phased to avoid timeouts

## Best practices MCP
- Use MCP tools for production (fallback logic, error handling)
- Apply smart language defaults
- Always format GUIDs with dashes and curly braces for ID paths
- Use search for deep discovery, not children recursively
