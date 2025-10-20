# Load-DotEnv.ps1 (canonical)
# Helper script to load environment variables from .env file

function Load-DotEnv {
    param(
        [string]$EnvFile = ".env"
    )
    
    if (-not (Test-Path $EnvFile)) {
        Write-Host "[WARN] .env file not found at: $EnvFile" -ForegroundColor Yellow
        Write-Host "[INFO] Using .env.example as reference" -ForegroundColor Cyan
        return $false
    }
    
    Write-Host "[INFO] Loading environment variables from: $EnvFile" -ForegroundColor Cyan
    
    $envContent = Get-Content $EnvFile -ErrorAction Stop
    
    foreach ($line in $envContent) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Trim().StartsWith('#')) {
            continue
        }
        
        # Parse KEY=VALUE
        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            
            # Remove quotes if present
            $value = $value.Trim('"').Trim("'")
            
            # Set environment variable for current process
            [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
            
            Write-Host "  [OK] Loaded: $key" -ForegroundColor Gray
        }
    }
    
    Write-Host "[OK] Environment variables loaded successfully!" -ForegroundColor Green
    return $true
}

# If script is run directly (not dot-sourced), load .env automatically
if ($MyInvocation.InvocationName -ne '.') {
    Load-DotEnv
}
