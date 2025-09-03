# Script de vérification de la santé des services
# Ce script vérifie que tous les services sont opérationnels

param(
    [string]$BaseUrl = "http://localhost:8080",
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Fonction pour logger avec timestamp
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# Fonction pour vérifier un service
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [string]$ExpectedStatus = "200"
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Log "✅ $ServiceName - OK" "SUCCESS"
            return $true
        }
        else {
            Write-Log "❌ $ServiceName - Status: $($response.StatusCode)" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "❌ $ServiceName - Erreur: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction pour vérifier Docker
function Test-DockerHealth {
    try {
        docker version | Out-Null
        Write-Log "✅ Docker - OK" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "❌ Docker - Non disponible" "ERROR"
        return $false
    }
}

# Fonction pour vérifier les conteneurs
function Test-ContainersHealth {
    $containers = @(
        "musafirgo-itinerary-postgres",
        "musafirgo-itinerary-redis",
        "musafirgo-itinerary-app",
        "musafirgo-itinerary-adminer",
        "musafirgo-itinerary-redis-commander"
    )
    
    $healthyContainers = 0
    
    foreach ($container in $containers) {
        try {
            $status = docker inspect $container --format='{{.State.Status}}' 2>$null
            if ($status -eq "running") {
                Write-Log "✅ $container - Running" "SUCCESS"
                $healthyContainers++
            }
            else {
                Write-Log "❌ $container - Status: $status" "ERROR"
            }
        }
        catch {
            Write-Log "❌ $container - Non trouvé" "ERROR"
        }
    }
    
    return $healthyContainers -eq $containers.Count
}

# Fonction pour vérifier la base de données
function Test-DatabaseHealth {
    try {
        $env:PGPASSWORD = "itinerary"
        $result = psql -h localhost -p 5432 -U itinerary -d itinerary -c "SELECT 1;" -t -A 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ PostgreSQL - OK" "SUCCESS"
            return $true
        }
        else {
            Write-Log "❌ PostgreSQL - Erreur de connexion" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "❌ PostgreSQL - Erreur: $($_.Exception.Message)" "ERROR"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Fonction pour vérifier Redis
function Test-RedisHealth {
    try {
        $result = redis-cli -h localhost -p 6379 ping 2>$null
        
        if ($result -eq "PONG") {
            Write-Log "✅ Redis - OK" "SUCCESS"
            return $true
        }
        else {
            Write-Log "❌ Redis - Pas de réponse" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "❌ Redis - Erreur: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction principale
function Main {
    Write-Log "=== VÉRIFICATION DE LA SANTÉ DES SERVICES ===" "INFO"
    Write-Log "URL de base: $BaseUrl" "INFO"
    
    $allHealthy = $true
    
    # Vérifier Docker
    if (-not (Test-DockerHealth)) {
        $allHealthy = $false
    }
    
    # Vérifier les conteneurs
    if (-not (Test-ContainersHealth)) {
        $allHealthy = $false
    }
    
    # Vérifier la base de données
    if (-not (Test-DatabaseHealth)) {
        $allHealthy = $false
    }
    
    # Vérifier Redis
    if (-not (Test-RedisHealth)) {
        $allHealthy = $false
    }
    
    # Vérifier les services web
    $webServices = @(
        @{ Name = "Itinerary Service Health"; Url = "$BaseUrl/actuator/health" },
        @{ Name = "Itinerary Service API"; Url = "$BaseUrl/api/itineraries" },
        @{ Name = "Adminer"; Url = "http://localhost:8081" },
        @{ Name = "Redis Commander"; Url = "http://localhost:8082" }
    )
    
    foreach ($service in $webServices) {
        if (-not (Test-ServiceHealth -ServiceName $service.Name -Url $service.Url)) {
            $allHealthy = $false
        }
    }
    
    # Résultat final
    if ($allHealthy) {
        Write-Log "🎉 Tous les services sont opérationnels !" "SUCCESS"
        return 0
    }
    else {
        Write-Log "❌ Certains services ne sont pas opérationnels" "ERROR"
        return 1
    }
}

# Exécution du script
try {
    $exitCode = Main
    exit $exitCode
}
catch {
    Write-Log "Erreur fatale: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
