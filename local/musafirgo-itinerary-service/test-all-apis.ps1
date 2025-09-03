# Script de test complet de toutes les APIs du service Itinerary
# Ce script teste tous les endpoints disponibles avec des cas de test variés

param(
    [string]$BaseUrl = "http://localhost:8080",
    [switch]$Verbose = $false,
    [switch]$SaveResults = $false,
    [int]$Timeout = 30000
)

$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ResultsDir = Join-Path $ScriptDir "results"

# Créer le dossier de résultats s'il n'existe pas
if (-not (Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
}

# Variables globales pour le suivi
$Global:TestResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

# Fonction pour logger avec timestamp
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        "TEST" { "Magenta" }
        default { "White" }
    }
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# Fonction pour exécuter un test
function Invoke-Test {
    param(
        [string]$TestName,
        [string]$Description,
        [scriptblock]$TestScript,
        [string]$Category = "API"
    )
    
    Write-Log "🧪 Test: $TestName" "TEST"
    if ($Verbose) {
        Write-Log "   Description: $Description" "INFO"
    }
    
    $testResult = @{
        Name = $TestName
        Description = $Description
        Category = $Category
        StartTime = Get-Date
        Status = "UNKNOWN"
        Error = $null
        Response = $null
        Duration = 0
    }
    
    try {
        $result = & $TestScript
        $testResult.Status = "PASSED"
        $testResult.Response = $result
        $Global:TestResults.Summary.Passed++
        Write-Log "   ✅ PASSED" "SUCCESS"
    }
    catch {
        $testResult.Status = "FAILED"
        $testResult.Error = $_.Exception.Message
        $Global:TestResults.Summary.Failed++
        Write-Log "   ❌ FAILED: $($_.Exception.Message)" "ERROR"
    }
    finally {
        $testResult.Duration = (Get-Date) - $testResult.StartTime
        $testResult.Duration = [math]::Round($testResult.Duration.TotalMilliseconds, 2)
        $Global:TestResults.Tests += $testResult
        $Global:TestResults.Summary.Total++
    }
}

# Fonction pour faire une requête HTTP
function Invoke-HttpRequest {
    param(
        [string]$Uri,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$Body = $null,
        [int]$Timeout = 30000
    )
    
    $requestParams = @{
        Uri = $Uri
        Method = $Method
        Headers = $Headers
        TimeoutSec = ($Timeout / 1000)
        UseBasicParsing = $true
    }
    
    if ($Body) {
        $requestParams.Body = $Body
    }
    
    return Invoke-WebRequest @requestParams
}

# ========================================
# TESTS DE SANTÉ ET DISPONIBILITÉ
# ========================================

# Test 1: Health Check
Invoke-Test -TestName "Health Check" -Description "Vérification de la santé du service" -Category "Health" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/actuator/health" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "Health check failed with status: $($response.StatusCode)"
    }
    
    $healthData = $response.Content | ConvertFrom-Json
    if ($healthData.status -ne "UP") {
        throw "Service health status is not UP: $($healthData.status)"
    }
    
    return $healthData
}

# Test 2: Database Connectivity
Invoke-Test -TestName "Database Connectivity" -Description "Vérification de la connectivité à la base de données" -Category "Health" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/actuator/health" -Method GET
    $healthData = $response.Content | ConvertFrom-Json
    
    if (-not $healthData.components.db) {
        throw "Database component not found in health check"
    }
    
    if ($healthData.components.db.status -ne "UP") {
        throw "Database is not UP: $($healthData.components.db.status)"
    }
    
    return $healthData.components.db
}

# Test 3: Redis Connectivity
Invoke-Test -TestName "Redis Connectivity" -Description "Vérification de la connectivité à Redis" -Category "Health" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/actuator/health" -Method GET
    $healthData = $response.Content | ConvertFrom-Json
    
    if (-not $healthData.components.redis) {
        throw "Redis component not found in health check"
    }
    
    if ($healthData.components.redis.status -ne "UP") {
        throw "Redis is not UP: $($healthData.components.redis.status)"
    }
    
    return $healthData.components.redis
}

# ========================================
# TESTS DE DOCUMENTATION
# ========================================

