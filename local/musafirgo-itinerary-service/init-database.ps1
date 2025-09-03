# Script d'initialisation de la base de données pour le service Itinerary
# Ce script initialise la base de données avec les données de test

param(
    [string]$BaseUrl = "http://localhost:8080",
    [switch]$Force = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataDir = Join-Path $ScriptDir "data"
$DumpDataFile = Join-Path $DataDir "dump-data.sql"

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

# Fonction pour vérifier si Docker est en cours d'exécution
function Test-DockerRunning {
    try {
        docker version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Fonction pour vérifier si les services sont démarrés
function Test-ServicesRunning {
    $services = @("postgres", "redis", "itinerary-service")
    $runningServices = @()
    
    foreach ($service in $services) {
        try {
            $status = docker-compose ps --services --filter "status=running" | Where-Object { $_ -eq $service }
            if ($status) {
                $runningServices += $service
            }
        }
        catch {
            # Service non trouvé
        }
    }
    
    return $runningServices
}

# Fonction pour attendre qu'un service soit prêt
function Wait-ForService {
    param(
        [string]$ServiceName,
        [string]$HealthCheckUrl,
        [int]$MaxRetries = 30,
        [int]$RetryInterval = 2
    )
    
    Write-Log "Attente du service $ServiceName..." "INFO"
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $HealthCheckUrl -Method GET -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Log "Service $ServiceName prêt !" "SUCCESS"
                return $true
            }
        }
        catch {
            if ($Verbose) {
                Write-Log "Tentative $i/$MaxRetries - Service $ServiceName pas encore prêt..." "WARNING"
            }
        }
        
        Start-Sleep -Seconds $RetryInterval
    }
    
    Write-Log "Timeout: Service $ServiceName non disponible après $($MaxRetries * $RetryInterval) secondes" "ERROR"
    return $false
}

# Fonction pour exécuter une requête SQL
function Invoke-SqlQuery {
    param(
        [string]$Query,
        [string]$Database = "itinerary",
        [string]$User = "itinerary",
        [string]$Password = "itinerary"
    )
    
    try {
        $env:PGPASSWORD = $Password
        $result = psql -h localhost -p 5432 -U $User -d $Database -c $Query -t -A
        return $result
    }
    catch {
        Write-Log "Erreur lors de l'exécution de la requête SQL: $($_.Exception.Message)" "ERROR"
        return $null
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Fonction pour vérifier si la base de données est initialisée
function Test-DatabaseInitialized {
    try {
        $result = Invoke-SqlQuery "SELECT COUNT(*) FROM itinerary;"
        if ($result -and [int]$result -gt 0) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Fonction pour initialiser la base de données
function Initialize-Database {
    Write-Log "Initialisation de la base de données..." "INFO"
    
    # Vérifier si le fichier de données existe
    if (-not (Test-Path $DumpDataFile)) {
        Write-Log "Fichier de données non trouvé: $DumpDataFile" "ERROR"
        return $false
    }
    
    try {
        # Exécuter le script SQL
        $env:PGPASSWORD = "itinerary"
        $result = psql -h localhost -p 5432 -U itinerary -d itinerary -f $DumpDataFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Base de données initialisée avec succès !" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Erreur lors de l'initialisation de la base de données" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de l'initialisation: $($_.Exception.Message)" "ERROR"
        return $false
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}

# Fonction pour afficher les statistiques de la base de données
function Show-DatabaseStats {
    Write-Log "Statistiques de la base de données:" "INFO"
    
    try {
        $stats = @{
            "Itinéraires" = (Invoke-SqlQuery "SELECT COUNT(*) FROM itinerary;")
            "Jours" = (Invoke-SqlQuery "SELECT COUNT(*) FROM day_plan;")
            "Activités" = (Invoke-SqlQuery "SELECT COUNT(*) FROM day_plan_item;")
            "Médias" = (Invoke-SqlQuery "SELECT COUNT(*) FROM media;")
        }
        
        foreach ($stat in $stats.GetEnumerator()) {
            Write-Log "  - $($stat.Key): $($stat.Value)" "INFO"
        }
        
        # Afficher les villes disponibles
        Write-Log "Villes disponibles:" "INFO"
        $cities = Invoke-SqlQuery "SELECT DISTINCT city FROM itinerary ORDER BY city;"
        if ($cities) {
            $cityList = $cities -split "`n" | Where-Object { $_.Trim() -ne "" }
            foreach ($city in $cityList) {
                Write-Log "  - $city" "INFO"
            }
        }
    }
    catch {
        Write-Log "Erreur lors de la récupération des statistiques: $($_.Exception.Message)" "WARNING"
    }
}

# Fonction principale
function Main {
    Write-Log "=== Initialisation de la base de données MusafirGO Itinerary ===" "INFO"
    
    # Vérifier Docker
    if (-not (Test-DockerRunning)) {
        Write-Log "Docker n'est pas en cours d'exécution. Veuillez démarrer Docker Desktop." "ERROR"
        exit 1
    }
    
    # Vérifier si les services sont démarrés
    $runningServices = Test-ServicesRunning
    if ($runningServices.Count -eq 0) {
        Write-Log "Aucun service n'est démarré. Démarrage des services..." "WARNING"
        
        # Démarrer les services
        try {
            Set-Location $ScriptDir
            docker-compose up -d
            Write-Log "Services démarrés. Attente de leur disponibilité..." "INFO"
        }
        catch {
            Write-Log "Erreur lors du démarrage des services: $($_.Exception.Message)" "ERROR"
            exit 1
        }
    }
    else {
        Write-Log "Services en cours d'exécution: $($runningServices -join ', ')" "SUCCESS"
    }
    
    # Attendre que PostgreSQL soit prêt
    if (-not (Wait-ForService "PostgreSQL" "http://localhost:5432" -MaxRetries 15)) {
        Write-Log "PostgreSQL n'est pas accessible" "ERROR"
        exit 1
    }
    
    # Attendre que le service Itinerary soit prêt
    if (-not (Wait-ForService "Itinerary Service" "$BaseUrl/actuator/health" -MaxRetries 30)) {
        Write-Log "Service Itinerary n'est pas accessible" "ERROR"
        exit 1
    }
    
    # Vérifier si la base de données est déjà initialisée
    if ((Test-DatabaseInitialized) -and (-not $Force)) {
        Write-Log "Base de données déjà initialisée. Utilisez -Force pour réinitialiser." "WARNING"
        Show-DatabaseStats
        return
    }
    
    # Initialiser la base de données
    if (Initialize-Database) {
        Write-Log "Initialisation terminée avec succès !" "SUCCESS"
        Show-DatabaseStats
        
        # Test rapide de l'API
        Write-Log "Test rapide de l'API..." "INFO"
        try {
            $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method GET -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $data = $response.Content | ConvertFrom-Json
                Write-Log "API fonctionnelle - $($data.content.Count) itinéraires trouvés" "SUCCESS"
            }
        }
        catch {
            Write-Log "Erreur lors du test de l'API: $($_.Exception.Message)" "WARNING"
        }
    }
    else {
        Write-Log "Échec de l'initialisation de la base de données" "ERROR"
        exit 1
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
    # Nettoyer les variables d'environnement
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
