#!/usr/bin/env pwsh

Write-Host "🧪 Test de la configuration APIM locale..." -ForegroundColor Green

# Vérifier que Bicep est installé
try {
    $null = az bicep --version 2>$null
    Write-Host "✅ Azure CLI Bicep est installé" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI Bicep n'est pas installé" -ForegroundColor Red
    Write-Host "Installez-le avec: az bicep install" -ForegroundColor Yellow
    exit 1
}

# Vérifier que nous sommes dans le bon répertoire
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BicepFile = Join-Path $ProjectRoot "dev\iac\aca-dev.bicep"
$ParamFile = Join-Path $ProjectRoot "dev\iac\aca-dev.parameters.json"

if (-not (Test-Path $BicepFile)) {
    Write-Host "❌ Fichier Bicep introuvable: $BicepFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ParamFile)) {
    Write-Host "❌ Fichier de paramètres introuvable: $ParamFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Fichiers de configuration trouvés" -ForegroundColor Green

# Test de compilation Bicep
Write-Host "🔨 Test de compilation Bicep..." -ForegroundColor Yellow
Set-Location (Join-Path $ProjectRoot "dev\iac")

try {
    az bicep build --file aca-dev.bicep --outfile aca-dev.compiled.json
    Write-Host "✅ Compilation Bicep réussie" -ForegroundColor Green
    
    # Nettoyer le fichier temporaire
    if (Test-Path "aca-dev.compiled.json") {
        Remove-Item "aca-dev.compiled.json"
    }
} catch {
    Write-Host "❌ Erreur de compilation Bicep" -ForegroundColor Red
    exit 1
}

# Test de validation des paramètres
Write-Host "🔍 Test de validation des paramètres..." -ForegroundColor Yellow
try {
    az deployment group validate `
        --resource-group "test-rg" `
        --template-file aca-dev.bicep `
        --parameters @aca-dev.parameters.json `
        --parameters containerImage="test-image:latest" | Out-Null
    
    Write-Host "✅ Validation des paramètres réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur de validation des paramètres" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Tous les tests de configuration APIM sont passés !" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Configuration APIM :" -ForegroundColor Cyan
Write-Host "   - SKU: Consumption (pour le POC)" -ForegroundColor White
Write-Host "   - Publisher: MusafirGO Team" -ForegroundColor White
Write-Host "   - Email: dev@musafirgo.com" -ForegroundColor White
Write-Host "   - API: itinerary-api" -ForegroundColor White
Write-Host "   - Endpoint: https://musafirgo-apim.azure-api.net/api/itinerary" -ForegroundColor White
Write-Host ""
Write-Host "Prêt pour le déploiement via GitHub Actions !" -ForegroundColor Green
