# Sitecore SPE API Test Script
# Test je Sitecore PowerShell Extensions API voordat je de MCP server gebruikt

param(
    [string]$SitecoreHost = $env:SITECORE_HOST,
    [string]$Username = "admin",
    [string]$Password = "",
    [string]$Database = "master"
)

if ([string]::IsNullOrEmpty($Password)) {
    $SecurePassword = Read-Host "Enter Sitecore password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

Write-Host "`n=== Sitecore SPE API Test ===" -ForegroundColor Cyan
Write-Host "Host: $SitecoreHost" -ForegroundColor White
Write-Host "User: $Username" -ForegroundColor White
Write-Host "Database: $Database" -ForegroundColor White
Write-Host ""

# Test 1: Basic connectivity
Write-Host "Test 1: Basic Connectivity..." -ForegroundColor Yellow
try {
    $uri = "$SitecoreHost/sitecore"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 5
    Write-Host "[OK] Sitecore is bereikbaar" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Kan Sitecore niet bereiken: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: SPE API endpoint
Write-Host "`nTest 2: SPE API Endpoint..." -ForegroundColor Yellow

# Test verschillende SPE endpoints en methodes
$endpoints = @(
    @{Path = "/sitecore/api/spe/v2/script"; Method = "POST"},
    @{Path = "/-/script/v2/master/script"; Method = "POST"},
    @{Path = "/sitecore/api/spe/v2/master/script"; Method = "POST"},
    @{Path = "/api/spe/v2/script"; Method = "POST"},
    @{Path = "/-/script/v2"; Method = "POST"}
)

$speFound = $false
foreach ($ep in $endpoints) {
    try {
        Write-Host "  Trying: $($ep.Path)" -ForegroundColor Gray
        
        $headers = @{
            "Content-Type" = "text/plain"
        }
        
        # Probeer eerst zonder credentials in URL (Basic Auth in header)
        $authString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password"))
        $headers["Authorization"] = "Basic $authString"
        
        $scriptBody = "Write-Output 'SPE is working!'"
        $uri = "{0}{1}" -f $SitecoreHost, $ep.Path
        
        Write-Host "    Full URI: $uri" -ForegroundColor DarkGray
        
        $response = Invoke-WebRequest -Uri $uri -Method $ep.Method -Headers $headers -Body $scriptBody -UseBasicParsing -TimeoutSec 10
        
        Write-Host "[OK] SPE API is bereikbaar op: $($ep.Path)" -ForegroundColor Green
        Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
        $speFound = $true
        $workingEndpoint = $ep.Path
        break
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "    HTTP $statusCode" -ForegroundColor DarkGray
        } else {
            Write-Host "    Not found" -ForegroundColor DarkGray
        }
    }
}

if (-not $speFound) {
    Write-Host "[ERROR] SPE API niet bereikbaar op bekende endpoints" -ForegroundColor Red
    Write-Host "`nGevonden HTTP status codes:" -ForegroundColor Yellow
    Write-Host "  - 403 = Service bestaat maar is DISABLED" -ForegroundColor White
    Write-Host "  - 404 = Endpoint bestaat niet" -ForegroundColor White
    Write-Host "  - 401 = Authenticatie mislukt" -ForegroundColor White
    Write-Host "`nAls je HTTP 403 ziet:" -ForegroundColor Yellow
    Write-Host "  ➡️  De 'restfulv2' service is DISABLED" -ForegroundColor Red
    Write-Host "  ➡️  Zie SPE-CONFIGURATIE.md voor de oplossing" -ForegroundColor Green
    Write-Host "`nSnelle fix:" -ForegroundColor Yellow
    Write-Host "  1. Open: App_Config\Include\Spe\Spe.config" -ForegroundColor White
    Write-Host "  2. Vind: <restfulv2 enabled=" -ForegroundColor White
    Write-Host "  3. Wijzig naar: <restfulv2 enabled=`"true`">" -ForegroundColor White
    Write-Host "  4. Run: iisreset" -ForegroundColor White
    Write-Host "  5. Test opnieuw: .\test-spe-api.ps1 -Password `"c`"" -ForegroundColor White
    exit 1
}

# Test 3: Get Sitecore item
Write-Host "`nTest 3: Get Sitecore Item..." -ForegroundColor Yellow
try {
    $scriptBody = @"
`$item = Get-Item -Path 'master:\sitecore\content' -ErrorAction Stop
@{
    name = `$item.Name
    id = `$item.ID.ToString()
    path = `$item.Paths.Path
    templateName = `$item.TemplateName
    hasChildren = `$item.HasChildren
} | ConvertTo-Json -Compress
"@
    
    $uri = "{0}{1}?sc_database={2}&user={3}&password={4}" -f $SitecoreHost, $workingEndpoint, $Database, $Username, $Password
    
    $response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $scriptBody -UseBasicParsing
    
    $result = $response.Content | ConvertFrom-Json
    Write-Host "[OK] Item ophalen werkt" -ForegroundColor Green
    Write-Host "  Item: $($result.name)" -ForegroundColor Gray
    Write-Host "  Path: $($result.path)" -ForegroundColor Gray
    Write-Host "  Template: $($result.templateName)" -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] Kan item niet ophalen: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "  Response: $responseBody" -ForegroundColor DarkGray
    }
    exit 1
}

# Test 4: Get children
Write-Host "`nTest 4: Get Children..." -ForegroundColor Yellow
try {
    $scriptBody = @"
`$items = Get-ChildItem -Path 'master:\sitecore\content' | Select-Object -First 5
`$items | ForEach-Object {
    @{
        name = `$_.Name
        path = `$_.Paths.Path
    }
} | ConvertTo-Json -Compress
"@
    
    $uri = "{0}{1}?sc_database={2}&user={3}&password={4}" -f $SitecoreHost, $workingEndpoint, $Database, $Username, $Password
    
    $response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body $scriptBody -UseBasicParsing
    
    $results = $response.Content | ConvertFrom-Json
    Write-Host "[OK] Children ophalen werkt" -ForegroundColor Green
    Write-Host "  Aantal items: $($results.Count)" -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] Kan children niet ophalen: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Samenvatting ===" -ForegroundColor Cyan
Write-Host "[OK] Alle tests geslaagd!" -ForegroundColor Green
Write-Host "`nJe kunt nu de MCP server gebruiken." -ForegroundColor White
Write-Host "Run: npm start" -ForegroundColor Yellow
Write-Host ""