# Test 4: OpenAPI Documentation
Invoke-Test -TestName "OpenAPI Documentation" -Description "Vérification de la documentation OpenAPI" -Category "Documentation" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/v3/api-docs" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "OpenAPI docs not accessible: $($response.StatusCode)"
    }
    
    $apiDocs = $response.Content | ConvertFrom-Json
    if (-not $apiDocs.info) {
        throw "OpenAPI documentation is invalid"
    }
    
    return $apiDocs.info
}

# Test 5: Swagger UI
Invoke-Test -TestName "Swagger UI" -Description "Vérification de l'interface Swagger UI" -Category "Documentation" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/swagger-ui/index.html" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "Swagger UI not accessible: $($response.StatusCode)"
    }
    
    return "Swagger UI accessible"
}

# ========================================
# TESTS CRUD - ITINÉRAIRES
# ========================================

# Test 6: List Itineraries (GET /api/itineraries)
Invoke-Test -TestName "List Itineraries" -Description "Récupération de la liste des itinéraires" -Category "CRUD" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "Failed to list itineraries: $($response.StatusCode)"
    }
    
    $data = $response.Content | ConvertFrom-Json
    if (-not $data.content) {
        throw "Invalid response format for list itineraries"
    }
    
    return $data
}

# Test 7: Create Itinerary (POST /api/itineraries)
$testItinerary = $null
Invoke-Test -TestName "Create Itinerary" -Description "Création d'un nouvel itinéraire" -Category "CRUD" {
    $newItinerary = @{
        city = "Test City"
        startDate = "2025-04-01"
        endDate = "2025-04-03"
        days = @(
            @{
                day = 1
                items = @("Test activity 1", "Test activity 2")
            },
            @{
                day = 2
                items = @("Test activity 3", "Test activity 4")
            }
        )
    }
    
    $body = $newItinerary | ConvertTo-Json -Depth 10
    $headers = @{ "Content-Type" = "application/json" }
    
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries" -Method POST -Body $body -Headers $headers
    if ($response.StatusCode -ne 201) {
        throw "Failed to create itinerary: $($response.StatusCode)"
    }
    
    $createdItinerary = $response.Content | ConvertFrom-Json
    if (-not $createdItinerary.id) {
        throw "Created itinerary missing ID"
    }
    
    $script:testItinerary = $createdItinerary
    return $createdItinerary
}

# Test 8: Get Itinerary by ID (GET /api/itineraries/{id})
Invoke-Test -TestName "Get Itinerary by ID" -Description "Récupération d'un itinéraire par son ID" -Category "CRUD" {
    if (-not $testItinerary) {
        throw "No test itinerary available"
    }
    
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries/$($testItinerary.id)" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "Failed to get itinerary: $($response.StatusCode)"
    }
    
    $retrievedItinerary = $response.Content | ConvertFrom-Json
    if ($retrievedItinerary.id -ne $testItinerary.id) {
        throw "Retrieved itinerary ID mismatch"
    }
    
    return $retrievedItinerary
}

# Test 9: Update Itinerary (PUT /api/itineraries/{id})
Invoke-Test -TestName "Update Itinerary" -Description "Mise à jour d'un itinéraire existant" -Category "CRUD" {
    if (-not $testItinerary) {
        throw "No test itinerary available"
    }
    
    $updatedItinerary = @{
        city = "Updated Test City"
        startDate = "2025-04-01"
        endDate = "2025-04-04"
        days = @(
            @{
                day = 1
                items = @("Updated activity 1", "Updated activity 2")
            },
            @{
                day = 2
                items = @("Updated activity 3", "Updated activity 4")
            },
            @{
                day = 3
                items = @("New activity 1", "New activity 2")
            }
        )
    }
    
    $body = $updatedItinerary | ConvertTo-Json -Depth 10
    $headers = @{ "Content-Type" = "application/json" }
    
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries/$($testItinerary.id)" -Method PUT -Body $body -Headers $headers
    if ($response.StatusCode -ne 200) {
        throw "Failed to update itinerary: $($response.StatusCode)"
    }
    
    $updatedResult = $response.Content | ConvertFrom-Json
    if ($updatedResult.city -ne "Updated Test City") {
        throw "Itinerary city was not updated correctly"
    }
    
    return $updatedResult
}

# ========================================
# TESTS DE RECHERCHE ET FILTRAGE
# ========================================

