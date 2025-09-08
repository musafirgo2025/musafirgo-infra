# Script pour exécuter la pipeline avec démarrage automatique de Docker
Write-Host "=== MusafirGO Pipeline avec Démarrage Auto Docker ===" -ForegroundColor Cyan

# Vérifier si Docker est en cours d'exécution
Write-Host "🔍 Vérification du statut Docker..." -ForegroundColor Yellow
$dockerInfo = docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Docker n'est pas en cours d'exécution" -ForegroundColor Yellow
    Write-Host "🚀 Tentative de démarrage de Docker Desktop..." -ForegroundColor Yellow
    
    # Démarrer Docker Desktop
    Start-Process "Docker Desktop" -ErrorAction SilentlyContinue
    Write-Host "📱 Commande de lancement Docker Desktop envoyée" -ForegroundColor Green
    
    # Attendre que Docker soit prêt
    Write-Host "⏳ Attente du démarrage de Docker..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0
    
    do {
        $attempt++
        Start-Sleep -Seconds 2
        
        $dockerInfo = docker info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker démarré avec succès après $($attempt * 2) secondes!" -ForegroundColor Green
            break
        }
        
        Write-Host "⏳ Attente en cours... ($attempt/$maxAttempts)" -ForegroundColor Yellow
    } while ($attempt -lt $maxAttempts)
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker n'a pas démarré dans les $($maxAttempts * 2) secondes" -ForegroundColor Red
        Write-Host "💡 Veuillez démarrer Docker Desktop manuellement et réessayer" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "✅ Docker est déjà en cours d'exécution" -ForegroundColor Green
}

# Maintenant exécuter la pipeline
Write-Host "🚀 Exécution de la pipeline MusafirGO..." -ForegroundColor Cyan
Write-Host ""

# Exécuter la pipeline
& ".\pipeline.exe"

Write-Host ""
Write-Host "✅ Pipeline exécutée avec succès!" -ForegroundColor Green