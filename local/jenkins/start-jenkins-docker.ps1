# Script de démarrage Jenkins Dockerisé pour MusafirGO
# Ce script démarre Jenkins avec Docker Compose pour la pipeline graphique

param(
    [switch]$WithAgent = $false,
    [switch]$Force = $false
)

Write-Host "=== DÉMARRAGE JENKINS DOCKERISÉ - MUSAFIRGO ===" -ForegroundColor Green

# Vérifier que Docker est en cours d'exécution
try {
    docker version | Out-Null
    Write-Host "Docker est en cours d'exécution" -ForegroundColor Green
}
catch {
    Write-Host "ERREUR: Docker n'est pas en cours d'exécution" -ForegroundColor Red
    Write-Host "Démarrez Docker Desktop et réessayez" -ForegroundColor Yellow
    exit 1
}

# Vérifier que le fichier docker-compose existe
$DockerComposeFile = "docker-compose-jenkins.yml"
if (-not (Test-Path $DockerComposeFile)) {
    Write-Host "ERREUR: Fichier $DockerComposeFile non trouvé" -ForegroundColor Red
    exit 1
}

# Arrêter les conteneurs existants si Force est activé
if ($Force) {
    Write-Host "Arrêt des conteneurs Jenkins existants..." -ForegroundColor Yellow
    docker-compose -f $DockerComposeFile down
}

# Démarrer Jenkins
Write-Host "Démarrage de Jenkins..." -ForegroundColor Yellow
if ($WithAgent) {
    Write-Host "Démarrage avec agent Jenkins..." -ForegroundColor Cyan
    docker-compose -f $DockerComposeFile --profile agent up -d
}
else {
    Write-Host "Démarrage Jenkins seul..." -ForegroundColor Cyan
    docker-compose -f $DockerComposeFile up -d jenkins
}

# Attendre que Jenkins soit prêt
Write-Host "Attente que Jenkins soit prêt..." -ForegroundColor Yellow
$MaxAttempts = 30
for ($i = 1; $i -le $MaxAttempts; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/login" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "Jenkins est prêt!" -ForegroundColor Green
            break
        }
    }
    catch {
        Write-Host "Tentative $i/$MaxAttempts - Jenkins pas encore prêt..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
    
    if ($i -eq $MaxAttempts) {
        Write-Host "ERREUR: Jenkins n'est pas accessible après $MaxAttempts tentatives" -ForegroundColor Red
        Write-Host "Vérifiez les logs: docker-compose -f $DockerComposeFile logs jenkins" -ForegroundColor Yellow
        exit 1
    }
}

# Obtenir le mot de passe admin initial
Write-Host "Récupération du mot de passe admin..." -ForegroundColor Yellow
try {
    $AdminPassword = docker exec musafirgo-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    Write-Host ""
    Write-Host "=== JENKINS DOCKERISÉ PRÊT ===" -ForegroundColor Green
    Write-Host "Interface web: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "Mot de passe admin: $AdminPassword" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "=== ÉTAPES DE CONFIGURATION ===" -ForegroundColor Green
    Write-Host "1. Ouvrez votre navigateur: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "2. Utilisez le mot de passe: $AdminPassword" -ForegroundColor Cyan
    Write-Host "3. Installez les plugins suggérés" -ForegroundColor Cyan
    Write-Host "4. Créez un utilisateur admin" -ForegroundColor Cyan
    Write-Host "5. Configurez l'URL Jenkins: http://localhost:8080" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "=== COMMANDES UTILES ===" -ForegroundColor Green
    Write-Host "Voir les logs: docker-compose -f $DockerComposeFile logs -f jenkins" -ForegroundColor Cyan
    Write-Host "Arrêter: docker-compose -f $DockerComposeFile down" -ForegroundColor Cyan
    Write-Host "Redémarrer: docker-compose -f $DockerComposeFile restart jenkins" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "=== PIPELINE MUSAFIRGO ===" -ForegroundColor Green
    Write-Host "Une fois configuré, créez un job 'Pipeline' nommé 'MusafirGO-Pipeline'" -ForegroundColor Cyan
    Write-Host "Utilisez le fichier: jenkins-pipeline-docker.xml" -ForegroundColor Cyan
}
catch {
    Write-Host "ERREUR: Impossible d'obtenir le mot de passe admin" -ForegroundColor Red
    Write-Host "Vérifiez les logs: docker-compose -f $DockerComposeFile logs jenkins" -ForegroundColor Yellow
}
