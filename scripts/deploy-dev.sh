#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="musafirgo-dev-rg"
LOCATION="westeurope"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
TEMPLATE_FILE="$PROJECT_ROOT/dev/iac/main.bicep"
PARAM_FILE="$PROJECT_ROOT/dev/iac/parameters.json"

echo "Vérification de la connexion à Azure..."
az account show > /dev/null 2>&1 || { echo "Faites 'az login' d'abord."; exit 1; }

echo "Vérification du groupe de ressources $RESOURCE_GROUP..."
az group create -n "$RESOURCE_GROUP" -l "$LOCATION" 1>/dev/null

echo "Déploiement (what-if)..."
az deployment group what-if \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "@$PARAM_FILE"

read -p "Confirmer le déploiement ? (y/N) " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then exit 0; fi

echo "Déploiement..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "@$PARAM_FILE"