#!/usr/bin/env pwsh

Write-Host "Test Rapide - Itinerary Service" -ForegroundColor Green
Write-Host ""

# Configuration
$BASE_URL = "http://localhost:8080"
$TIMEOUT = 5

# Fonction de test rapide
function Test-Quick {
    param(
        [string]$TestName,
        [string]$Url,
        [string]$ExpectedStatus = "200"
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $TIMEOUT -ErrorAction Stop
        
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "SUCCESS: $TestName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "FAILED: $TestName (Status: $($response.StatusCode))" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "FAILED: $TestName (Error: $($_.Exception.Message))" -ForegroundColor Red
        return $false
    }
}

# Tests essentiels
$allGood = $true

Write-Host "Tests essentiels..." -ForegroundColor Yellow

# Test 1: Health Check
if (-not (Test-Quick -TestName "Health Check" -Url "$BASE_URL/actuator/health")) {
    $allGood = $false
}

# Test 2: API Documentation
if (-not (Test-Quick -TestName "API Docs" -Url "$BASE_URL/v3/api-docs")) {
    $allGood = $false
}

# Test 3: Itinerary Endpoint (avec paramètre city requis)
if (-not (Test-Quick -TestName "Itinerary API" -Url "$BASE_URL/api/itinerary?city=Casablanca")) {
    $allGood = $false
}

Write-Host ""

if ($allGood) {
    Write-Host "Service operationnel !" -ForegroundColor Green
    Write-Host "Ouvrez: $BASE_URL/v3/api-docs" -ForegroundColor Cyan
} else {
    Write-Host "Problemes detectes. Verifiez les logs: docker-compose logs -f" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Pour tests complets: .\smoke-tests.ps1" -ForegroundColor Cyan
