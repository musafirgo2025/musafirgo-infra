# MusafirGO — Infra (Local & Dev)

Infra pour MusafirGO :
- **Local** : exécuter les services avec Docker Compose.
- **Dev (cloud)** : déployer sur **Azure Container Apps (ACA)** + **ACR**, via **GitHub Actions OIDC** (zéro mot de passe).

---

## Sommaire
- [Prérequis](#prérequis)
- [Arborescence](#arborescence)
- [Démarrage en local](#démarrage-en-local)
- [Déploiement Dev (Azure)](#déploiement-dev-azure)
   - [1) Configurer l’accès OIDC GitHub → Azure](#1-configurer-laccès-oidc-github--azure)
   - [2) Secrets GitHub à créer](#2-secrets-github-à-créer)
   - [3) Première création de l’infra Dev](#3-première-création-de-linfra-dev)
   - [4) Déployer depuis un microservice (branche `dev`)](#4-déployer-depuis-un-microservice-branche-dev)
   - [5) Vérifier le déploiement](#5-vérifier-le-déploiement)
- [Bonnes pratiques & sécurité](#bonnes-pratiques--sécurité)
- [Dépannage](#dépannage)

---

## Prérequis
- **Docker** & **Docker Compose**
- **Azure CLI** (`az`)
- Accès **Contributor** (ou Owner) sur la souscription Azure cible
- Droits sur les dépôts GitHub : `musafirgo-infra`, `musafirgo-itinerary-service` (et autres MS)
- (Optionnel) **GitHub CLI** (`gh`)

---

## Arborescence
