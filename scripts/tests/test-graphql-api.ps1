# Test Sitecore GraphQL API
# Dit script test de verbinding met GraphQL voordat je de MCP server gebruikt

param(
    [string]$SitecoreHost = $env:SITECORE_HOST,
    [string]$Username = "sitecore\admin",
    [string]$Password = "your-password",
    [string]$Database = "master",
    [string]$ApiKey = $env:SITECORE_API_KEY
)

# Load environment variables from .env using canonical loader (mandatory pattern)
. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

# Populate parameters from environment if not provided
if (-not $SitecoreHost -and $env:SITECORE_HOST) { $SitecoreHost = $env:SITECORE_HOST }
if (-not $ApiKey -and $env:SITECORE_API_KEY) { $ApiKey = $env:SITECORE_API_KEY }

if (-not $SitecoreHost) {
    Write-Host "ERROR: SitecoreHost is required. Set SITECORE_HOST environment variable or pass -SitecoreHost parameter" -ForegroundColor Red
    exit 1
}

if (-not $ApiKey) {
    Write-Host "ERROR: ApiKey is required. Set SITECORE_API_KEY environment variable or pass -ApiKey parameter" -ForegroundColor Red
    exit 1
}

# GraphQL API endpoint (zonder /ui - dat is alleen voor de browser IDE)
$graphqlEndpoint = "$SitecoreHost/sitecore/api/graph/items/master"

# Maak headers met API key (en Basic Auth als fallback)
$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password"))
$headers = @{
    "sc_apikey" = $ApiKey
    "Authorization" = "Basic $credentials"
    "Content-Type" = "application/json"
}

Write-Host "`n=== Sitecore GraphQL API Test ===" -ForegroundColor Cyan
Write-Host "Endpoint: $graphqlEndpoint" -ForegroundColor White
Write-Host "API Key: $ApiKey" -ForegroundColor White
Write-Host "User: $Username" -ForegroundColor White
Write-Host ""

# Test 1: Get Item by Path
Write-Host "Test 1: Get Item by Path (/sitecore/content)" -ForegroundColor Yellow
try {
    $query = @"
    {
      item(path: "/sitecore/content", language: "en") {
        id
        name
        displayName
        path
        template {
          id
          name
        }
        hasChildren
      }
    }
"@
    
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri $graphqlEndpoint -Method Post -Body $body -Headers $headers
    
    if ($response.data.item) {
        Write-Host "[OK] SUCCESS!" -ForegroundColor Green
        Write-Host "  ID: $($response.data.item.id)" -ForegroundColor Gray
        Write-Host "  Name: $($response.data.item.name)" -ForegroundColor Gray
        Write-Host "  Path: $($response.data.item.path)" -ForegroundColor Gray
        Write-Host "  Template: $($response.data.item.template.name)" -ForegroundColor Gray
        Write-Host "  Has Children: $($response.data.item.hasChildren)" -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] No data returned" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Get Children (children is a direct array in /items/master, no results wrapper)
Write-Host "Test 2: Get Children of /sitecore/content" -ForegroundColor Yellow
try {
    $query = @"
    {
      item(path: "/sitecore/content", language: "en") {
        children(first: 50) {
          id
          name
          displayName
          path
          hasChildren
          template { name }
        }
      }
    }
"@
    
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri $graphqlEndpoint -Method Post -Body $body -Headers $headers
    
    if ($response.data.item.children) {
        Write-Host "[OK] SUCCESS!" -ForegroundColor Green
        Write-Host "  Found $($response.data.item.children.Count) children:" -ForegroundColor Gray
        $response.data.item.children | ForEach-Object {
            Write-Host "    - $($_.name) [$($_.template.name)]" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "[ERROR] No children found" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Get Single Field (single 'field' returns a direct string in /items/master)
Write-Host "Test 3: Get Single Field Value" -ForegroundColor Yellow
try {
    $query = @"
    {
      item(path: "/sitecore/content/Home", language: "en") {
        name
        field(name: "Title")
      }
    }
"@
    
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri $graphqlEndpoint -Method Post -Body $body -Headers $headers
    
    if ($null -ne $response.data.item.field -and $response.data.item.field -ne "") {
        Write-Host "[OK] SUCCESS!" -ForegroundColor Green
        Write-Host "  Item: $($response.data.item.name)" -ForegroundColor Gray
        Write-Host "  Title: $($response.data.item.field)" -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] Field not found" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Shallow children listing (avoid deep nesting/timeouts)
Write-Host "Test 4: List all content items (via children query)" -ForegroundColor Yellow
try {
    $query = @"
    {
      item(path: "/sitecore/content", language: "en") {
        children(first: 50) {
          id
          name
          path
          template { name }
          hasChildren
        }
      }
    }
"@
    
    $body = @{ query = $query } | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri $graphqlEndpoint -Method Post -Body $body -Headers $headers
    
    if ($response.data.item.children) {
        Write-Host "[OK] SUCCESS!" -ForegroundColor Green
        Write-Host "  Found $($response.data.item.children.Count) items:" -ForegroundColor Gray
        $response.data.item.children | ForEach-Object {
            Write-Host "    - $($_.name) [$($_.path)]" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "[ERROR] No results found" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 5: GraphQL with Variables
Write-Host "Test 5: Query with Variables" -ForegroundColor Yellow
try {
    $query = @"
    query GetItem(`$path: String!) {
      item(path: `$path, language: "en") {
        id
        name
        displayName
        path
      }
    }
"@
    
    $body = @{
        query = $query
        variables = @{
            path = "/sitecore/content"
        }
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri $graphqlEndpoint -Method Post -Body $body -Headers $headers
    
    if ($response.data.item) {
        Write-Host "[OK] SUCCESS!" -ForegroundColor Green
        Write-Host "  Item: $($response.data.item.name) at $($response.data.item.path)" -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] No data returned" -ForegroundColor Red
    }
} catch {
    Write-Host "[ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Test Voltooid ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Als alle tests succesvol zijn, werkt de GraphQL API!" -ForegroundColor Green
Write-Host "Je kunt nu de MCP server gebruiken met: npm run build && npm start" -ForegroundColor Green
Write-Host ""
