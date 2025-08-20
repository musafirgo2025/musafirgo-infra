#!/usr/bin/env bash
# musafirgo-infra/scripts/setup-azure-oidc.sh
set -Eeuo pipefail
trap 'echo "❌ Error line $LINENO: $BASH_COMMAND"; exit 1' ERR

log() { echo -e "==> $*"; }

# --- Variables à adapter (valeurs par défaut sûres) ---
SUB_ID="${SUB_ID:-$(az account show --query id -o tsv)}"
RG_DEV="${RG_DEV:-musafirgo-dev-rg}"
LOCATION="${LOCATION:-westeurope}"
APP_NAME="${APP_NAME:-musafirgo-github-oidc}"

# ⚠️ Owner GitHub de tes dépôts
ORG_GH="${ORG_GH:-musafirgo2025}"

# Repos & branche DEV
REPO_INFRA="${REPO_INFRA:-musafirgo-infra}"
REPO_MS_1="${REPO_MS_1:-musafirgo-itinerary-service}"
REPO_WEB="${REPO_WEB:-musafirgo-web}"
BRANCH_DEV="${BRANCH_DEV:-dev}"

# ACR (créé par le Bicep au 1er déploiement)
ACR_NAME="${ACR_NAME:-musafirgoacr}"

# -------------------------------------------------------------------
# Connexion
az account show >/dev/null || { echo "Fais d'abord: az login"; exit 1; }
log "Sélection de la subscription ${SUB_ID}…"
az account set --subscription "$SUB_ID"
log "Contexte courant : $(az account show --query '{sub:id,tenant:tenantId,name:name}' -o tsv)"

# Providers utiles
log "Enregistrement des providers nécessaires (idempotent)…"
az provider register -n Microsoft.Authorization       --subscription "$SUB_ID" --wait >/dev/null 2>&1 || true
az provider register -n Microsoft.App                 --subscription "$SUB_ID" --wait >/dev/null 2>&1 || true
az provider register -n Microsoft.ContainerRegistry   --subscription "$SUB_ID" --wait >/dev/null 2>&1 || true
az provider register -n Microsoft.OperationalInsights --subscription "$SUB_ID" --wait >/dev/null 2>&1 || true

# --- App + SP
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [[ -z "$APP_ID" ]]; then
  log "Création Azure AD App: $APP_NAME"
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
else
  log "App existante: $APP_NAME ($APP_ID)"
fi

SP_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)
if [[ -z "$SP_ID" ]]; then
  log "Création Service Principal…"
  az ad sp create --id "$APP_ID" >/dev/null
  SP_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
fi

log "APP_ID=$APP_ID"
log "SP_ID=$SP_ID"

# --- Upsert (delete/recreate si subject ne matche pas) ---
ensure_fc () {
  local NAME="$1" REPO="$2" BRANCH="$3"
  local EXPECTED_SUBJECT="repo:${ORG_GH}/${REPO}:ref:refs/heads/${BRANCH}"
  local CURRENT_SUBJECT

  CURRENT_SUBJECT=$(az ad app federated-credential list --id "$APP_ID" \
    --query "[?name=='${NAME}'] | [0].subject" -o tsv 2>/dev/null || true)

  if [[ -n "$CURRENT_SUBJECT" && "$CURRENT_SUBJECT" != "$EXPECTED_SUBJECT" ]]; then
    log "Sujet différent pour '$NAME' (${CURRENT_SUBJECT} != ${EXPECTED_SUBJECT}) → suppression"
    az ad app federated-credential delete --id "$APP_ID" --federated-credential-id "$NAME"
    CURRENT_SUBJECT=""
  fi

  if [[ -z "$CURRENT_SUBJECT" ]]; then
    log "Création credential OIDC '$NAME' → ${EXPECTED_SUBJECT}"
    local TMP; TMP="$(mktemp)"
    cat > "$TMP" <<EOF
{
  "name": "$NAME",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "${EXPECTED_SUBJECT}",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
    az ad app federated-credential create --id "$APP_ID" --parameters @"$TMP"
    rm -f "$TMP"
  else
    log "Credential '$NAME' OK (subject = ${CURRENT_SUBJECT})"
  fi
}

# Infra réutilisable depuis main, services sur dev
ensure_fc "infra-main"    "$REPO_INFRA" "main"
ensure_fc "itinerary-dev" "$REPO_MS_1"  "$BRANCH_DEV"
ensure_fc "web-dev"       "$REPO_WEB"   "$BRANCH_DEV"

# --- RG (toujours avec --subscription) ---
log "Création du Resource Group (si absent)…"
az group create -n "$RG_DEV" -l "$LOCATION" --subscription "$SUB_ID" 1>/dev/null

# --- Rôles (forcer la souscription dans la commande) ---
log "Attribution rôle Contributor sur le RG Dev…"
az role assignment create \
  --subscription "$SUB_ID" \
  --assignee-object-id "$SP_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/${SUB_ID}/resourceGroups/${RG_DEV}" \
  || log "Contributor déjà attribué (ou droits insuffisants)."

# AcrPush (si l'ACR existe déjà)
if ACR_ID=$(az acr show -n "$ACR_NAME" --subscription "$SUB_ID" --query id -o tsv 2>/dev/null); then
  log "Attribution rôle AcrPush sur $ACR_NAME…"
  az role assignment create \
    --subscription "$SUB_ID" \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "AcrPush" \
    --scope "$ACR_ID" \
    || log "AcrPush déjà attribué."
else
  log "ACR '$ACR_NAME' introuvable (créé au 1er déploiement Bicep). Refaire AcrPush après."
fi

log "✅ Fini. À mettre dans les *Repository secrets* des repos appelants :"
echo "  AZURE_CLIENT_ID=$APP_ID"
echo "  AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)"
echo "  AZURE_SUBSCRIPTION_ID=$SUB_ID"