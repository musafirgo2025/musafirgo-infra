#!/usr/bin/env pwsh

Write-Host "🔍 Vérification de la santé des services locaux..." -ForegroundColor Green

# Configuration
$LOCAL_INFRA = "C:\Users\omars\workspace\musafirgo\musafirgo-infra\local"

# Vérifier que le répertoire existe
if (-not (Test-Path $LOCAL_INFRA)) {
    Write-Host "❌ Répertoire infra local introuvable: $LOCAL_INFRA" -ForegroundColor Red
    exit 1
}

# Aller au répertoire local
Set-Location $LOCAL_INFRA

# Vérifier le statut des conteneurs
Write-Host "🐳 Statut des conteneurs Docker..." -ForegroundColor Yellow
try {
    docker-compose ps
} catch {
    Write-Host "❌ Erreur lors de la vérification des conteneurs" -ForegroundColor Red
}

Write-Host ""

# Vérifier PostgreSQL
Write-Host "🗄️  Vérification de PostgreSQL..." -ForegroundColor Yellow
try {
    $pgHealth = docker exec musafirgo-itinerary-postgres pg_isready -U itinerary -d itinerarydb 2>$null
    if ($pgHealth -like "*accepting connections*") {
        Write-Host "✅ PostgreSQL est prêt et accepte les connexions" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL n'est pas prêt" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Impossible de vérifier PostgreSQL - conteneur non démarré" -ForegroundColor Red
}

# Vérifier l'itinerary service
Write-Host "🌐 Vérification de l'itinerary service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Itinerary service répond (HTTP 200)" -ForegroundColor Green
        
        # Afficher le contenu de la réponse de santé
        try {
            $healthData = $response.Content | ConvertFrom-Json
            Write-Host "   📊 Status: $($healthData.status)" -ForegroundColor White
            if ($healthData.components) {
                Write-Host "   🔧 Composants:" -ForegroundColor White
                foreach ($component in $healthData.components.PSObject.Properties) {
                    $status = $component.Value.status
                    $color = if ($status -eq "UP") { "Green" } else { "Red" }
                    Write-Host "      - $($component.Name): $status" -ForegroundColor $color
                }
            }
        } catch {
            Write-Host "   📄 Réponse brute: $($response.Content.Substring(0, [Math]::Min(100, $response.Content.Length)))..." -ForegroundColor White
        }
    } else {
        Write-Host "⚠️ Itinerary service répond avec HTTP $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Itinerary service ne répond pas - service non démarré ou en cours de démarrage" -ForegroundColor Red
}

# Vérifier les logs récents
Write-Host ""
Write-Host "📝 Logs récents de l'itinerary service..." -ForegroundColor Yellow
try {
    docker logs --tail 10 musafirgo-itinerary-app
} catch {
    Write-Host "❌ Impossible de récupérer les logs" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔧 Commandes utiles :" -ForegroundColor Cyan
Write-Host "   📝 Logs en temps réel: docker-compose logs -f" -ForegroundColor White
Write-Host "   🔄 Redémarrage: docker-compose restart" -ForegroundColor White
Write-Host "   🚀 Redémarrage complet: .\start-local.ps1" -ForegroundColor White
Write-Host "   🛑 Arrêt: .\stop-local.ps1" -ForegroundColor White
