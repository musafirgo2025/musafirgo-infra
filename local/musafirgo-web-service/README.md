# 🚀 MusafirGO Web Service Pipeline

Pipeline automatisée pour tester et valider le projet Angular MusafirGO avec services mock.

## 📋 Description

Cette pipeline teste l'application Angular MusafirGO en utilisant des services mock au lieu des microservices réels. Elle vérifie :

- ✅ **Prérequis** : Docker, Node.js, Angular CLI
- 🔨 **Build Angular** : Construction de l'application en mode production
- 🐳 **Services Mock** : Démarrage des services mock via Docker
- 🏥 **Health Checks** : Vérification de la santé des services
- 🧪 **Tests API** : Tests complets des endpoints mock
- ⚡ **Performance** : Tests de performance des endpoints
- 📊 **Rapports** : Génération de rapports HTML détaillés

## 🚀 Utilisation

### Lancement rapide
```bash
# Pipeline complète
run.bat

# Pipeline complète sans skips
run-complete.bat

# Tests uniquement (skip build)
run-tests-only.bat
```

### Lancement manuel
```bash
# Build
go build -o musafirgo-web-pipeline.exe pipeline.go

# Exécution
./musafirgo-web-pipeline.exe http://localhost:3000

# Avec options
./musafirgo-web-pipeline.exe http://localhost:3000 --skip-init --skip-data-load --skip-tests
```

## 📊 Endpoints Testés

### 🔐 Authentification
- `POST /api/auth/login` - Connexion utilisateur
- `POST /api/auth/register` - Inscription utilisateur
- `GET /api/auth/me` - Informations utilisateur actuel

### 🌍 Destinations
- `GET /api/destinations` - Liste des destinations
- `GET /api/destinations?search=Istanbul` - Recherche par nom
- `GET /api/destinations?country=Turquie` - Filtrage par pays
- `GET /api/destinations?halalFriendly=true` - Filtrage halal
- `GET /api/destinations/1` - Destination spécifique

### 🏨 Hébergements
- `GET /api/accommodations` - Liste des hébergements
- `GET /api/accommodations?search=Hotel` - Recherche par nom
- `GET /api/accommodations?location=Istanbul` - Filtrage par localisation
- `GET /api/accommodations?minPrice=50&maxPrice=200` - Filtrage par prix
- `GET /api/accommodations?halalCertified=true` - Filtrage halal certifié
- `GET /api/accommodations/1` - Hébergement spécifique

## 📈 Rapports

La pipeline génère automatiquement :

- **Rapport HTML** : `MusafirGO_Web_Pipeline_Report_YYYYMMDD_HHMMSS.html`
- **Visualisations** : Graphiques de performance et pipeline visuelle
- **Détails** : Résultats détaillés de tous les tests

## ⚙️ Configuration

### Variables d'environnement
- `BASE_URL` : URL de base de l'API mock (défaut: http://localhost:3000)
- `PROJECT_PATH` : Chemin vers le projet Angular (défaut: C:\Users\omars\workspace\musafirgo\musafirgo-web-service)

### Prérequis
- **Docker** : Pour les services mock
- **Node.js** : Pour Angular
- **Angular CLI** : Pour le build
- **Go** : Pour la pipeline

## 🔧 Développement

### Structure du projet
```
musafirgo-web-service-pipeline/
├── pipeline.go          # Code principal de la pipeline
├── go.mod              # Dépendances Go
├── run.bat             # Script de lancement
├── run-complete.bat    # Script de lancement complet
├── run-tests-only.bat  # Script de tests uniquement
└── README.md           # Documentation
```

### Ajout de nouveaux tests
1. Modifier la fonction `APITests()` dans `pipeline.go`
2. Ajouter les nouveaux endpoints dans la liste `endpoints`
3. Rebuild et tester

## 📝 Logs

La pipeline affiche des logs détaillés avec :
- **INFO** : Informations générales
- **SUCCESS** : Opérations réussies
- **ERROR** : Erreurs critiques
- **WARNING** : Avertissements

## 🐛 Dépannage

### Erreurs communes
1. **Docker non démarré** : La pipeline tentera de le démarrer automatiquement
2. **Ports occupés** : Vérifier que les ports 3000 et 4200 sont libres
3. **Dépendances manquantes** : Installer Node.js, Angular CLI, Docker

### Logs de debug
```bash
# Activer les logs détaillés
set DEBUG=1
run.bat
```

## 📞 Support

Pour toute question ou problème :
1. Vérifier les logs de la pipeline
2. Consulter le rapport HTML généré
3. Vérifier que tous les prérequis sont installés

---

**Développé pour MusafirGO** 🕌
