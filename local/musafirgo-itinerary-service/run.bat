@echo off
echo === MusafirGO Pipeline Go - Run Script ===

REM Vérifier si Go est installé
go version >nul 2>&1
if errorlevel 1 (
    echo ❌ Go n'est pas installé. Veuillez installer Go 1.21 ou plus récent.
    echo 📥 Téléchargez Go depuis: https://golang.org/dl/
    pause
    exit /b 1
)

echo ✅ Go détecté

REM Télécharger les dépendances
echo 📦 Téléchargement des dépendances...
go mod tidy
if errorlevel 1 (
    echo ❌ Erreur lors du téléchargement des dépendances
    pause
    exit /b 1
)

REM Compiler la pipeline
echo 🔨 Compilation de la pipeline...
go build -o musafirgo-pipeline.exe pipeline.go
if errorlevel 1 (
    echo ❌ Erreur lors de la compilation
    pause
    exit /b 1
)

echo ✅ Compilation réussie!

REM Exécuter la pipeline
echo 🚀 Exécution de la pipeline...
echo.
musafirgo-pipeline.exe

echo.
echo ✅ Pipeline exécutée avec succès!
pause
