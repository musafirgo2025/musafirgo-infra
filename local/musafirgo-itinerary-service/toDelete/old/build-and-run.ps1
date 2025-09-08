# Script de build et d'exécution pour la pipeline Go (Windows)

Write-Host "=== MusafirGO Pipeline Go - Build and Run ===" -ForegroundColor Cyan

# Vérifier si Go est installé
try {
    $goVersion = go version
    Write-Host "OK Go version: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "ERREUR: Go n'est pas installe. Veuillez installer Go 1.21 ou plus recent." -ForegroundColor Red
    Write-Host "Telechargez Go depuis: https://golang.org/dl/" -ForegroundColor Yellow
    exit 1
}

# Nettoyer les builds précédents
Write-Host "Nettoyage des builds precedents..." -ForegroundColor Yellow
Remove-Item -Path "musafirgo-pipeline*" -Force -ErrorAction SilentlyContinue

# Télécharger les dépendances
Write-Host "Telechargement des dependances..." -ForegroundColor Yellow
go mod tidy

# Build pour différentes plateformes
Write-Host "Compilation..." -ForegroundColor Yellow

# Build pour Windows 64-bit
Write-Host "  - Windows 64-bit..." -ForegroundColor White
$env:GOOS = "windows"
$env:GOARCH = "amd64"
go build -o musafirgo-pipeline-windows.exe pipeline.go

# Build pour Linux
Write-Host "  - Linux..." -ForegroundColor White
$env:GOOS = "linux"
$env:GOARCH = "amd64"
go build -o musafirgo-pipeline-linux pipeline.go

# Build pour macOS
Write-Host "  - macOS..." -ForegroundColor White
$env:GOOS = "darwin"
$env:GOARCH = "amd64"
go build -o musafirgo-pipeline-macos pipeline.go

# Build pour l'architecture actuelle
Write-Host "  - Architecture actuelle..." -ForegroundColor White
$env:GOOS = ""
$env:GOARCH = ""
go build -o musafirgo-pipeline.exe pipeline.go

Write-Host "OK Compilation terminee!" -ForegroundColor Green

# Afficher les fichiers générés
Write-Host "Fichiers generes:" -ForegroundColor Cyan
Get-ChildItem -Name "musafirgo-pipeline*" | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

# Vérifier si Docker est disponible
try {
    docker --version | Out-Null
    Write-Host "Docker detecte. Execution de la pipeline..." -ForegroundColor Green
    Write-Host ""
    Write-Host "=== EXÉCUTION DE LA PIPELINE ===" -ForegroundColor Cyan
    .\musafirgo-pipeline.exe
} catch {
    Write-Host "WARNING: Docker non detecte. La pipeline necessite Docker pour fonctionner." -ForegroundColor Yellow
    Write-Host "Pour tester sans Docker, utilisez: .\musafirgo-pipeline.exe http://your-api-url:8080" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== SCRIPT TERMINE ===" -ForegroundColor Cyan
