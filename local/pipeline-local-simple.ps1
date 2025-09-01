#!/usr/bin/env pwsh

# Pipeline Local MusafirGO - A a Z
# Ce script execute tout le processus de demarrage et de test

Write-Host "PIPELINE LOCAL MUSAFIRGO - A a Z" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Configuration
$PROJECT_ROOT = "C:\Users\omars\workspace\musafirgo"
$ITINERARY_SERVICE = "$PROJECT_ROOT\musafirgo-itinerary-service"
$LOCAL_INFRA = "$PROJECT_ROOT\musafirgo-infra\local"
$BASE_URL = "http://localhost:8080"

# Variables de suivi
$pipelineSteps = @()
$startTime = Get-Date
$overallSuccess = $true

# Fonction pour ajouter une étape
function Add-PipelineStep {
    param(
        [string]$StepName,
        [string]$Status,
        [string]$Details = "",
        [string]$Duration = ""
    )
    
    $step = @{
        Name = $StepName
        Status = $Status
        Details = $Details
        Duration = $Duration
        Timestamp = Get-Date -Format "HH:mm:ss"
    }
    
    $pipelineSteps += $step
    
    # Affichage en temps réel
    $color = if ($Status -eq "SUCCESS") { "Green" } else { "Red" }
    $icon = if ($Status -eq "SUCCESS") { "SUCCESS" } else { "FAILED" }
    Write-Host "[$($step.Timestamp)] $icon $StepName: $Status" -ForegroundColor $color
    if ($Details) { Write-Host "   $Details" -ForegroundColor White }
    if ($Duration) { Write-Host "   Duree: $Duration" -ForegroundColor Cyan }
    Write-Host ""
}

# Fonction pour vérifier les prérequis
function Test-Prerequisites {
    $stepStart = Get-Date
    Write-Host "Verification des prerequis..." -ForegroundColor Yellow
    
    # Vérifier Docker
    try {
        $null = docker version 2>$null
        Add-PipelineStep -StepName "Docker" -Status "SUCCESS" -Details "Docker Desktop est en cours d'execution"
    } catch {
        Add-PipelineStep -StepName "Docker" -Status "FAILED" -Details "Docker Desktop n'est pas en cours d'execution"
        return $false
    }
    
    # Vérifier les répertoires
    if (-not (Test-Path $ITINERARY_SERVICE)) {
        Add-PipelineStep -StepName "Repertoires" -Status "FAILED" -Details "Itinerary service introuvable: $ITINERARY_SERVICE"
        return $false
    }
    
    if (-not (Test-Path $LOCAL_INFRA)) {
        Add-PipelineStep -StepName "Repertoires" -Status "FAILED" -Details "Infra local introuvable: $LOCAL_INFRA"
        return $false
    }
    
    Add-PipelineStep -StepName "Repertoires" -Status "SUCCESS" -Details "Tous les repertoires sont accessibles"
    
    $duration = (Get-Date) - $stepStart
    Add-PipelineStep -StepName "Prerequis" -Status "SUCCESS" -Details "Tous les prerequis sont satisfaits" -Duration $duration.ToString("ss\.fff")
    
    return $true
}

