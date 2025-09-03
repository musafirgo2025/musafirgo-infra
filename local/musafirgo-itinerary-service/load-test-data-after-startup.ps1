# Script to load test data after application startup
# This script waits for the application to be ready, then loads test data

param(
    [string]$BaseUrl = "http://localhost:8080",
    [int]$MaxRetries = 30,
    [int]$RetryInterval = 5
)

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Wait-ForService {
    param(
        [string]$Url,
        [int]$MaxRetries = 30,
        [int]$RetryInterval = 5
    )
    
    Write-Log "Waiting for service to be ready..." "INFO"
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method GET -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Log "Service ready!" "SUCCESS"
                return $true
            }
        }
        catch {
            Write-Log "Attempt $i/$MaxRetries - Service not ready yet..." "INFO"
            Start-Sleep -Seconds $RetryInterval
        }
    }
    
    Write-Log "Service did not become ready within the timeout period" "ERROR"
    return $false
}

function Load-TestData {
    Write-Log "Loading test data..." "INFO"
    
    try {
        # Execute SQL script via docker-compose
        $result = docker-compose exec -T postgres psql -U itinerary -d itinerary -f /docker-entrypoint-initdb.d/01-dump-data.sql
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Test data loaded successfully" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Error loading test data" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error loading test data: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main script
Write-Log "=== Loading MusafirGO Itinerary Test Data ===" "INFO"

# Step 1: Wait for service to be ready
if (-not (Wait-ForService -Url "$BaseUrl/actuator/health" -MaxRetries $MaxRetries -RetryInterval $RetryInterval)) {
    Write-Log "Cannot continue - service is not ready" "ERROR"
    exit 1
}

# Step 2: Load test data
if (Load-TestData) {
    Write-Log "=== Test data loaded successfully ===" "SUCCESS"
    exit 0
}
else {
    Write-Log "=== Failed to load test data ===" "ERROR"
    exit 1
}