# Test 10: Search by City
Invoke-Test -TestName "Search by City" -Description "Recherche d'itinéraires par ville" -Category "Search" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries?city=Casablanca" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "Failed to search by city: $($response.StatusCode)"
    }
    
    $data = $response.Content | ConvertFrom-Json
    return $data
}

# Test 11: Search with Date Range
Invoke-Test -TestName "Search with Date Range" -Description "Recherche d'itinéraires avec plage de dates" -Category "Search" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries?from=2025-01-01&to=2025-12-31" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "Failed to search with date range: $($response.StatusCode)"
    }
    
    $data = $response.Content | ConvertFrom-Json
    return $data
}

# Test 12: Pagination
Invoke-Test -TestName "Pagination" -Description "Test de la pagination des résultats" -Category "Search" {
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries?page=0&size=2" -Method GET
    if ($response.StatusCode -ne 200) {
        throw "Failed to test pagination: $($response.StatusCode)"
    }
    
    $data = $response.Content | ConvertFrom-Json
    if (-not $data.pageable) {
        throw "Pagination information missing"
    }
    
    return $data
}

# ========================================
# TESTS DE GESTION DES ITEMS
# ========================================

# Test 13: Add Item to Day
Invoke-Test -TestName "Add Item to Day" -Description "Ajout d'un item à un jour d'itinéraire" -Category "Items" {
    if (-not $testItinerary) {
        throw "No test itinerary available"
    }
    
    $addItemRequest = @{
        value = "Nouvelle activité ajoutée"
    }
    
    $body = $addItemRequest | ConvertTo-Json
    $headers = @{ "Content-Type" = "application/json" }
    
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries/$($testItinerary.id)/days/1/items" -Method POST -Body $body -Headers $headers
    if ($response.StatusCode -ne 200) {
        throw "Failed to add item to day: $($response.StatusCode)"
    }
    
    $updatedItinerary = $response.Content | ConvertFrom-Json
    return $updatedItinerary
}

# Test 14: Remove Item from Day
Invoke-Test -TestName "Remove Item from Day" -Description "Suppression d'un item d'un jour d'itinéraire" -Category "Items" {
    if (-not $testItinerary) {
        throw "No test itinerary available"
    }
    
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries/$($testItinerary.id)/days/1/items/0" -Method DELETE
    if ($response.StatusCode -ne 200) {
        throw "Failed to remove item from day: $($response.StatusCode)"
    }
    
    $updatedItinerary = $response.Content | ConvertFrom-Json
    return $updatedItinerary
}

# ========================================
# TESTS DE VALIDATION ET ERREURS
# ========================================

# Test 15: Invalid Itinerary Creation
Invoke-Test -TestName "Invalid Itinerary Creation" -Description "Test de création d'itinéraire invalide" -Category "Validation" {
    $invalidItinerary = @{
        city = ""  # Ville vide - devrait échouer
        startDate = "2025-04-01"
        endDate = "2025-04-03"
        days = @()
    }
    
    $body = $invalidItinerary | ConvertTo-Json -Depth 10
    $headers = @{ "Content-Type" = "application/json" }
    
    try {
        $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries" -Method POST -Body $body -Headers $headers
        if ($response.StatusCode -eq 400) {
            return "Validation correctly rejected invalid itinerary"
        }
        else {
            throw "Expected 400 status code for invalid itinerary, got: $($response.StatusCode)"
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            return "Validation correctly rejected invalid itinerary"
        }
        else {
            throw $_.Exception
        }
    }
}

# Test 16: Get Non-existent Itinerary
Invoke-Test -TestName "Get Non-existent Itinerary" -Description "Test de récupération d'itinéraire inexistant" -Category "Validation" {
    $nonExistentId = "00000000-0000-0000-0000-000000000000"
    
    try {
        $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries/$nonExistentId" -Method GET
        if ($response.StatusCode -eq 404) {
            return "Correctly returned 404 for non-existent itinerary"
        }
        else {
            throw "Expected 404 status code for non-existent itinerary, got: $($response.StatusCode)"
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            return "Correctly returned 404 for non-existent itinerary"
        }
        else {
            throw $_.Exception
        }
    }
}

# ========================================
# NETTOYAGE
# ========================================

