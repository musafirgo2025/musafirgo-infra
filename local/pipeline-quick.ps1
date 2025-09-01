#!/usr/bin/env pwsh

# Pipeline Rapide MusafirGO - Vérification Express
# Ce script vérifie rapidement que tout fonctionne

Write-Host "⚡ PIPELINE RAPIDE MUSAFIRGO" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host ""

# Configuration
$BASE_URL = "http://localhost:8080"
$startTime = Get-Date
$allGood = $true

# Fonction de test rapide
function Test-Quick {
    param(
        [string]$TestName,
        [string]$Url,
        [string]$ExpectedStatus = "200"
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -ErrorAction Stop
        
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "✅ $TestName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $TestName (Status: $($response.StatusCode))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ $TestName (Error: $($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
}

# Vérification rapide des services
Write-Host "🔍 Vérification rapide des services..." -ForegroundColor Yellow

# Test 1: Health Check
if (-not (Test-Quick -TestName "Health Check" -Url "$BASE_URL/actuator/health")) {
    $allGood = $false
}

# Test 2: API Documentation
if (-not (Test-Quick -TestName "API Docs" -Url "$BASE_URL/v3/api-docs")) {
    $allGood = $false
}

# Test 3: Itinerary Endpoint
if (-not (Test-Quick -TestName "Itinerary API" -Url "$BASE_URL/api/itinerary?city=Casablanca")) {
    $allGood = $false
}

# Test 4: Database (via health check)
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/actuator/health" -TimeoutSec 5 -ErrorAction Stop
    $healthData = $response.Content | ConvertFrom-Json
    
    if ($healthData.components.db.status -eq "UP") {
        Write-Host "✅ Database" -ForegroundColor Green
    } else {
        Write-Host "❌ Database (Status: $($healthData.components.db.status))" -ForegroundColor Red
        $allGood = $false
    }
} catch {
    Write-Host "❌ Database (Error: $($_.Exception.Message))" -ForegroundColor Red
    $allGood = $false
}

# Rapport final
$duration = (Get-Date) - $startTime
Write-Host ""
Write-Host "📊 RAPPORT RAPIDE" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host "🎉 TOUT EST OK !" -ForegroundColor Green
    Write-Host "Tous les services sont opérationnels." -ForegroundColor Green
    Write-Host "Durée: $($duration.ToString('ss\.fff')) secondes" -ForegroundColor Cyan
} else {
    Write-Host "⚠️ PROBLÈMES DÉTECTÉS" -ForegroundColor Red
    Write-Host "Certains services ont des problèmes." -ForegroundColor Red
    Write-Host "Durée: $($duration.ToString('ss\.fff')) secondes" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🌐 URLs disponibles:" -ForegroundColor White
Write-Host "   - Service: $BASE_URL" -ForegroundColor White
Write-Host "   - API Docs: $BASE_URL/v3/api-docs" -ForegroundColor White
Write-Host "   - Swagger: $BASE_URL/swagger-ui/index.html" -ForegroundColor White

Write-Host ""
if ($allGood) {
    Write-Host "💡 Pour tests complets: .\pipeline-local.ps1" -ForegroundColor Cyan
} else {
    Write-Host "🔍 Pour diagnostiquer: .\health-check.ps1" -ForegroundColor Yellow
    Write-Host "🔄 Pour redémarrer: .\start-local.ps1" -ForegroundColor Yellow
}
