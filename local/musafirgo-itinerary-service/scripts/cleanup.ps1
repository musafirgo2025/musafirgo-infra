# Script de nettoyage des ressources
# Ce script nettoie les conteneurs, volumes et images Docker

param(
    [switch]$All = $false,
    [switch]$Volumes = $false,
    [switch]$Images = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Fonction pour logger avec timestamp
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# Fonction pour confirmer une action
function Confirm-Action {
    param([string]$Message)
    
    if ($Force) {
        return $true
    }
    
    $response = Read-Host "$Message (y/N)"
    return $response -eq "y" -or $response -eq "Y"
}

# Fonction pour arrêter les services
function Stop-Services {
    Write-Log "Arrêt des services..." "INFO"
    
    try {
        Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
        docker-compose down
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Services arrêtés avec succès" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Erreur lors de l'arrêt des services" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de l'arrêt des services: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Fonction pour supprimer les volumes
function Remove-Volumes {
    if (-not (Confirm-Action "Supprimer les volumes Docker ?")) {
        Write-Log "Suppression des volumes annulée" "WARNING"
        return
    }
    
    Write-Log "Suppression des volumes..." "INFO"
    
    try {
        Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
        docker-compose down -v
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Volumes supprimés avec succès" "SUCCESS"
        }
        else {
            Write-Log "Erreur lors de la suppression des volumes" "ERROR"
        }
    }
    catch {
        Write-Log "Erreur lors de la suppression des volumes: $($_.Exception.Message)" "ERROR"
    }
}

# Fonction pour supprimer les images
function Remove-Images {
    if (-not (Confirm-Action "Supprimer les images Docker ?")) {
        Write-Log "Suppression des images annulée" "WARNING"
        return
    }
    
    Write-Log "Suppression des images..." "INFO"
    
    try {
        # Supprimer les images du projet
        $images = @(
            "musafirgo-itinerary-service_local",
            "postgres:15.6-alpine",
            "redis:7.2-alpine",
            "adminer:latest",
            "rediscommander/redis-commander:latest"
        )
        
        foreach ($image in $images) {
            try {
                docker rmi $image -f 2>$null
                Write-Log "Image supprimée: $image" "SUCCESS"
            }
            catch {
                Write-Log "Image non trouvée: $image" "WARNING"
            }
        }
        
        # Nettoyer les images inutilisées
        docker image prune -f
        
        Write-Log "Images supprimées avec succès" "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors de la suppression des images: $($_.Exception.Message)" "ERROR"
    }
}

# Fonction pour nettoyer le système Docker
function Clean-DockerSystem {
    if (-not (Confirm-Action "Nettoyer le système Docker (conteneurs, réseaux, images inutilisées) ?")) {
        Write-Log "Nettoyage du système annulé" "WARNING"
        return
    }
    
    Write-Log "Nettoyage du système Docker..." "INFO"
    
    try {
        docker system prune -f
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Système Docker nettoyé avec succès" "SUCCESS"
        }
        else {
            Write-Log "Erreur lors du nettoyage du système" "ERROR"
        }
    }
    catch {
        Write-Log "Erreur lors du nettoyage du système: $($_.Exception.Message)" "ERROR"
    }
}

# Fonction pour nettoyer les fichiers locaux
function Clean-LocalFiles {
    Write-Log "Nettoyage des fichiers locaux..." "INFO"
    
    $filesToClean = @(
        "logs\*",
        "results\*",
        "*.log",
        "*.tmp"
    )
    
    foreach ($pattern in $filesToClean) {
        try {
            $files = Get-ChildItem -Path $pattern -Recurse -Force -ErrorAction SilentlyContinue
            if ($files) {
                $files | Remove-Item -Force -Recurse
                Write-Log "Fichiers supprimés: $pattern" "SUCCESS"
            }
        }
        catch {
            Write-Log "Erreur lors de la suppression de $pattern : $($_.Exception.Message)" "WARNING"
        }
    }
}

# Fonction pour afficher l'espace libéré
function Show-DiskSpace {
    Write-Log "Espace disque libéré:" "INFO"
    
    try {
        $diskUsage = docker system df
        Write-Log $diskUsage "INFO"
    }
    catch {
        Write-Log "Impossible de récupérer les informations d'espace disque" "WARNING"
    }
}

# Fonction principale
function Main {
    Write-Log "=== NETTOYAGE DES RESSOURCES MUSAFIRGO ITINERARY ===" "INFO"
    
    if ($All) {
        $Volumes = $true
        $Images = $true
    }
    
    # Arrêter les services
    Stop-Services
    
    # Supprimer les volumes si demandé
    if ($Volumes) {
        Remove-Volumes
    }
    
    # Supprimer les images si demandé
    if ($Images) {
        Remove-Images
    }
    
    # Nettoyer le système Docker
    Clean-DockerSystem
    
    # Nettoyer les fichiers locaux
    Clean-LocalFiles
    
    # Afficher l'espace libéré
    Show-DiskSpace
    
    Write-Log "Nettoyage terminé !" "SUCCESS"
}

# Exécution du script
try {
    Main
}
catch {
    Write-Log "Erreur fatale: $($_.Exception.Message)" "ERROR"
    exit 1
}
