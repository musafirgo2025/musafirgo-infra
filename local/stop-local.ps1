#!/usr/bin/env pwsh

Write-Host "🛑 Arrêt de l'environnement local MusafirGO..." -ForegroundColor Yellow

# Configuration
$LOCAL_INFRA = "C:\Users\omars\workspace\musafirgo\musafirgo-infra\local"

# Vérifier que le répertoire existe
if (-not (Test-Path $LOCAL_INFRA)) {
    Write-Host "❌ Répertoire infra local introuvable: $LOCAL_INFRA" -ForegroundColor Red
    exit 1
}

# Aller au répertoire local
Set-Location $LOCAL_INFRA

# Arrêt des services
Write-Host "🔄 Arrêt des services..." -ForegroundColor Yellow
try {
    docker-compose down
    Write-Host "✅ Services arrêtés avec succès" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Erreur lors de l'arrêt des services" -ForegroundColor Yellow
}

# Nettoyage des images non utilisées (optionnel)
Write-Host "🧹 Nettoyage des images non utilisées..." -ForegroundColor Yellow
try {
    docker image prune -f
    Write-Host "✅ Images nettoyées" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Erreur lors du nettoyage des images" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Environnement local arrêté avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Pour redémarrer, utilisez : .\start-local.ps1" -ForegroundColor Cyan
