# Script pour attendre que Docker soit prêt
# Ce script attend que Docker Desktop soit complètement démarré

Write-Host "=== ATTENTE DOCKER DESKTOP - MUSAFIRGO ===" -ForegroundColor Green

# Fonction pour vérifier si Docker est vraiment prêt
function Test-DockerReady {
    try {
        $result = docker version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Attendre que Docker soit prêt
Write-Host "Attente que Docker Desktop soit complètement prêt..." -ForegroundColor Yellow
$MaxAttempts = 120  # 20 minutes
for ($i = 1; $i -le $MaxAttempts; $i++) {
    if (Test-DockerReady) {
        Write-Host "Docker est prêt!" -ForegroundColor Green
        Write-Host "Vous pouvez maintenant démarrer Jenkins avec: .\start-jenkins-docker.ps1" -ForegroundColor Cyan
        exit 0
    }
    Write-Host "Tentative $i/$MaxAttempts - Docker pas encore prêt..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    if ($i -eq $MaxAttempts) {
        Write-Host "ERREUR: Docker n'est pas prêt après $MaxAttempts tentatives (20 minutes)" -ForegroundColor Red
        Write-Host "Vérifiez que Docker Desktop est démarré manuellement" -ForegroundColor Yellow
        Write-Host "Ou redémarrez Docker Desktop" -ForegroundColor Yellow
        exit 1
    }
}