# Test 17: Delete Test Itinerary
Invoke-Test -TestName "Delete Test Itinerary" -Description "Suppression de l'itinéraire de test" -Category "Cleanup" {
    if (-not $testItinerary) {
        throw "No test itinerary available"
    }
    
    $response = Invoke-HttpRequest -Uri "$BaseUrl/api/itineraries/$($testItinerary.id)" -Method DELETE
    if ($response.StatusCode -ne 204) {
        throw "Failed to delete test itinerary: $($response.StatusCode)"
    }
    
    return "Test itinerary deleted successfully"
}

# ========================================
# GÉNÉRATION DU RAPPORT
# ========================================

# Fonction pour générer le rapport
function Generate-Report {
    $endTime = Get-Date
    $totalDuration = $endTime - $Global:TestResults.StartTime
    
    $report = @{
        Summary = @{
            StartTime = $Global:TestResults.StartTime
            EndTime = $endTime
            TotalDuration = [math]::Round($totalDuration.TotalSeconds, 2)
            TotalTests = $Global:TestResults.Summary.Total
            PassedTests = $Global:TestResults.Summary.Passed
            FailedTests = $Global:TestResults.Summary.Failed
            SkippedTests = $Global:TestResults.Summary.Skipped
            SuccessRate = if ($Global:TestResults.Summary.Total -gt 0) { [math]::Round(($Global:TestResults.Summary.Passed / $Global:TestResults.Summary.Total) * 100, 2) } else { 0 }
        }
        Tests = $Global:TestResults.Tests
        Categories = @{}
    }
    
    # Grouper par catégorie
    foreach ($test in $Global:TestResults.Tests) {
        if (-not $report.Categories.ContainsKey($test.Category)) {
            $report.Categories[$test.Category] = @{
                Total = 0
                Passed = 0
                Failed = 0
                Tests = @()
            }
        }
        
        $report.Categories[$test.Category].Total++
        $report.Categories[$test.Category].Tests += $test
        
        if ($test.Status -eq "PASSED") {
            $report.Categories[$test.Category].Passed++
        }
        elseif ($test.Status -eq "FAILED") {
            $report.Categories[$test.Category].Failed++
        }
    }
    
    return $report
}

# Fonction pour afficher le résumé
function Show-Summary {
    $report = Generate-Report
    
    Write-Log "=== RÉSUMÉ DES TESTS ===" "INFO"
    Write-Log "Durée totale: $($report.Summary.TotalDuration) secondes" "INFO"
    Write-Log "Tests exécutés: $($report.Summary.TotalTests)" "INFO"
    Write-Log "Tests réussis: $($report.Summary.PassedTests)" "SUCCESS"
    Write-Log "Tests échoués: $($report.Summary.FailedTests)" "ERROR"
    Write-Log "Taux de réussite: $($report.Summary.SuccessRate)%" "INFO"
    
    Write-Log "`n=== RÉSULTATS PAR CATÉGORIE ===" "INFO"
    foreach ($category in $report.Categories.GetEnumerator()) {
        $categoryName = $category.Key
        $categoryData = $category.Value
        $categorySuccessRate = if ($categoryData.Total -gt 0) { [math]::Round(($categoryData.Passed / $categoryData.Total) * 100, 2) } else { 0 }
        
        Write-Log "$categoryName : $($categoryData.Passed)/$($categoryData.Total) ($categorySuccessRate%)" "INFO"
    }
    
    if ($SaveResults) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $reportFile = Join-Path $ResultsDir "api-test-results-$timestamp.json"
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
        Write-Log "Rapport sauvegardé: $reportFile" "SUCCESS"
    }
}

# Exécution du script
try {
    Write-Log "=== TESTS COMPLETS DES APIs MUSAFIRGO ITINERARY ===" "INFO"
    Write-Log "URL de base: $BaseUrl" "INFO"
    Write-Log "Mode verbose: $Verbose" "INFO"
    Write-Log "Sauvegarde des résultats: $SaveResults" "INFO"
    
    Show-Summary
    
    if ($Global:TestResults.Summary.Failed -gt 0) {
        Write-Log "`n⚠️  Certains tests ont échoué. Vérifiez les logs ci-dessus." "WARNING"
        exit 1
    }
    else {
        Write-Log "`n🎉 Tous les tests sont passés avec succès !" "SUCCESS"
        exit 0
    }
}
catch {
    Write-Log "Erreur fatale: $($_.Exception.Message)" "ERROR"
    exit 1
}
