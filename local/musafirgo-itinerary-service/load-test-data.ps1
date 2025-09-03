# Script de chargement des données de test pour le service Itinerary
# Ce script charge des données de test supplémentaires via l'API

param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$DataFile = "data/test-itineraries.json",
    [switch]$ClearExisting = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataFilePath = Join-Path $ScriptDir $DataFile

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

# Fonction pour vérifier si le service est accessible
function Test-ServiceAccessible {
    param([string]$Url)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 10 -UseBasicParsing
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

# Fonction pour charger les données de test
function Load-TestData {
    param([string]$DataFile)
    
    if (-not (Test-Path $DataFile)) {
        Write-Log "Fichier de données non trouvé: $DataFile" "ERROR"
        return $false
    }
    
    try {
        $jsonContent = Get-Content $DataFile -Raw | ConvertFrom-Json
        Write-Log "Fichier de données chargé: $DataFile" "SUCCESS"
        return $jsonContent
    }
    catch {
        Write-Log "Erreur lors du chargement du fichier JSON: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction pour créer un itinéraire via l'API
function New-Itinerary {
    param(
        [object]$ItineraryData,
        [string]$BaseUrl
    )
    
    try {
        $body = @{
            city = $ItineraryData.city
            startDate = $ItineraryData.startDate
            endDate = $ItineraryData.endDate
            days = $ItineraryData.days
        } | ConvertTo-Json -Depth 10
        
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method POST -Body $body -Headers $headers -UseBasicParsing
        
        if ($response.StatusCode -eq 201) {
            $createdItinerary = $response.Content | ConvertFrom-Json
            Write-Log "Itinéraire créé: $($ItineraryData.city) (ID: $($createdItinerary.id))" "SUCCESS"
            return $createdItinerary
        }
        else {
            Write-Log "Erreur lors de la création de l'itinéraire $($ItineraryData.city): $($response.StatusCode)" "ERROR"
            return $null
        }
    }
    catch {
        Write-Log "Erreur lors de la création de l'itinéraire $($ItineraryData.city): $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Fonction pour ajouter un item à un jour
function Add-ItemToDay {
    param(
        [string]$ItineraryId,
        [int]$Day,
        [string]$ItemValue,
        [string]$BaseUrl
    )
    
    try {
        $body = @{
            value = $ItemValue
        } | ConvertTo-Json
        
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries/$ItineraryId/days/$Day/items" -Method POST -Body $body -Headers $headers -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Log "Item ajouté au jour $Day de l'itinéraire $ItineraryId" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Erreur lors de l'ajout de l'item au jour $Day: $($response.StatusCode)" "WARNING"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de l'ajout de l'item au jour $Day: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

# Fonction pour lister les itinéraires existants
function Get-ExistingItineraries {
    param([string]$BaseUrl)
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method GET -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            $data = $response.Content | ConvertFrom-Json
            return $data.content
        }
        else {
            Write-Log "Erreur lors de la récupération des itinéraires: $($response.StatusCode)" "WARNING"
            return @()
        }
    }
    catch {
        Write-Log "Erreur lors de la récupération des itinéraires: $($_.Exception.Message)" "WARNING"
        return @()
    }
}

# Fonction pour supprimer un itinéraire
function Remove-Itinerary {
    param(
        [string]$ItineraryId,
        [string]$BaseUrl
    )
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries/$ItineraryId" -Method DELETE -UseBasicParsing
        
        if ($response.StatusCode -eq 204) {
            Write-Log "Itinéraire supprimé: $ItineraryId" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Erreur lors de la suppression de l'itinéraire $ItineraryId: $($response.StatusCode)" "WARNING"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la suppression de l'itinéraire $ItineraryId: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

# Fonction pour nettoyer les données existantes
function Clear-ExistingData {
    param([string]$BaseUrl)
    
    Write-Log "Nettoyage des données existantes..." "WARNING"
    
    $existingItineraries = Get-ExistingItineraries -BaseUrl $BaseUrl
    
    foreach ($itinerary in $existingItineraries) {
        Remove-Itinerary -ItineraryId $itinerary.id -BaseUrl $BaseUrl
    }
    
    Write-Log "Nettoyage terminé" "SUCCESS"
}

# Fonction pour charger les données de test
function Load-AllTestData {
    param(
        [object]$TestData,
        [string]$BaseUrl
    )
    
    $createdCount = 0
    $failedCount = 0
    
    Write-Log "Chargement des données de test..." "INFO"
    
    foreach ($itinerary in $TestData.testItineraries) {
        Write-Log "Création de l'itinéraire: $($itinerary.city)" "INFO"
        
        $createdItinerary = New-Itinerary -ItineraryData $itinerary -BaseUrl $BaseUrl
        
        if ($createdItinerary) {
            $createdCount++
            
            # Ajouter des items supplémentaires si nécessaire
            if ($Verbose) {
                Write-Log "Ajout d'items supplémentaires pour $($itinerary.city)..." "INFO"
                
                foreach ($day in $itinerary.days) {
                    foreach ($item in $day.items) {
                        Add-ItemToDay -ItineraryId $createdItinerary.id -Day $day.day -ItemValue $item -BaseUrl $BaseUrl
                    }
                }
            }
        }
        else {
            $failedCount++
        }
    }
    
    Write-Log "Chargement terminé: $createdCount créés, $failedCount échoués" "INFO"
    
    return @{
        Created = $createdCount
        Failed = $failedCount
    }
}

# Fonction pour afficher les statistiques finales
function Show-FinalStats {
    param([string]$BaseUrl)
    
    Write-Log "Statistiques finales:" "INFO"
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method GET -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            $data = $response.Content | ConvertFrom-Json
            $itineraries = $data.content
            
            Write-Log "  - Nombre total d'itinéraires: $($itineraries.Count)" "INFO"
            
            # Grouper par ville
            $cities = $itineraries | Group-Object city
            foreach ($city in $cities) {
                Write-Log "  - $($city.Name): $($city.Count) itinéraire(s)" "INFO"
            }
            
            # Afficher les IDs des itinéraires créés
            if ($Verbose) {
                Write-Log "IDs des itinéraires:" "INFO"
                foreach ($itinerary in $itineraries) {
                    Write-Log "  - $($itinerary.city): $($itinerary.id)" "INFO"
                }
            }
        }
    }
    catch {
        Write-Log "Erreur lors de la récupération des statistiques: $($_.Exception.Message)" "WARNING"
    }
}

# Fonction principale
function Main {
    Write-Log "=== Chargement des données de test MusafirGO Itinerary ===" "INFO"
    
    # Vérifier si le service est accessible
    if (-not (Test-ServiceAccessible -Url "$BaseUrl/actuator/health")) {
        Write-Log "Service Itinerary non accessible sur $BaseUrl" "ERROR"
        Write-Log "Veuillez démarrer le service avec: docker-compose up -d" "WARNING"
        exit 1
    }
    
    Write-Log "Service Itinerary accessible" "SUCCESS"
    
    # Charger les données de test
    $testData = Load-TestData -DataFile $DataFilePath
    if (-not $testData) {
        exit 1
    }
    
    # Nettoyer les données existantes si demandé
    if ($ClearExisting) {
        Clear-ExistingData -BaseUrl $BaseUrl
    }
    
    # Charger toutes les données de test
    $results = Load-AllTestData -TestData $testData -BaseUrl $BaseUrl
    
    # Afficher les statistiques finales
    Show-FinalStats -BaseUrl $BaseUrl
    
    if ($results.Created -gt 0) {
        Write-Log "Chargement des données de test terminé avec succès !" "SUCCESS"
        Write-Log "Vous pouvez maintenant tester l'API avec: .\test-all-apis.ps1" "INFO"
    }
    else {
        Write-Log "Aucune donnée n'a été chargée" "WARNING"
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
