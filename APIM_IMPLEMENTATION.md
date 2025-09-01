# Implémentation APIM pour MusafirGO

## Vue d'ensemble

Ce document décrit l'implémentation d'Azure API Management (APIM) pour l'itinerary service dans le cadre du Sprint 1 de MusafirGO.

## Architecture

### Composants déployés

1. **Azure API Management (APIM)**
   - SKU: Consumption (optimisé pour le POC)
   - Publisher: MusafirGO Team
   - Email: dev@musafirgo.com

2. **API Itinerary**
   - Nom: `itinerary-api`
   - Version: v1
   - Endpoint: `https://musafirgo-apim.azure-api.net/api/itinerary`

3. **Politique de Mock (Sprint 1)**
   - Retourne 200 OK pour tous les appels
   - Permet de tester l'architecture sans backend réel

## Configuration Bicep

### Fichiers modifiés

- `dev/iac/aca-dev.bicep` - Ajout des ressources APIM
- `dev/iac/aca-dev.parameters.json` - Nouveaux paramètres APIM
- `dev/iac/itinerary-openapi.json` - Spécification OpenAPI

### Ressources APIM ajoutées

```bicep
// Service APIM
resource apim 'Microsoft.ApiManagement/service@2024-02-15-preview'

// API Definition
resource api 'Microsoft.ApiManagement/service/apis@2024-02-15-preview'

// Politique de Mock
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2024-02-15-preview'
```

## Déploiement

### Déclenchement automatique

Le déploiement APIM se déclenche automatiquement via GitHub Actions à chaque merge sur la branche `dev` de l'itinerary service.

### Workflow

1. **Build & Push** - Construction de l'image Docker
2. **Deploy** - Déploiement ACA + APIM via le workflow réutilisable
3. **Smoke Tests** - Tests de santé de l'API

### Prérequis

- Azure CLI avec Bicep
- Droits Contributor sur la souscription Azure
- Secrets GitHub configurés (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)

## Tests locaux

### Scripts de test

- `scripts/test-apim-local.sh` (Linux/macOS)
- `scripts/test-apim-local.ps1` (Windows)

### Validation

```bash
# Test de compilation
az bicep build --file aca-dev.bicep

# Test de validation
az deployment group validate \
  --resource-group "test-rg" \
  --template-file aca-dev.bicep \
  --parameters @aca-dev.parameters.json
```

## Endpoints disponibles

### Base URL
```
https://musafirgo-apim.azure-api.net/api/itinerary
```

### Endpoints principaux

- `GET /` - Liste des itinéraires (paginated)
- `POST /` - Créer un itinéraire
- `GET /{id}` - Récupérer un itinéraire
- `PUT /{id}` - Mettre à jour un itinéraire
- `DELETE /{id}` - Supprimer un itinéraire
- `POST /{id}/days/{day}/items` - Ajouter un item
- `DELETE /{id}/days/{day}/items/{index}` - Supprimer un item

## Politique de Mock (Sprint 1)

### Configuration

```xml
<policies>
  <inbound>
    <base />
    <!-- Mock policy for Sprint 1 - returns 200 OK -->
    <mock-response status-code="200" content-type="application/json" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
```

### Comportement

- Tous les appels retournent HTTP 200 OK
- Pas de routage vers le backend réel
- Permet de valider l'architecture APIM

## Monitoring et Logs

### Logs APIM

- Disponibles dans Azure Monitor
- Rétention configurée selon le SKU
- Métriques de performance et d'utilisation

### Métriques clés

- Nombre d'appels API
- Latence de réponse
- Taux d'erreur
- Utilisation des quotas

## Sécurité

### Niveaux de sécurité

1. **Sprint 1 (POC)**
   - APIM public sans authentification
   - Politique de mock pour les tests

2. **Sprints suivants**
   - Authentification OAuth2/JWT
   - Rate limiting
   - Politiques de sécurité avancées

### Bonnes pratiques

- Utilisation du SKU Consumption pour le POC
- Configuration des secrets via Azure Key Vault (futur)
- Monitoring des accès et utilisation

## Évolutions futures

### Sprint 2-3
- Authentification et autorisation
- Rate limiting et quotas
- Politiques de sécurité avancées

### Sprint 4-5
- Intégration avec Azure Front Door
- CDN et distribution globale
- Analytics et reporting avancés

## Dépannage

### Problèmes courants

1. **Erreur de compilation Bicep**
   - Vérifier la version d'Azure CLI
   - Installer Bicep: `az bicep install`

2. **Échec de déploiement**
   - Vérifier les droits Azure
   - Consulter les logs de déploiement

3. **API non accessible**
   - Vérifier la configuration des politiques
   - Tester l'endpoint directement

### Commandes utiles

```bash
# Vérifier le statut APIM
az apim show --name musafirgo-apim --resource-group musafirgo-dev-rg

# Lister les APIs
az apim api list --service-name musafirgo-apim --resource-group musafirgo-dev-rg

# Tester l'endpoint
curl -X GET "https://musafirgo-apim.azure-api.net/api/itinerary"
```

## Support

Pour toute question ou problème :
- Créer une issue dans le repo `musafirgo-infra`
- Contacter l'équipe DevOps
- Consulter la documentation Azure APIM