# Fonction pour démarrer l'environnement
function Start-Environment {
    $stepStart = Get-Date
    Write-Host "Demarrage de l'environnement..." -ForegroundColor Yellow
    
    try {
        # Aller au répertoire itinerary service
        Set-Location $ITINERARY_SERVICE
        
        # Build de l'image Docker
        Write-Host "   Build de l'image Docker..." -ForegroundColor Cyan
        docker build -t musafirgo-itinerary-service:local . | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Add-PipelineStep -StepName "Build Docker" -Status "SUCCESS" -Details "Image buildée avec succes"
        } else {
            Add-PipelineStep -StepName "Build Docker" -Status "FAILED" -Details "Erreur lors du build"
            return $false
        }
        
        # Retour au répertoire local
        Set-Location $LOCAL_INFRA
        
        # Arrêter les services existants
        Write-Host "   Nettoyage des services existants..." -ForegroundColor Cyan
        docker-compose down 2>$null | Out-Null
        
        # Démarrer les services
        Write-Host "   Demarrage des services..." -ForegroundColor Cyan
        docker-compose up -d | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Add-PipelineStep -StepName "Demarrage Services" -Status "SUCCESS" -Details "Services demarres avec succes"
        } else {
            Add-PipelineStep -StepName "Demarrage Services" -Status "FAILED" -Details "Erreur lors du demarrage"
            return $false
        }
        
        # Attendre que les services soient prêts
        Write-Host "   Attente que les services soient prets..." -ForegroundColor Cyan
        Start-Sleep -Seconds 15
        
        $duration = (Get-Date) - $stepStart
        Add-PipelineStep -StepName "Environnement" -Status "SUCCESS" -Details "Environnement demarre et pret" -Duration $duration.ToString("ss\.fff")
        
        return $true
        
    } catch {
        Add-PipelineStep -StepName "Environnement" -Status "FAILED" -Details "Erreur: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour exécuter les tests
function Run-AllTests {
    $stepStart = Get-Date
    Write-Host "Execution des tests..." -ForegroundColor Yellow
    
    $testResults = @()
    
    # Test 1: Health Check
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/actuator/health" -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $testResults += @{ Name = "Health Check"; Status = "SUCCESS" }
        } else {
            $testResults += @{ Name = "Health Check"; Status = "FAILED"; Details = "HTTP $($response.StatusCode)" }
        }
    } catch {
        $testResults += @{ Name = "Health Check"; Status = "FAILED"; Details = $_.Exception.Message }
    }
    
    # Test 2: API Documentation
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/v3/api-docs" -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $testResults += @{ Name = "API Docs"; Status = "SUCCESS" }
        } else {
            $testResults += @{ Name = "API Docs"; Status = "FAILED"; Details = "HTTP $($response.StatusCode)" }
        }
    } catch {
        $testResults += @{ Name = "API Docs"; Status = "FAILED"; Details = $_.Exception.Message }
    }
    
    # Test 3: Itinerary Endpoint
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/api/itinerary?city=Casablanca" -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $testResults += @{ Name = "Itinerary API"; Status = "SUCCESS" }
        } else {
            $testResults += @{ Name = "Itinerary API"; Status = "FAILED"; Details = "HTTP $($response.StatusCode)" }
        }
    } catch {
        $testResults += @{ Name = "Itinerary API"; Status = "FAILED"; Details = $_.Exception.Message }
    }
    
    # Test 4: Database Connectivity
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/actuator/health" -TimeoutSec 10 -ErrorAction Stop
        $healthData = $response.Content | ConvertFrom-Json
        
        if ($healthData.components.db.status -eq "UP") {
            $testResults += @{ Name = "Database"; Status = "SUCCESS" }
        } else {
            $testResults += @{ Name = "Database"; Status = "FAILED"; Details = "Status: $($healthData.components.db.status)" }
        }
    } catch {
        $testResults += @{ Name = "Database"; Status = "FAILED"; Details = "Impossible de verifier" }
    }
    
    # Afficher les résultats des tests
    foreach ($test in $testResults) {
        $color = if ($test.Status -eq "SUCCESS") { "Green" } else { "Red" }
        $icon = if ($test.Status -eq "SUCCESS") { "SUCCESS" } else { "FAILED" }
        $details = if ($test.Details) { " - $($test.Details)" } else { "" }
        
        Add-PipelineStep -StepName $test.Name -Status $test.Status -Details $details
        
        if ($test.Status -eq "FAILED") {
            $overallSuccess = $false
        }
    }
    
    $duration = (Get-Date) - $stepStart
    Add-PipelineStep -StepName "Tests" -Status "COMPLETED" -Details "Tous les tests executes" -Duration $duration.ToString("ss\.fff")
    
    return $overallSuccess
}

