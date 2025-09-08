# Script simple pour exécuter la pipeline Go sans installation Go

Write-Host "=== MusafirGO Pipeline Go - Execution Simple ===" -ForegroundColor Cyan

# Vérifier si Go est installé
try {
    $goVersion = go version 2>$null
    if ($goVersion) {
        Write-Host "Go detecte: $goVersion" -ForegroundColor Green
        Write-Host "Compilation en cours..." -ForegroundColor Yellow
        
        # Compiler la pipeline
        go mod tidy
        go build -o musafirgo-pipeline.exe pipeline.go
        
        if (Test-Path "musafirgo-pipeline.exe") {
            Write-Host "Compilation reussie!" -ForegroundColor Green
            Write-Host "Execution de la pipeline..." -ForegroundColor Yellow
            .\musafirgo-pipeline.exe
        } else {
            Write-Host "Erreur de compilation" -ForegroundColor Red
        }
    } else {
        throw "Go non trouve"
    }
} catch {
    Write-Host "Go n'est pas installe sur ce systeme." -ForegroundColor Red
    Write-Host ""
    Write-Host "Options disponibles:" -ForegroundColor Yellow
    Write-Host "1. Installer Go manuellement depuis: https://golang.org/dl/" -ForegroundColor White
    Write-Host "2. Utiliser Docker pour executer la pipeline" -ForegroundColor White
    Write-Host "3. Utiliser la version PowerShell (dans le dossier old/)" -ForegroundColor White
    Write-Host ""
    Write-Host "Pour installer Go automatiquement, executez:" -ForegroundColor Cyan
    Write-Host "  .\install-go.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Pour utiliser la version PowerShell:" -ForegroundColor Cyan
    Write-Host "  .\old\pipeline-complete.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host "=== SCRIPT TERMINE ===" -ForegroundColor Cyan
