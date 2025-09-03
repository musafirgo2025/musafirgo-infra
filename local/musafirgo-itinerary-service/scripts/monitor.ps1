# Script de monitoring en temps réel
# Ce script surveille les services et affiche les métriques en temps réel

param(
    [string]$BaseUrl = "http://localhost:8080",
    [int]$Interval = 5,
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
        "METRIC" { "Magenta" }
        default { "White" }
    }
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# Fonction pour récupérer les métriques du service
function Get-ServiceMetrics {
    param([string]$Url)
    
    try {
        $startTime = Get-Date
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 5 -UseBasicParsing
        $endTime = Get-Date
        
        $responseTime = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            Status = "OK"
            StatusCode = $response.StatusCode
            ResponseTime = [math]::Round($responseTime, 2)
            Timestamp = $startTime
        }
    }
    catch {
        return @{
            Status = "ERROR"
            StatusCode = $null
            ResponseTime = $null
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

# Fonction pour récupérer les métriques Docker
function Get-DockerMetrics {
    try {
        $containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null
        
        $metrics = @{
            Containers = $containers
            Status = "OK"
        }
        
        return $metrics
    }
    catch {
        return @{
            Containers = $null
            Status = "ERROR"
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour récupérer les métriques de la base de données
function Get-DatabaseMetrics {
    try {
        $env:PGPASSWORD = "itinerary"
        $result = psql -h localhost -p 5432 -U itinerary -d itinerary -c "SELECT COUNT(*) FROM itinerary;" -t -A 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            return @{
                Status = "OK"
                ItineraryCount = [int]$result
                Timestamp = Get-Date
            }
        }
        else {
            return @{
                Status = "ERROR"
                Error = "Database connection failed"
                Timestamp = Get-Date
            }
        }
    }
    catch {
        return @{
            Status = "ERROR"
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Fonction pour récupérer les métriques Redis
function Get-RedisMetrics {
    try {
        $result = redis-cli -h localhost -p 6379 ping 2>$null
        
        if ($result -eq "PONG") {
            return @{
                Status = "OK"
                Response = $result
                Timestamp = Get-Date
            }
        }
        else {
            return @{
                Status = "ERROR"
                Error = "Redis not responding"
                Timestamp = Get-Date
            }
        }
    }
    catch {
        return @{
            Status = "ERROR"
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

# Fonction pour afficher les métriques
function Show-Metrics {
    param(
        [hashtable]$ServiceMetrics,
        [hashtable]$DockerMetrics,
        [hashtable]$DatabaseMetrics,
        [hashtable]$RedisMetrics
    )
    
    # Effacer l'écran
    Clear-Host
    
    Write-Log "=== MONITORING MUSAFIRGO ITINERARY SERVICE ===" "INFO"
    Write-Log "Intervalle: $Interval secondes | Appuyez sur Ctrl+C pour arrêter" "INFO"
    Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
    Write-Log ""
    
    # Métriques du service
    Write-Log "🔧 SERVICE ITINERARY" "METRIC"
    if ($ServiceMetrics.Status -eq "OK") {
        Write-Log "  Status: ✅ OK" "SUCCESS"
        Write-Log "  Code: $($ServiceMetrics.StatusCode)" "INFO"
        Write-Log "  Temps de réponse: $($ServiceMetrics.ResponseTime) ms" "INFO"
    }
    else {
        Write-Log "  Status: ❌ ERROR" "ERROR"
        Write-Log "  Erreur: $($ServiceMetrics.Error)" "ERROR"
    }
    Write-Log ""
    
    # Métriques Docker
    Write-Log "🐳 DOCKER CONTAINERS" "METRIC"
    if ($DockerMetrics.Status -eq "OK") {
        Write-Log "  Status: ✅ OK" "SUCCESS"
        if ($Verbose -and $DockerMetrics.Containers) {
            Write-Log "  Conteneurs:" "INFO"
            $DockerMetrics.Containers | ForEach-Object { Write-Log "    $_" "INFO" }
        }
    }
    else {
        Write-Log "  Status: ❌ ERROR" "ERROR"
        Write-Log "  Erreur: $($DockerMetrics.Error)" "ERROR"
    }
    Write-Log ""
    
    # Métriques de la base de données
    Write-Log "🗄️ DATABASE" "METRIC"
    if ($DatabaseMetrics.Status -eq "OK") {
        Write-Log "  Status: ✅ OK" "SUCCESS"
        Write-Log "  Itinéraires: $($DatabaseMetrics.ItineraryCount)" "INFO"
    }
    else {
        Write-Log "  Status: ❌ ERROR" "ERROR"
        Write-Log "  Erreur: $($DatabaseMetrics.Error)" "ERROR"
    }
    Write-Log ""
    
    # Métriques Redis
    Write-Log "🔴 REDIS" "METRIC"
    if ($RedisMetrics.Status -eq "OK") {
        Write-Log "  Status: ✅ OK" "SUCCESS"
        Write-Log "  Response: $($RedisMetrics.Response)" "INFO"
    }
    else {
        Write-Log "  Status: ❌ ERROR" "ERROR"
        Write-Log "  Erreur: $($RedisMetrics.Error)" "ERROR"
    }
    Write-Log ""
    
    # URLs utiles
    Write-Log "🌐 URLS UTILES" "METRIC"
    Write-Log "  Service: $BaseUrl" "INFO"
    Write-Log "  Health: $BaseUrl/actuator/health" "INFO"
    Write-Log "  API: $BaseUrl/api/itineraries" "INFO"
    Write-Log "  Swagger: $BaseUrl/swagger-ui/index.html" "INFO"
    Write-Log "  Adminer: http://localhost:8081" "INFO"
    Write-Log "  Redis Commander: http://localhost:8082" "INFO"
}

# Fonction principale
function Main {
    Write-Log "Démarrage du monitoring..." "INFO"
    Write-Log "Appuyez sur Ctrl+C pour arrêter" "WARNING"
    
    try {
        while ($true) {
            # Récupérer les métriques
            $serviceMetrics = Get-ServiceMetrics -Url "$BaseUrl/actuator/health"
            $dockerMetrics = Get-DockerMetrics
            $databaseMetrics = Get-DatabaseMetrics
            $redisMetrics = Get-RedisMetrics
            
            # Afficher les métriques
            Show-Metrics -ServiceMetrics $serviceMetrics -DockerMetrics $dockerMetrics -DatabaseMetrics $databaseMetrics -RedisMetrics $redisMetrics
            
            # Attendre l'intervalle
            Start-Sleep -Seconds $Interval
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Log "Monitoring arrêté par l'utilisateur" "WARNING"
    }
    catch {
        Write-Log "Erreur lors du monitoring: $($_.Exception.Message)" "ERROR"
    }
}

# Exécution du script
try {
    Main
}
catch {
    Write-Log "Erreur fatale: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