# Fonction pour générer le rapport final
function Show-FinalReport {
    $totalDuration = (Get-Date) - $startTime
    $successCount = ($pipelineSteps | Where-Object { $_.Status -eq "SUCCESS" }).Count
    $totalCount = $pipelineSteps.Count
    
    Write-Host ""
    Write-Host "RAPPORT FINAL DE LA PIPELINE" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($overallSuccess) {
        Write-Host "PIPELINE REUSSIE !" -ForegroundColor Green
        Write-Host "Tous les services sont operationnels et fonctionnels." -ForegroundColor Green
    } else {
        Write-Host "PIPELINE ECHOUEE" -ForegroundColor Red
        Write-Host "Certains services ont des problemes." -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Statistiques:" -ForegroundColor White
    Write-Host "   - Etapes reussies: $successCount/$totalCount" -ForegroundColor White
    Write-Host "   - Duree totale: $($totalDuration.ToString('mm\:ss'))" -ForegroundColor White
    Write-Host "   - Statut global: $(if ($overallSuccess) { 'SUCCESS' } else { 'FAILED' })" -ForegroundColor $(if ($overallSuccess) { 'Green' } else { 'Red' })
    
    Write-Host ""
    Write-Host "Services disponibles:" -ForegroundColor Cyan
    Write-Host "   - Itinerary Service: $BASE_URL" -ForegroundColor White
    Write-Host "   - Health Check: $BASE_URL/actuator/health" -ForegroundColor White
    Write-Host "   - API Docs: $BASE_URL/v3/api-docs" -ForegroundColor White
    Write-Host "   - Swagger UI: $BASE_URL/swagger-ui/index.html" -ForegroundColor White
    Write-Host "   - PostgreSQL: localhost:5432" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Commandes utiles:" -ForegroundColor Cyan
    Write-Host "   - Verifier la sante: .\health-check.ps1" -ForegroundColor White
    Write-Host "   - Tests rapides: .\quick-test-simple.ps1" -ForegroundColor White
    Write-Host "   - Tests complets: .\smoke-tests.ps1" -ForegroundColor White
    Write-Host "   - Monitoring: .\monitor-service.ps1" -ForegroundColor White
    Write-Host "   - Arreter: .\stop-local.ps1" -ForegroundColor White
    
    if (-not $overallSuccess) {
        Write-Host ""
        Write-Host "Depannage:" -ForegroundColor Yellow
        Write-Host "   - Verifiez les logs: docker-compose logs -f" -ForegroundColor White
        Write-Host "   - Redemarrez: .\start-local.ps1" -ForegroundColor White
        Write-Host "   - Consultez le README pour plus d'informations" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Pour relancer la pipeline: .\pipeline-local-simple.ps1" -ForegroundColor Cyan
}

# Fonction principale
function Start-Pipeline {
    Write-Host "Demarrage de la pipeline locale MusafirGO..." -ForegroundColor Green
    Write-Host "Cette pipeline va:" -ForegroundColor White
    Write-Host "1. Verifier les prerequis" -ForegroundColor White
    Write-Host "2. Demarrer l'environnement Docker" -ForegroundColor White
    Write-Host "3. Executer tous les tests" -ForegroundColor White
    Write-Host "4. Generer un rapport complet" -ForegroundColor White
    Write-Host ""
    
    # Étape 1: Vérification des prérequis
    if (-not (Test-Prerequisites)) {
        Write-Host "Echec de la verification des prerequis. Pipeline arretee." -ForegroundColor Red
        exit 1
    }
    
    # Étape 2: Démarrage de l'environnement
    if (-not (Start-Environment)) {
        Write-Host "Echec du demarrage de l'environnement. Pipeline arretee." -ForegroundColor Red
        exit 1
    }
    
    # Étape 3: Exécution des tests
    if (-not (Run-AllTests)) {
        Write-Host "Certains tests ont echoue, mais l'environnement est demarre." -ForegroundColor Yellow
    }
    
    # Étape 4: Rapport final
    Show-FinalReport
    
    # Retour au répertoire original
    Set-Location $LOCAL_INFRA
}

# Exécution de la pipeline
try {
    Start-Pipeline
} catch {
    Write-Host "Erreur critique dans la pipeline: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
