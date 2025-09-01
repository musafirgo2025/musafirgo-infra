#!/usr/bin/env pwsh

Write-Host "🧪 Suite de Tests MusafirGO - Itinerary Service" -ForegroundColor Green
Write-Host ""

# Charger la configuration
$configPath = Join-Path $PSScriptRoot "test-config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration introuvable: $configPath" -ForegroundColor Red
    exit 1
}

try {
    $config = Get-Content $configPath | ConvertFrom-Json
} catch {
    Write-Host "Erreur lors du chargement de la configuration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Fonction pour afficher le menu
function Show-Menu {
    Write-Host "Choisissez le type de test:" -ForegroundColor Cyan
    Write-Host "1. Test rapide (5 secondes)" -ForegroundColor White
    Write-Host "2. Tests complets (smoke tests)" -ForegroundColor White
    Write-Host "3. Monitoring continu" -ForegroundColor White
    Write-Host "4. Test personnalise" -ForegroundColor White
    Write-Host "5. Quitter" -ForegroundColor White
    Write-Host ""
}

# Fonction pour exécuter le test rapide
function Run-QuickTest {
    Write-Host "Executing quick test..." -ForegroundColor Yellow
    & "$PSScriptRoot\quick-test-simple.ps1"
}

# Fonction pour exécuter les smoke tests
function Run-SmokeTests {
    Write-Host "Executing smoke tests..." -ForegroundColor Yellow
    & "$PSScriptRoot\smoke-tests.ps1"
}

# Fonction pour exécuter le monitoring
function Run-Monitoring {
    Write-Host "Starting continuous monitoring..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Cyan
    & "$PSScriptRoot\monitor-service.ps1"
}

# Fonction pour test personnalisé
function Run-CustomTest {
    Write-Host "Test personnalise - Choisissez une ville:" -ForegroundColor Yellow
    Write-Host "Villes disponibles: $($config.testData.testCities -join ', ')" -ForegroundColor White
    Write-Host ""
    
    $city = Read-Host "Entrez le nom de la ville (ou appuyez sur Enter pour Casablanca)"
    if (-not $city) { $city = "Casablanca" }
    
    $url = "$($config.baseUrl)$($config.endpoints.itinerary)?city=$city"
    Write-Host "Testing: $url" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec $config.timeout -ErrorAction Stop
        Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Response: $($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))..." -ForegroundColor White
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Boucle principale
do {
    Show-Menu
    $choice = Read-Host "Votre choix (1-5)"
    
    switch ($choice) {
        "1" { 
            Run-QuickTest
            Write-Host ""
            Read-Host "Appuyez sur Enter pour continuer"
        }
        "2" { 
            Run-SmokeTests
            Write-Host ""
            Read-Host "Appuyez sur Enter pour continuer"
        }
        "3" { 
            Run-Monitoring
        }
        "4" { 
            Run-CustomTest
            Write-Host ""
            Read-Host "Appuyez sur Enter pour continuer"
        }
        "5" { 
            Write-Host "Au revoir !" -ForegroundColor Green
            break
        }
        default { 
            Write-Host "Choix invalide. Veuillez choisir 1-5." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
    
    Clear-Host
} while ($choice -ne "5")
