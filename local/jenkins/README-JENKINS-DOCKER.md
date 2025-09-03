# 🐳 Jenkins Dockerisé - Pipeline Graphique MusafirGO

## 📋 Vue d'ensemble

Ce guide vous permet de configurer Jenkins dockerisé sur votre PC Windows pour créer une pipeline graphique de votre script MusafirGO Itinerary Service.

## 🎯 Avantages Jenkins Dockerisé

- ✅ **Installation simple** avec Docker Compose
- ✅ **Pas de configuration Java** manuelle
- ✅ **Isolation complète** dans un conteneur
- ✅ **Facile à nettoyer** et redémarrer
- ✅ **Intégration Docker** native
- ✅ **Interface graphique** locale (http://localhost:8080)
- ✅ **Pipeline visuelle** avec étapes claires
- ✅ **Historique** des exécutions
- ✅ **Monitoring** en temps réel
- ✅ **Rapports** détaillés

## 🚀 Installation Rapide

### Prérequis
- Docker Desktop installé et démarré
- PowerShell 5.1+

### Étape 1 : Démarrer Jenkins
```powershell
# Dans le dossier musafirgo
.\start-jenkins-docker.ps1
```

### Étape 2 : Configuration initiale
```powershell
# Lancer le script de configuration
.\setup-jenkins-docker.ps1
```

### Étape 3 : Accès à l'interface
- Ouvrir le navigateur : http://localhost:8080
- Utiliser le mot de passe admin affiché
- Suivre les étapes de configuration

## 📊 Pipeline MusafirGO

### Étapes de la Pipeline
1. **Checkout** - Vérification de l'environnement
2. **Prerequisites** - Vérification Docker, PowerShell
3. **MusafirGO Pipeline** - Exécution du script `pipeline-complete.ps1`
4. **Results** - Analyse et archivage des résultats

### Configuration
- **Nom du job** : `MusafirGO-Pipeline`
- **Type** : Pipeline
- **Script** : Utiliser le fichier `jenkins-pipeline-docker.xml`

## 🔧 Configuration Détaillée

### 1. Créer un nouveau Job
1. Cliquer sur "New Item"
2. Nommer le job : `MusafirGO-Pipeline`
3. Sélectionner "Pipeline"
4. Cliquer "OK"

### 2. Configurer la Pipeline
1. Dans la section "Pipeline"
2. Sélectionner "Pipeline script"
3. Copier le contenu de `jenkins-pipeline-docker.xml`
4. Sauvegarder

### 3. Exécuter la Pipeline
1. Cliquer sur "Build Now"
2. Suivre l'exécution en temps réel
3. Consulter les logs et rapports

## 📈 Monitoring et Rapports

### Interface Graphique
- **Dashboard** : Vue d'ensemble des jobs
- **Build History** : Historique des exécutions
- **Console Output** : Logs détaillés
- **Test Results** : Résultats des tests

### Rapports
- **Pipeline Results** : Rapport JSON détaillé
- **HTML Reports** : Rapports visuels
- **Artifacts** : Fichiers générés

## 🛠️ Commandes Utiles

### Démarrer Jenkins
```powershell
.\start-jenkins-docker.ps1
```

### Démarrer avec agent Jenkins
```powershell
.\start-jenkins-docker.ps1 -WithAgent
```

### Forcer le redémarrage
```powershell
.\start-jenkins-docker.ps1 -Force
```

### Voir les logs
```powershell
docker-compose -f docker-compose-jenkins.yml logs -f jenkins
```

### Arrêter Jenkins
```powershell
docker-compose -f docker-compose-jenkins.yml down
```

### Redémarrer Jenkins
```powershell
docker-compose -f docker-compose-jenkins.yml restart jenkins
```

### Accéder à l'interface
- URL : http://localhost:8080
- Mot de passe admin : Affiché au démarrage

## 🔍 Dépannage

### Jenkins ne démarre pas
- Vérifier que Docker Desktop est démarré
- Vérifier que le port 8080 est libre
- Consulter les logs : `docker-compose -f docker-compose-jenkins.yml logs jenkins`

### Pipeline échoue
- Vérifier que Docker est accessible depuis Jenkins
- Vérifier que le script `pipeline-complete.ps1` existe
- Consulter les logs de la build

### Interface web inaccessible
- Vérifier l'URL : http://localhost:8080
- Vérifier que Jenkins est démarré : `docker-compose -f docker-compose-jenkins.yml ps`
- Vérifier les paramètres de pare-feu

### Problèmes de permissions Docker
- Vérifier que Docker Desktop est en cours d'exécution
- Vérifier les permissions Docker sur Windows

## 📁 Fichiers Créés

- `docker-compose-jenkins.yml` - Configuration Docker Compose
- `start-jenkins-docker.ps1` - Script de démarrage
- `setup-jenkins-docker.ps1` - Script de configuration
- `jenkins-pipeline-docker.xml` - Configuration de la pipeline
- `jenkins_home/` - Volume Docker pour les données Jenkins

## 🎯 Prochaines Étapes

1. **Configurer Jenkins** avec l'interface web
2. **Créer la pipeline** MusafirGO
3. **Exécuter** la première build
4. **Configurer** les notifications
5. **Personnaliser** les rapports

## 🔄 Comparaison : Jenkins Desktop vs Dockerisé

| Aspect | Jenkins Desktop | Jenkins Dockerisé |
|--------|----------------|-------------------|
| **Installation** | Complexe (Java + WAR) | Simple (Docker) |
| **Configuration** | Manuelle | Automatique |
| **Isolation** | Système | Conteneur |
| **Nettoyage** | Difficile | Facile |
| **Redémarrage** | Lent | Rapide |
| **Ressources** | Système | Conteneur |
| **Maintenance** | Complexe | Simple |

## 📞 Support

- **Documentation Jenkins** : https://www.jenkins.io/doc/
- **Jenkins Docker** : https://github.com/jenkinsci/docker
- **Plugins** : https://plugins.jenkins.io/
- **Community** : https://community.jenkins.io/

---

**🎉 Votre pipeline graphique MusafirGO dockerisée est prête !**
