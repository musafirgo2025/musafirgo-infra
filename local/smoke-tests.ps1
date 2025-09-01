#!/usr/bin/env pwsh

Write-Host "🧪 Execution des Smoke Tests pour l'Itinerary Service..." -ForegroundColor Green
Write-Host ""

# Configuration
$BASE_URL = "http://localhost:8080"
$TIMEOUT = 10
$MAX_RETRIES = 3

# Variables pour le suivi des tests
$totalTests = 0
$passedTests = 0
$failedTests = 0

# Fonction pour exécuter un test
function Test-Endpoint {
    param(
        [string]$TestName,
        [string]$Url,
        [string]$Method = "GET",
        [string]$ExpectedStatus = "200",
        [string]$Body = $null,
        [hashtable]$Headers = @{}
    )
    
    $totalTests++
    Write-Host "Test: $TestName" -ForegroundColor Yellow
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            TimeoutSec = $TIMEOUT
            ErrorAction = "Stop"
        }
        
        if ($Headers.Count -gt 0) {
            $params.Headers = $Headers
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-WebRequest @params
        
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "  ✅ SUCCESS - Status: $($response.StatusCode)" -ForegroundColor Green
            $passedTests++
            return $true
        } else {
            Write-Host "  ❌ FAILED - Expected: $ExpectedStatus, Got: $($response.StatusCode)" -ForegroundColor Red
            $failedTests++
            return $false
        }
    } catch {
        Write-Host "  ❌ FAILED - Error: $($_.Exception.Message)" -ForegroundColor Red
        $failedTests++
        return $false
    }
}

# Fonction pour tester avec retry
function Test-EndpointWithRetry {
    param(
        [string]$TestName,
        [string]$Url,
        [string]$Method = "GET",
        [string]$ExpectedStatus = "200",
        [string]$Body = $null,
        [hashtable]$Headers = @{}
    )
    
    for ($i = 1; $i -le $MAX_RETRIES; $i++) {
        Write-Host "  Tentative $i/$MAX_RETRIES..." -ForegroundColor Cyan
        
        if (Test-Endpoint -TestName $TestName -Url $Url -Method $Method -ExpectedStatus $ExpectedStatus -Body $Body -Headers $Headers) {
            return $true
        }
        
        if ($i -lt $MAX_RETRIES) {
            Write-Host "  Attente avant retry..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
    
    return $false
}

# Vérifier que les services sont démarrés
Write-Host "🔍 Verification que les services sont demarres..." -ForegroundColor Cyan
try {
    $containers = docker-compose ps --format json | ConvertFrom-Json
    $postgresRunning = $containers | Where-Object { $_.Name -eq "musafirgo-itinerary-postgres" -and $_.State -eq "running" }
    $appRunning = $containers | Where-Object { $_.Name -eq "musafirgo-itinerary-app" -and $_.State -eq "running" }
    
    if ($postgresRunning) {
        Write-Host "✅ PostgreSQL est demarre" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL n'est pas demarre" -ForegroundColor Red
        exit 1
    }
    
    if ($appRunning) {
        Write-Host "✅ Itinerary Service est demarre" -ForegroundColor Green
    } else {
        Write-Host "❌ Itinerary Service n'est pas demarre" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Impossible de verifier le statut des conteneurs" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Attendre que l'application soit prête
Write-Host "⏳ Attente que l'application soit prete..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host ""
Write-Host "🚀 Execution des tests..." -ForegroundColor Green
Write-Host ""

# Test 1: Health Check
Test-EndpointWithRetry -TestName "Health Check" -Url "$BASE_URL/actuator/health" -ExpectedStatus "200"

# Test 2: Info Endpoint
Test-EndpointWithRetry -TestName "Info Endpoint" -Url "$BASE_URL/actuator/info" -ExpectedStatus "200"

# Test 3: OpenAPI Documentation
Test-EndpointWithRetry -TestName "OpenAPI Docs" -Url "$BASE_URL/v3/api-docs" -ExpectedStatus "200"

# Test 4: Swagger UI
Test-EndpointWithRetry -TestName "Swagger UI" -Url "$BASE_URL/swagger-ui/index.html" -ExpectedStatus "200"

# Test 5: API Base Path
Test-EndpointWithRetry -TestName "API Base Path" -Url "$BASE_URL/api" -ExpectedStatus "404"  # 404 attendu car pas d'endpoint racine

# Test 6: Itinerary Endpoint (GET)
Test-EndpointWithRetry -TestName "Itinerary List Endpoint" -Url "$BASE_URL/api/itinerary" -ExpectedStatus "200"

# Test 7: Create Itinerary (POST)
$createItineraryBody = @{
    city = "Casablanca"
    startDate = "2025-01-15"
    endDate = "2025-01-17"
} | ConvertTo-Json

Test-EndpointWithRetry -TestName "Create Itinerary" -Url "$BASE_URL/api/itinerary" -Method "POST" -Body $createItineraryBody -ExpectedStatus "201"

# Test 8: Metrics Endpoint
Test-EndpointWithRetry -TestName "Metrics Endpoint" -Url "$BASE_URL/actuator/metrics" -ExpectedStatus "200"

# Test 9: Prometheus Endpoint
Test-EndpointWithRetry -TestName "Prometheus Metrics" -Url "$BASE_URL/actuator/prometheus" -ExpectedStatus "200"

# Test 10: Database Connectivity (via health check)
Write-Host "Test: Database Connectivity" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "$BASE_URL/actuator/health" -TimeoutSec $TIMEOUT -ErrorAction Stop
    $healthData = $healthResponse.Content | ConvertFrom-Json
    
    if ($healthData.components.db.status -eq "UP") {
        Write-Host "  ✅ SUCCESS - Database is UP" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  ❌ FAILED - Database status: $($healthData.components.db.status)" -ForegroundColor Red
        $failedTests++
    }
} catch {
    Write-Host "  ❌ FAILED - Cannot check database status" -ForegroundColor Red
    $failedTests++
}

$totalTests++

Write-Host ""
Write-Host "📊 RESULTATS DES SMOKE TESTS" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Total des tests: $totalTests" -ForegroundColor White
Write-Host "Tests reussis: $passedTests" -ForegroundColor Green
Write-Host "Tests echoues: $failedTests" -ForegroundColor Red

if ($failedTests -eq 0) {
    Write-Host ""
    Write-Host "🎉 TOUS LES TESTS SONT PASSES ! Le microservice est operationnel." -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 URLs disponibles:" -ForegroundColor Cyan
    Write-Host "   - Application: $BASE_URL" -ForegroundColor White
    Write-Host "   - Health Check: $BASE_URL/actuator/health" -ForegroundColor White
    Write-Host "   - API Docs: $BASE_URL/v3/api-docs" -ForegroundColor White
    Write-Host "   - Swagger UI: $BASE_URL/swagger-ui/index.html" -ForegroundColor White
    Write-Host "   - Metrics: $BASE_URL/actuator/metrics" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "⚠️ $failedTests test(s) ont echoue. Le microservice peut avoir des problemes." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔍 Pour diagnostiquer:" -ForegroundColor Cyan
    Write-Host "   - Voir les logs: docker-compose logs -f" -ForegroundColor White
    Write-Host "   - Vérifier la santé: .\health-check.ps1" -ForegroundColor White
    Write-Host "   - Redémarrer: .\start-local.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host "💡 Pour relancer les tests: .\smoke-tests.ps1" -ForegroundColor Cyan
