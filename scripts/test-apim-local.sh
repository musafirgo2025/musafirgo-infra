#!/bin/bash
set -euo pipefail

echo "🧪 Test de la configuration APIM locale..."

# Vérifier que Bicep est installé
if ! command -v az bicep >/dev/null 2>&1; then
    echo "❌ Azure CLI Bicep n'est pas installé"
    echo "Installez-le avec: az bicep install"
    exit 1
fi

# Vérifier que nous sommes dans le bon répertoire
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
BICEP_FILE="$PROJECT_ROOT/dev/iac/aca-dev.bicep"
PARAM_FILE="$PROJECT_ROOT/dev/iac/aca-dev.parameters.json"

if [ ! -f "$BICEP_FILE" ]; then
    echo "❌ Fichier Bicep introuvable: $BICEP_FILE"
    exit 1
fi

if [ ! -f "$PARAM_FILE" ]; then
    echo "❌ Fichier de paramètres introuvable: $PARAM_FILE"
    exit 1
fi

echo "✅ Fichiers de configuration trouvés"

# Test de compilation Bicep
echo "🔨 Test de compilation Bicep..."
cd "$PROJECT_ROOT/dev/iac"

if az bicep build --file aca-dev.bicep --outfile aca-dev.compiled.json; then
    echo "✅ Compilation Bicep réussie"
    rm -f aca-dev.compiled.json
else
    echo "❌ Erreur de compilation Bicep"
    exit 1
fi

# Test de validation des paramètres
echo "🔍 Test de validation des paramètres..."
if az deployment group validate \
    --resource-group "test-rg" \
    --template-file aca-dev.bicep \
    --parameters @aca-dev.parameters.json \
    --parameters containerImage="test-image:latest" >/dev/null 2>&1; then
    echo "✅ Validation des paramètres réussie"
else
    echo "❌ Erreur de validation des paramètres"
    exit 1
fi

echo ""
echo "🎉 Tous les tests de configuration APIM sont passés !"
echo ""
echo "📋 Configuration APIM :"
echo "   - SKU: Consumption (pour le POC)"
echo "   - Publisher: MusafirGO Team"
echo "   - Email: dev@musafirgo.com"
echo "   - API: itinerary-api"
echo "   - Endpoint: https://musafirgo-apim.azure-api.net/api/itinerary"
echo ""
echo "🚀 Prêt pour le déploiement via GitHub Actions !"
