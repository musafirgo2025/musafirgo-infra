# --- Variables à adapter ---
SUB_ID=$(az account show --query id -o tsv)
RG_DEV="musafirgo-dev-rg"
LOCATION="westeurope"
APP_NAME="musafirgo-github-oidc"
ORG_GH="musafirgo"   # organisation GitHub

# Repos (ajoute ceux que tu veux déclencher en dev)
REPO_INFRA="musafirgo-infra"
REPO_MS_1="musafirgo-itinerary-service"
REPO_WEB="musafirgo-web"  # si tu veux aussi déclencher depuis le front
BRANCH_DEV="dev"

# --- Création App + SP si pas encore créé ---
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [ -z "$APP_ID" ]; then
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
fi
SP_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)
if [ -z "$SP_ID" ]; then
  az ad sp create --id "$APP_ID" >/dev/null
  SP_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
fi
echo "APP_ID=$APP_ID"
echo "SP_ID=$SP_ID"

# --- Ajouter les credentials fédérés (OIDC) pour chaque repo/branche ---
# Sujet = repo:<org>/<repo>:ref:refs/heads/<branch>
make_fc () {
  local NAME="$1" REPO="$2" BRANCH="$3"
  cat > fc-${NAME}.json <<EOF
{
  "name": "${NAME}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${ORG_GH}/${REPO}:ref:refs/heads/${BRANCH}",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
  az ad app federated-credential create --id "$APP_ID" --parameters @fc-${NAME}.json
  rm -f fc-${NAME}.json
}

# Infra (le workflow sera appelé en reusable depuis les services)
make_fc "infra-dev" "$REPO_INFRA" "main"

# Services (déclenchement uniquement sur push/merge vers 'dev')
make_fc "itinerary-dev" "$REPO_MS_1" "$BRANCH_DEV"
make_fc "web-dev"       "$REPO_WEB"  "$BRANCH_DEV"

# --- Rôles nécessaires ---
# Le SP a besoin de 'Contributor' sur le RG pour faire les déploiements Bicep ACA.
az role assignment create \
  --assignee-object-id "$SP_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/${SUB_ID}/resourceGroups/${RG_DEV}"

# Le SP a besoin de 'AcrPush' sur l'ACR (push des images depuis les repos services).
# Si l’ACR n’existe pas encore (créé par le Bicep), tu pourras exécuter cette ligne après la 1re création :
ACR_NAME="musafirgoacr"
ACR_ID=$(az acr show -n "$ACR_NAME" --query id -o tsv 2>/dev/null || true)
if [ -n "$ACR_ID" ]; then
  az role assignment create \
    --assignee-object-id "$SP_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "AcrPush" \
    --scope "$ACR_ID"
else
  echo "ACR non trouvé pour l’instant (sera créé par le Bicep). Pense à attribuer 'AcrPush' après création."
fi
