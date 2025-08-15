MusafirGO — Infra (Local & Dev)

Ce dépôt gère l’infra pour MusafirGO :

Local : Docker Compose pour lancer les services sur ta machine.

Dev (cloud) : Azure Container Apps (ACA) + ACR, déployés via GitHub Actions (OIDC, sans secrets/mots de passe).

Sommaire

Prérequis

Structure

Déploiement local

Déploiement Dev (Azure)

1) Setup Azure OIDC (une seule fois)

2) Première création de l’infra Dev

3) Déployer en Dev depuis un microservice

4) Vérifier le déploiement

Bonnes pratiques & sécurité

Dépannage

Prérequis

Docker + Docker Compose

Azure CLI (az)

GitHub CLI (recommandé)

Accès Contributor sur l’abonnement Azure cible (pour la première mise en place)

Droits sur les dépôts GitHub suivants :

musafirgo-infra (ce dépôt)

musafirgo-itinerary-service (exemple de microservice)

(optionnel) musafirgo-web pour déclenchements front

Ports : par convention, musafirgo-itinerary-service écoute en 8081.

Structure
musafirgo-infra/
├─ dev/
│  └─ iac/
│     ├─ aca-dev.bicep                 # Infra ACA + ACR + Logs + UAMI
│     └─ aca-dev.parameters.json       # Paramètres (sans secrets)
├─ local/
│  └─ docker-compose.yml               # Stack locale (8081)
├─ scripts/
│  ├─ deploy-dev.sh                    # (optionnel) déploiement group (Bicep)
│  └─ setup-azure-oidc.sh              # Script pour créer l’OIDC Azure
└─ .github/
└─ workflows/
└─ aca-deploy.yml                # Workflow réutilisable pour déployer l’ACA

Déploiement local
1) Variables d’environnement (optionnel)

Créer musafirgo-infra/.env :

ITINERARY_IMAGE=ghcr.io/musafirgo/musafirgo-itinerary-service:latest
JAVA_OPTS=-XX:+UseG1GC -XX:MaxRAMPercentage=75

2) Lancer
   cd local
   docker compose up --build

3) Vérifier

Service : http://localhost:8081/api/itinerary?city=Istanbul

OpenAPI : http://localhost:8081/v3/api-docs

Swagger UI : http://localhost:8081/swagger-ui.html

Health : http://localhost:8081/actuator/health

Si le port 8081 est pris, change le mapping dans local/docker-compose.yml.

Déploiement Dev (Azure)
1) Setup Azure OIDC (une seule fois)

Objectif : permettre à GitHub Actions de se connecter à Azure sans mot de passe (OIDC).

Configurer l’App Registration + credentials fédérés pour musafirgo-infra et les services :

chmod +x scripts/setup-azure-oidc.sh
./scripts/setup-azure-oidc.sh


Ce script :

crée l’App Registration musafirgo-github-oidc,

ajoute des federated credentials pour :

musafirgo-infra@main (workflow réutilisable),

musafirgo-itinerary-service@dev (déclenchement dev),

(facultatif) musafirgo-web@dev,

attribue les rôles nécessaires (Contributor sur RG Dev, AcrPush sur ACR quand il existe).

Secrets GitHub (pas des passwords) :
Dans musafirgo-infra et dans chaque repo service, ajoute :

AZURE_CLIENT_ID = App ID renvoyé par le script

AZURE_TENANT_ID = Tenant ID

AZURE_SUBSCRIPTION_ID = Subscription ID

2) Première création de l’infra Dev

Dans musafirgo-infra, pousse dev/iac/aca-dev.bicep, dev/iac/aca-dev.parameters.json et .github/workflows/aca-deploy.yml (déjà fournis).

Note : L’ACR (musafirgoacr) sera créé par le Bicep lors du premier déploiement.
Le workflow aca-deploy.yml est réutilisable : il ne se lance pas seul.

3) Déployer en Dev depuis un microservice

Dans le repo musafirgo-itinerary-service, crée (ou garde) le workflow :

.github/workflows/dev-cd.yml :

name: Dev CD (build & deploy ACA)

on:
push:
branches: ["dev"]  # ⬅️ déclenche uniquement sur push/merge vers 'dev'
workflow_dispatch: {}

jobs:
build-push:
runs-on: ubuntu-latest
permissions:
id-token: write
contents: read
outputs:
imageRef: ${{ steps.meta.outputs.imageRef }}

    steps:
      - uses: actions/checkout@v4
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id:  ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Resolve ACR
        id: acr
        run: |
          ACR_NAME=$(az acr list --query "[?contains(name,'acr') && contains(name,'musafirgo')].name | [0]" -o tsv)
          if [ -z "$ACR_NAME" ]; then ACR_NAME="musafirgoacr"; fi
          LOGIN_SERVER=$(az acr show -n $ACR_NAME --query loginServer -o tsv || echo "$ACR_NAME.azurecr.io")
          echo "name=$ACR_NAME"   >> $GITHUB_OUTPUT
          echo "server=$LOGIN_SERVER" >> $GITHUB_OUTPUT

      - name: Set image ref
        id: meta
        run: echo "imageRef=${{ steps.acr.outputs.server }}/musafirgo-itinerary-service:${{ github.sha }}" >> $GITHUB_OUTPUT

      - name: ACR Login
        run: az acr login -n ${{ steps.acr.outputs.name }}

      - name: Build & Push Docker
        run: |
          docker build -t ${{ steps.meta.outputs.imageRef }} .
          docker push ${{ steps.meta.outputs.imageRef }}

deploy:
needs: build-push
uses: musafirgo/musafirgo-infra/.github/workflows/aca-deploy.yml@main
with:
imageRef: ${{ needs.build-push.outputs.imageRef }}
secrets: inherit


Résultat : un push/merge sur la branche dev de musafirgo-itinerary-service build l’image, la pousse sur ACR, puis appelle le workflow de musafirgo-infra qui déploie ACA avec cette image.

4) Vérifier le déploiement

À la fin du déploiement, l’action ACA Dev Deploy (Reusable) affiche l’output containerAppUrl.
Vérifie les endpoints :

https://<containerAppUrl>/api/itinerary?city=Istanbul

https://<containerAppUrl>/v3/api-docs

https://<containerAppUrl>/swagger-ui.html

https://<containerAppUrl>/actuator/health

Bonnes pratiques & sécurité

Aucun mot de passe en clair :

Connexion GitHub → Azure via OIDC (secrets courts, pas de clés stockées)

ACR admin désactivé

ACA tire les images via identité managée (AcrPull)

Branche dev = environnement Dev (déploiements auto).
main peut servir à preprod/prod plus tard, avec d’autres workflows.

Observabilité (Actuator) activée pour liveness/readiness.

Dépannage

Erreur OIDC / Forbidden :
Vérifie que le federated credential correspond bien à repo:<org>/<repo>:ref:refs/heads/dev (ou main côté infra).

ACR introuvable au premier run :
L’ACR est créé par le Bicep à la première exécution. Relance le job de build & push après le déploiement initial, puis assigne AcrPush au SP si nécessaire.

Timeout ingress :
Vérifie que le service écoute bien en 8081 et que les probes /actuator/health/liveness & /readiness répondent.

Port local occupé :
Modifie le mapping dans local/docker-compose.yml