#!/bin/bash
echo "=== MusafirGO Pipeline Go - Run Script ==="

# Vérifier si Go est installé
if ! command -v go &> /dev/null; then
    echo "❌ Go n'est pas installé. Veuillez installer Go 1.21 ou plus récent."
    echo "📥 Téléchargez Go depuis: https://golang.org/dl/"
    exit 1
fi

echo "✅ Go détecté: $(go version)"

# Télécharger les dépendances
echo "📦 Téléchargement des dépendances..."
if ! go mod tidy; then
    echo "❌ Erreur lors du téléchargement des dépendances"
    exit 1
fi

# Compiler la pipeline
echo "🔨 Compilation de la pipeline..."
if ! go build -o musafirgo-pipeline pipeline.go; then
    echo "❌ Erreur lors de la compilation"
    exit 1
fi

echo "✅ Compilation réussie!"

# Exécuter la pipeline
echo "🚀 Exécution de la pipeline..."
echo ""
./musafirgo-pipeline

echo ""
echo "✅ Pipeline exécutée avec succès!"



