# Script d'installation automatique de Go pour Windows

Write-Host "=== Installation de Go pour MusafirGO Pipeline ===" -ForegroundColor Cyan

# Vérifier si Go est déjà installé
try {
    $goVersion = go version 2>$null
    if ($goVersion) {
        Write-Host "✅ Go est déjà installé: $goVersion" -ForegroundColor Green
        Write-Host "Vous pouvez maintenant exécuter: .\build-and-run.ps1" -ForegroundColor Yellow
        exit 0
    }
} catch {
    Write-Host "Go n'est pas installé. Installation en cours..." -ForegroundColor Yellow
}

# URL de téléchargement de Go (version 1.21.5)
$goVersion = "1.21.5"
$goUrl = "https://go.dev/dl/go$goVersion.windows-amd64.msi"
$goInstaller = "go$goVersion.windows-amd64.msi"
$goPath = "$env:USERPROFILE\go"

Write-Host "📥 Téléchargement de Go $goVersion..." -ForegroundColor Yellow

try {
    # Télécharger Go
    Invoke-WebRequest -Uri $goUrl -OutFile $goInstaller -UseBasicParsing
    Write-Host "✅ Téléchargement terminé" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du téléchargement: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Veuillez télécharger Go manuellement depuis: https://golang.org/dl/" -ForegroundColor Yellow
    exit 1
}

Write-Host "🔧 Installation de Go..." -ForegroundColor Yellow

try {
    # Installer Go silencieusement
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $goInstaller, "/quiet", "/norestart" -Wait
    Write-Host "✅ Installation terminée" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de l'installation: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Veuillez installer Go manuellement en exécutant: $goInstaller" -ForegroundColor Yellow
    exit 1
}

# Nettoyer l'installateur
Remove-Item $goInstaller -Force

# Ajouter Go au PATH pour la session actuelle
$env:PATH += ";C:\Program Files\Go\bin"

# Vérifier l'installation
try {
    $goVersion = go version
    Write-Host "✅ Go installé avec succès: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Go installé mais pas encore disponible dans le PATH" -ForegroundColor Yellow
    Write-Host "Veuillez redémarrer votre terminal ou exécuter:" -ForegroundColor Cyan
    Write-Host "`$env:PATH += `";C:\Program Files\Go\bin`"" -ForegroundColor White
}

# Créer le répertoire de travail Go
if (!(Test-Path $goPath)) {
    New-Item -ItemType Directory -Path $goPath -Force | Out-Null
    Write-Host "📁 Répertoire Go créé: $goPath" -ForegroundColor Green
}

# Configurer les variables d'environnement Go
Write-Host "⚙️  Configuration des variables d'environnement..." -ForegroundColor Yellow

# Ajouter Go au PATH de manière permanente
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*C:\Program Files\Go\bin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Program Files\Go\bin", "User")
    Write-Host "✅ PATH mis à jour" -ForegroundColor Green
}

# Configurer GOPATH
[Environment]::SetEnvironmentVariable("GOPATH", $goPath, "User")
Write-Host "✅ GOPATH configuré: $goPath" -ForegroundColor Green

# Configurer GOROOT
[Environment]::SetEnvironmentVariable("GOROOT", "C:\Program Files\Go", "User")
Write-Host "✅ GOROOT configuré: C:\Program Files\Go" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Installation de Go terminée avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. Redémarrez votre terminal PowerShell" -ForegroundColor White
Write-Host "2. Exécutez: .\build-and-run.ps1" -ForegroundColor White
Write-Host "3. Ou testez avec: go version" -ForegroundColor White
Write-Host ""
Write-Host "💡 Si Go n'est pas reconnu après redémarrage, ajoutez manuellement au PATH:" -ForegroundColor Yellow
Write-Host "   C:\Program Files\Go\bin" -ForegroundColor White
Write-Host ""
Write-Host "=== INSTALLATION TERMINÉE ===" -ForegroundColor Cyan
