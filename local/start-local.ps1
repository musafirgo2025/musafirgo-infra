#!/usr/bin/env pwsh

Write-Host "🚀 Démarrage de l'environnement local MusafirGO..." -ForegroundColor Green

# Configuration
$PROJECT_ROOT = "C:\Users\omars\workspace\musafirgo"
$ITINERARY_SERVICE = "$PROJECT_ROOT\musafirgo-itinerary-service"
$LOCAL_INFRA = "$PROJECT_ROOT\musafirgo-infra\local"

# Vérifier que Docker est en cours d'exécution
Write-Host "🔍 Vérification de Docker..." -ForegroundColor Yellow
try {
    $null = docker version 2>$null
    Write-Host "✅ Docker est en cours d'exécution" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker n'est pas en cours d'exécution. Démarrez Docker Desktop et réessayez." -ForegroundColor Red
    exit 1
}

# Vérifier que les répertoires existent
if (-not (Test-Path $ITINERARY_SERVICE)) {
    Write-Host "❌ Répertoire itinerary service introuvable: $ITINERARY_SERVICE" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $LOCAL_INFRA)) {
    Write-Host "❌ Répertoire infra local introuvable: $LOCAL_INFRA" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Répertoires vérifiés" -ForegroundColor Green

# Build de l'image Docker de l'itinerary service
Write-Host "🔨 Build de l'image Docker de l'itinerary service..." -ForegroundColor Yellow
Set-Location $ITINERARY_SERVICE

try {
    docker build -t musafirgo-itinerary-service:local .
    Write-Host "✅ Image Docker buildée avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du build Docker" -ForegroundColor Red
    exit 1
}

# Retour au répertoire local
Set-Location $LOCAL_INFRA

# Arrêt des services existants (nettoyage)
Write-Host "🧹 Nettoyage des services existants..." -ForegroundColor Yellow
try {
    docker-compose down
    Write-Host "✅ Services arrêtés" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Aucun service à arrêter" -ForegroundColor Yellow
}

# Démarrage des services
Write-Host "🚀 Démarrage des services locaux..." -ForegroundColor Yellow
try {
    docker-compose up -d
    Write-Host "✅ Services démarrés avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du démarrage des services" -ForegroundColor Red
    exit 1
}

# Attendre que les services soient prêts
Write-Host "⏳ Attente que les services soient prêts..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Vérification de la santé des services
Write-Host "🔍 Vérification de la santé des services..." -ForegroundColor Yellow

# Vérifier PostgreSQL
try {
    $pgHealth = docker exec musafirgo-itinerary-postgres pg_isready -U itinerary -d itinerarydb
    if ($pgHealth -like "*accepting connections*") {
        Write-Host "✅ PostgreSQL est prêt" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL n'est pas prêt" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Impossible de vérifier PostgreSQL" -ForegroundColor Red
}

# Vérifier l'itinerary service
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Itinerary service est prêt (HTTP 200)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Itinerary service répond avec HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⏳ Itinerary service n'est pas encore prêt, attendez quelques secondes..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Environnement local démarré avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Services disponibles :" -ForegroundColor Cyan
Write-Host "   🌐 Itinerary Service: http://localhost:8080" -ForegroundColor White
Write-Host "   🗄️  PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host "   📊 Health Check: http://localhost:8080/actuator/health" -ForegroundColor White
Write-Host "   📚 API Docs: http://localhost:8080/v3/api-docs" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Commandes utiles :" -ForegroundColor Cyan
Write-Host "   📝 Logs: docker-compose logs -f" -ForegroundColor White
Write-Host "   🛑 Arrêt: docker-compose down" -ForegroundColor White
Write-Host "   🔄 Redémarrage: docker-compose restart" -ForegroundColor White
Write-Host ""
Write-Host "Pour tester l'API, ouvrez : http://localhost:8080/v3/api-docs" -ForegroundColor Green
