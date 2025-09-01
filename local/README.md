# Environnement Local MusafirGO

Cet environnement local permet de faire tourner tous les services MusafirGO sur votre PC Windows avec Docker.

## 🚀 Démarrage rapide

### Prérequis
- **Docker Desktop** installé et en cours d'exécution
- **PowerShell** (inclus avec Windows 10/11)
- **Git** pour cloner les repositories

### 1. Démarrer l'environnement
```powershell
# Dans le répertoire musafirgo-infra/local
.\start-local.ps1
```

### 2. Vérifier la santé des services
```powershell
.\health-check.ps1
```

### 3. Arrêter l'environnement
```powershell
.\stop-local.ps1
```

### 4. Tests et monitoring
```powershell
# 🚀 PIPELINES COMPLÈTES (RECOMMANDÉ)
.\pipeline-local-simple.ps1   # Pipeline complète A à Z
.\pipeline-quick-simple.ps1   # Pipeline rapide (5 secondes)

# 🧪 TESTS INDIVIDUELS
.\run-tests.ps1               # Menu principal des tests
.\quick-test-simple.ps1       # Test rapide des endpoints
.\smoke-tests.ps1             # Tests complets (smoke tests)
.\monitor-service.ps1         # Monitoring continu
```

## 📋 Services disponibles

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| **Itinerary Service** | 8080 | http://localhost:8080 | API Java Spring Boot |
| **PostgreSQL** | 5432 | localhost:5432 | Base de données |
| **Adminer** | 8081 | http://localhost:8081 | Interface d'administration DB |

## 🧪 Tests et Monitoring

### Scripts de test disponibles
- **`pipeline-local-simple.ps1`** - 🚀 Pipeline complète A à Z (démarrage + tests)
- **`pipeline-quick-simple.ps1`** - ⚡ Pipeline rapide pour vérifications quotidiennes (5 secondes)
- **`run-tests.ps1`** - 🧪 Menu principal avec tous les types de tests
- **`quick-test-simple.ps1`** - Test rapide des endpoints essentiels
- **`smoke-tests.ps1`** - Tests complets avec retry et validation complète
- **`monitor-service.ps1`** - Monitoring continu avec statistiques
- **`test-config.json`** - Configuration des tests et endpoints

### Exécution des tests
```powershell
# 🚀 PIPELINES (RECOMMANDÉ)
.\pipeline-local-simple.ps1   # Pipeline complète A à Z
.\pipeline-quick-simple.ps1   # Pipeline rapide quotidienne

# 🧪 TESTS INDIVIDUELS
.\run-tests.ps1               # Menu principal des tests
.\quick-test-simple.ps1       # Test rapide quotidien
.\smoke-tests.ps1             # Tests complets avant déploiement
.\monitor-service.ps1         # Monitoring en continu (Ctrl+C pour arrêter)
```

## 🔧 Commandes utiles

### Docker Compose
```bash
# Voir le statut des services
docker-compose ps

# Voir les logs en temps réel
docker-compose logs -f

# Redémarrer un service
docker-compose restart itinerary-service

# Redémarrer tous les services
docker-compose restart

# Arrêter tous les services
docker-compose down
```

### Logs spécifiques
```bash
# Logs de l'itinerary service
docker logs musafirgo-itinerary-app

# Logs de PostgreSQL
docker logs musafirgo-itinerary-postgres

# Logs en temps réel
docker logs -f musafirgo-itinerary-app
```

## 🌐 Test de l'API

### Health Check
```bash
curl http://localhost:8080/actuator/health
```

### Documentation OpenAPI
- **Swagger UI** : http://localhost:8080/swagger-ui/index.html
- **OpenAPI JSON** : http://localhost:8080/v3/api-docs

### Test d'un endpoint
```bash
# Créer un itinéraire
curl -X POST http://localhost:8080/api/itinerary \
  -H "Content-Type: application/json" \
  -d '{
    "city": "Casablanca",
    "startDate": "2025-01-15",
    "endDate": "2025-01-17"
  }'
```

## 🗄️ Base de données

### Connexion
- **Host** : localhost
- **Port** : 5432
- **Database** : itinerarydb
- **Username** : itinerary
- **Password** : itinerary

### Interface d'administration
Ouvrez http://localhost:8081 dans votre navigateur pour accéder à Adminer.

### Données persistantes
Les données sont stockées dans le volume Docker `pgdata` et persistent entre les redémarrages.

## 🔍 Dépannage

### Service ne démarre pas
1. Vérifiez que Docker Desktop est en cours d'exécution
2. Vérifiez les logs : `docker-compose logs`
3. Vérifiez les ports disponibles : `netstat -an | findstr 8080`

### Base de données inaccessible
1. Vérifiez que PostgreSQL est démarré : `docker-compose ps postgres`
2. Vérifiez les logs PostgreSQL : `docker logs musafirgo-itinerary-postgres`
3. Vérifiez la santé : `docker exec musafirgo-itinerary-postgres pg_isready -U itinerary -d itinerarydb`

### Itinerary service ne répond pas
1. Vérifiez que le service est démarré : `docker-compose ps itinerary-service`
2. Vérifiez les logs : `docker logs musafirgo-itinerary-app`
3. Vérifiez la santé : http://localhost:8080/actuator/health

## 📁 Structure des fichiers

```
local/
├── docker-compose.yml          # Configuration des services
├── .env                        # Variables d'environnement
├── start-local.ps1            # Script de démarrage
├── stop-local.ps1             # Script d'arrêt
├── health-check.ps1           # Script de vérification
├── pipeline-local-simple.ps1  # 🚀 Pipeline complète A à Z
├── pipeline-quick-simple.ps1  # ⚡ Pipeline rapide quotidienne
├── run-tests.ps1              # 🧪 Menu principal des tests
├── quick-test-simple.ps1      # Tests rapides
├── smoke-tests.ps1            # Tests complets (smoke tests)
├── monitor-service.ps1        # Monitoring continu
├── test-config.json           # Configuration des tests
├── README.md                  # Ce fichier
├── logs/                      # Logs des services (créé automatiquement)
└── init-scripts/              # Scripts d'initialisation DB (optionnel)
```

## 🔄 Redémarrage complet

Si vous rencontrez des problèmes, vous pouvez faire un redémarrage complet :

```powershell
# 1. Arrêter tous les services
.\stop-local.ps1

# 2. Nettoyer Docker (optionnel)
docker system prune -f

# 3. Redémarrer
.\start-local.ps1
```

## 📚 Ressources utiles

- [Documentation Docker Compose](https://docs.docker.com/compose/)
- [Documentation PostgreSQL](https://www.postgresql.org/docs/)
- [Documentation Spring Boot](https://spring.io/projects/spring-boot)
- [Adminer - Interface DB](https://www.adminer.org/)

## 📚 Documentation complète

- **`PIPELINE_GUIDE.md`** - Guide détaillé des pipelines automatisées
- **`README.md`** - Ce fichier (vue d'ensemble)

## 🆘 Support

Pour toute question ou problème :
1. Vérifiez les logs des services
2. Consultez ce README et le guide des pipelines
3. Créez une issue dans le repository `musafirgo-infra`
