#!/usr/bin/env bash
# musafirgo-infra/scripts/grant-rbac-dev.sh
set -Eeuo pipefail

# === Paramètres (adapte si besoin) ===
SUB_ID="${SUB_ID:-99377697-1189-4ed3-b4b8-7397b97db025}"
RG="${RG:-musafirgo-dev-rg}"
LOCATION="${LOCATION:-westeurope}"

# App "musafirgo-github-oidc"
APP_ID="${APP_ID:-1d86482b-3996-4c60-a68f-6d2e225bcf7e}"             # == AZURE_CLIENT_ID
SP_OBJECT_ID="${SP_OBJECT_ID:-2aed59d4-8233-4f6e-930d-d2fcb2127898}" # ObjectId du Service Principal

ROLE_CONTRIBUTOR="b24988ac-6180-42a0-ab88-20f7382dd24c"

echo "==> Set subscription"
az account set --subscription "$SUB_ID"

echo "==> Ensure provider Microsoft.Authorization"
state=$(az provider show -n Microsoft.Authorization --subscription "$SUB_ID" --query registrationState -o tsv 2>/dev/null || echo "NotRegistered")
if [ "$state" != "Registered" ]; then
  az provider register -n Microsoft.Authorization --subscription "$SUB_ID" --wait
fi

echo "==> Ensure RG"
az group show -n "$RG" --subscription "$SUB_ID" >/dev/null 2>&1 || az group create -n "$RG" -l "$LOCATION" --subscription "$SUB_ID" >/dev/null
RG_ID="$(az group show -n "$RG" --subscription "$SUB_ID" --query id -o tsv)"
echo "==> Scope: $RG_ID"

# Génère un GUID pour l'assignation
if command -v uuidgen >/dev/null 2>&1; then
  ASSIGN_ID="$(uuidgen)"
else
  ASSIGN_ID="$(powershell -NoProfile -Command "[guid]::NewGuid().ToString()")"
fi
ROLE_DEF_ID="/subscriptions/${SUB_ID}/providers/Microsoft.Authorization/roleDefinitions/${ROLE_CONTRIBUTOR}"

echo "==> Create role assignment via ARM (Contributor on RG)"
BODY="{\"properties\":{\"roleDefinitionId\":\"${ROLE_DEF_ID}\",\"principalId\":\"${SP_OBJECT_ID}\",\"principalType\":\"ServicePrincipal\"}}"

az rest \
  --method PUT \
  --url "https://management.azure.com${RG_ID}/providers/Microsoft.Authorization/roleAssignments/${ASSIGN_ID}?api-version=2022-04-01" \
  --body "$BODY" \
  --headers "Content-Type=application/json"

echo '==> Verify assignments (best-effort)'
az role assignment list --subscription "$SUB_ID" --assignee "$APP_ID" --scope "$RG_ID" -o table || true

echo "✅ Done."