#!/bin/bash
# Script de build et d'exécution pour la pipeline Go

echo "=== MusafirGO Pipeline Go - Build and Run ==="

# Vérifier si Go est installé
if ! command -v go &> /dev/null; then
    echo "❌ Go n'est pas installé. Veuillez installer Go 1.21 ou plus récent."
    exit 1
fi

echo "✅ Go version: $(go version)"

# Nettoyer les builds précédents
echo "🧹 Nettoyage des builds précédents..."
rm -f musafirgo-pipeline musafirgo-pipeline.exe

# Télécharger les dépendances
echo "📦 Téléchargement des dépendances..."
go mod tidy

# Build pour différentes plateformes
echo "🔨 Compilation..."

# Build pour Linux/Unix
echo "  - Linux/Unix..."
GOOS=linux GOARCH=amd64 go build -o musafirgo-pipeline-linux pipeline.go

# Build pour Windows
echo "  - Windows..."
GOOS=windows GOARCH=amd64 go build -o musafirgo-pipeline-windows.exe pipeline.go

# Build pour macOS
echo "  - macOS..."
GOOS=darwin GOARCH=amd64 go build -o musafirgo-pipeline-macos pipeline.go

# Build pour l'architecture actuelle
echo "  - Architecture actuelle..."
go build -o musafirgo-pipeline pipeline.go

echo "✅ Compilation terminée!"

# Afficher les fichiers générés
echo "📁 Fichiers générés:"
ls -la musafirgo-pipeline*

# Vérifier si Docker est disponible
if command -v docker &> /dev/null; then
    echo "🐳 Docker détecté. Exécution de la pipeline..."
    echo ""
    echo "=== EXÉCUTION DE LA PIPELINE ==="
    ./musafirgo-pipeline
else
    echo "⚠️  Docker non détecté. La pipeline nécessite Docker pour fonctionner."
    echo "💡 Pour tester sans Docker, utilisez: ./musafirgo-pipeline http://your-api-url:8080"
fi
