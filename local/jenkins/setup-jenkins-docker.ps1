# Script de configuration Jenkins Dockerisé pour MusafirGO
# Ce script configure Jenkins avec la pipeline MusafirGO

param(
    [string]$JenkinsUrl = "http://localhost:8080"
)

Write-Host "=== CONFIGURATION JENKINS DOCKERISÉ - MUSAFIRGO ===" -ForegroundColor Green

# Fonction pour attendre que Jenkins soit prêt
function Wait-ForJenkins {
    param([string]$Url, [int]$MaxAttempts = 30)
    
    Write-Host "Attente que Jenkins soit prêt..." -ForegroundColor Yellow
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "Jenkins est prêt!" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "Tentative $i/$MaxAttempts - Jenkins pas encore prêt..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
    }
    return $false
}

# Fonction pour obtenir le mot de passe admin initial
function Get-InitialAdminPassword {
    try {
        $password = docker exec musafirgo-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
        return $password.Trim()
    }
    catch {
        return $null
    }
}

# Attendre que Jenkins soit prêt
if (-not (Wait-ForJenkins -Url $JenkinsUrl)) {
    Write-Host "ERREUR: Jenkins n'est pas accessible à $JenkinsUrl" -ForegroundColor Red
    Write-Host "Vérifiez que Jenkins est démarré: docker-compose -f docker-compose-jenkins.yml ps" -ForegroundColor Yellow
    exit 1
}

# Obtenir le mot de passe admin
$AdminPassword = Get-InitialAdminPassword
if ([string]::IsNullOrEmpty($AdminPassword)) {
    Write-Host "ERREUR: Impossible d'obtenir le mot de passe admin Jenkins" -ForegroundColor Red
    Write-Host "Vérifiez les logs: docker-compose -f docker-compose-jenkins.yml logs jenkins" -ForegroundColor Yellow
    exit 1
}

Write-Host "Mot de passe admin Jenkins: $AdminPassword" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== ÉTAPES DE CONFIGURATION ===" -ForegroundColor Green
Write-Host "1. Ouvrez votre navigateur: $JenkinsUrl" -ForegroundColor Cyan
Write-Host "2. Utilisez le mot de passe: $AdminPassword" -ForegroundColor Cyan
Write-Host "3. Installez les plugins suggérés" -ForegroundColor Cyan
Write-Host "4. Créez un utilisateur admin" -ForegroundColor Cyan
Write-Host "5. Configurez l'URL Jenkins: $JenkinsUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== CRÉATION DE LA PIPELINE MUSAFIRGO ===" -ForegroundColor Green
Write-Host "Une fois Jenkins configuré, créez un nouveau job 'Pipeline' avec le nom 'MusafirGO-Pipeline'" -ForegroundColor Cyan
Write-Host "Utilisez le fichier de configuration: jenkins-pipeline-docker.xml" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== PLUGINS RECOMMANDÉS ===" -ForegroundColor Green
Write-Host "- Pipeline (déjà inclus)" -ForegroundColor Cyan
Write-Host "- HTML Publisher (pour les rapports)" -ForegroundColor Cyan
Write-Host "- Build Timeout" -ForegroundColor Cyan
Write-Host "- Timestamper" -ForegroundColor Cyan
Write-Host "- Docker Pipeline" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== COMMANDES UTILES ===" -ForegroundColor Green
Write-Host "Démarrer Jenkins: .\start-jenkins-docker.ps1" -ForegroundColor Cyan
Write-Host "Voir les logs: docker-compose -f docker-compose-jenkins.yml logs -f jenkins" -ForegroundColor Cyan
Write-Host "Arrêter Jenkins: docker-compose -f docker-compose-jenkins.yml down" -ForegroundColor Cyan
Write-Host "Redémarrer Jenkins: docker-compose -f docker-compose-jenkins.yml restart jenkins" -ForegroundColor Cyan
Write-Host "Interface web: $JenkinsUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== AVANTAGES JENKINS DOCKERISÉ ===" -ForegroundColor Green
Write-Host "✅ Installation simple avec Docker" -ForegroundColor Cyan
Write-Host "✅ Pas de configuration Java manuelle" -ForegroundColor Cyan
Write-Host "✅ Isolation complète" -ForegroundColor Cyan
Write-Host "✅ Facile à nettoyer et redémarrer" -ForegroundColor Cyan
Write-Host "✅ Intégration Docker native" -ForegroundColor Cyan
