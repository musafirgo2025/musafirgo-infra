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

# ⚠️ Owner GitHub de tes dépôts (utilisateur/organisation)
ORG_GH="${ORG_GH:-musafirgo2025}"

# Repos
REPO_INFRA="${REPO_INFRA:-musafirgo-infra}"
REPO_MS_1="${REPO_MS_1:-musafirgo-itinerary-service}"
REPO_WEB="${REPO_WEB:-musafirgo-web}"

# Branche de déploiement DEV
BRANCH_DEV="${BRANCH_DEV:-dev}"

# ACR (créé par le Bicep au 1er déploiement)
ACR_NAME="${ACR_NAME:-musafirgoacr}"

# -------------------------------------------------------------------
# Prérequis
az account show >/dev/null || { echo "Fais d'abord: az login"; exit 1; }

# --- Création App + SP si besoin ---
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
log "SUB_ID=$SUB_ID"

# --- Federated credentials (OIDC) ---
make_fc () {
  local NAME="$1" REPO="$2" BRANCH="$3"
  local TMP; TMP="$(mktemp)"
  cat > "$TMP" <<EOF
{
  "name": "$NAME",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${ORG_GH}/${REPO}:ref:refs/heads/${BRANCH}",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
  log "Ajout credential OIDC: $NAME pour ${ORG_GH}/${REPO}@${BRANCH}"
  az ad app federated-credential create --id "$APP_ID" --parameters @"$TMP" \
    || log "Credential '$NAME' déjà existant — on continue."
  rm -f "$TMP"
}

# Infra réutilisable depuis main, services déclenchés sur dev
make_fc "infra-main"     "$REPO_INFRA" "main"
make_fc "itinerary-dev"  "$REPO_MS_1"  "$BRANCH_DEV"
make_fc "web-dev"        "$REPO_WEB"   "$BRANCH_DEV" || true

# --- Rôles nécessaires ---
log "Sélection de la subscription…"
az account set --subscription "$SUB_ID"
az account show -o table

log "Création du Resource Group (si absent)…"
az group create -n "$RG_DEV" -l "$LOCATION" 1>/dev/null

log "Attribution rôle Contributor sur le RG Dev…"
az role assignment create \
  --assignee-object-id "$SP_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/${SUB_ID}/resourceGroups/${RG_DEV}" \
  || log "Contributor déjà attribué ou droits insuffisants (vérifie ta permission)."

# AcrPush (si l'ACR existe déjà)
if ACR_ID=$(az acr show -n "$ACR_NAME" --query id -o tsv 2>/dev/null); then
  log "Attribution rôle AcrPush sur $ACR_NAME…"
  az role assignment create \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "AcrPush" \
    --scope "$ACR_ID" \
    || log "AcrPush déjà attribué."
else
  log "ACR '$ACR_NAME' introuvable (créé au 1er déploiement Bicep). Refaire AcrPush après."
fi

log "✅ Fini. Ajoute ces secrets dans chaque repo *appelant* (service/front):"
echo "  AZURE_CLIENT_ID=$APP_ID"
echo "  AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)"
echo "  AZURE_SUBSCRIPTION_ID=$SUB_ID"
