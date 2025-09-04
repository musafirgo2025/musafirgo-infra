# Script pour démarrer Docker Desktop et Jenkins
# Ce script démarre Docker Desktop, attend qu'il soit prêt, puis lance Jenkins

Write-Host "=== DÉMARRAGE DOCKER ET JENKINS - MUSAFIRGO ===" -ForegroundColor Green

# Fonction pour vérifier si Docker est prêt
function Test-DockerReady {
    try {
        docker version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Démarrer Docker Desktop
Write-Host "Démarrage de Docker Desktop..." -ForegroundColor Yellow
try {
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Hidden
    Write-Host "Docker Desktop en cours de démarrage..." -ForegroundColor Cyan
}
catch {
    Write-Host "ERREUR: Impossible de démarrer Docker Desktop" -ForegroundColor Red
    Write-Host "Vérifiez que Docker Desktop est installé à: C:\Program Files\Docker\Docker\Docker Desktop.exe" -ForegroundColor Yellow
    exit 1
}

# Attendre que Docker soit prêt
Write-Host "Attente que Docker soit prêt..." -ForegroundColor Yellow
$MaxAttempts = 60
for ($i = 1; $i -le $MaxAttempts; $i++) {
    if (Test-DockerReady) {
        Write-Host "Docker est prêt!" -ForegroundColor Green
        break
    }
    Write-Host "Tentative $i/$MaxAttempts - Docker pas encore prêt..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    if ($i -eq $MaxAttempts) {
        Write-Host "ERREUR: Docker n'est pas prêt après $MaxAttempts tentatives" -ForegroundColor Red
        Write-Host "Vérifiez que Docker Desktop est démarré manuellement" -ForegroundColor Yellow
        exit 1
    }
}

# Démarrer Jenkins
Write-Host "Démarrage de Jenkins..." -ForegroundColor Yellow
& ".\start-jenkins-docker.ps1"



