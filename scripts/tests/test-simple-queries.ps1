# Simple direct GraphQL tests for sites and templates
. "$PSScriptRoot\scripts\tests\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"

# Disable SSL
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

# Endpoint fallback: prefer SITECORE_ENDPOINT, else build from SITECORE_HOST
$endpoint = $env:SITECORE_ENDPOINT
if (-not $endpoint -and $env:SITECORE_HOST) {
    $endpoint = "$(($env:SITECORE_HOST))/sitecore/api/graph/items/master"
}

Write-Host "`n[TEST] Sites query" -ForegroundColor Cyan
$sitesQuery = '{ sites { name } }'
try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$sitesQuery} | ConvertTo-Json)
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[TEST] Templates query" -ForegroundColor Cyan
$templatesQuery = '{ templates { name } }'
try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$templatesQuery} | ConvertTo-Json)
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[TEST] Search query" -ForegroundColor Cyan
$searchQuery = '{ search(keyword: "home", first: 1) { total } }'
try {
    $response = Invoke-RestMethod -Uri $endpoint -Method Post `
        -Headers $headers -Body (@{query=$searchQuery} | ConvertTo-Json)
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
