# 🚀 Guide des Pipelines MusafirGO

## Vue d'ensemble

Ce guide explique comment utiliser les **pipelines automatisées** pour tester et valider votre environnement local MusafirGO.

## 🎯 Pipelines disponibles

### 1. **Pipeline Complète A à Z** (`pipeline-local-simple.ps1`)
**Utilisation recommandée pour :**
- Première configuration
- Après des modifications importantes
- Validation complète de l'environnement

**Ce qu'elle fait :**
1. ✅ Vérifie les prérequis (Docker, répertoires)
2. 🚀 Démarre l'environnement complet
3. 🧪 Exécute tous les tests
4. 📊 Génère un rapport détaillé

**Durée estimée :** 2-3 minutes

### 2. **Pipeline Rapide** (`pipeline-quick-simple.ps1`)
**Utilisation recommandée pour :**
- Vérifications quotidiennes
- Tests rapides avant développement
- Validation que tout fonctionne

**Ce qu'elle fait :**
1. 🔍 Teste les endpoints essentiels
2. 🗄️ Vérifie la base de données
3. 📊 Génère un rapport rapide

**Durée estimée :** 5-10 secondes

## 🚀 Comment utiliser

### Démarrage rapide
```powershell
# Dans le répertoire musafirgo-infra/local
.\pipeline-quick-simple.ps1
```

### Configuration complète
```powershell
# Dans le répertoire musafirgo-infra/local
.\pipeline-local-simple.ps1
```

## 📊 Interprétation des résultats

### ✅ Pipeline Réussie
```
🎉 PIPELINE RÉUSSIE !
Tous les services sont opérationnels et fonctionnels.

📈 Statistiques:
   - Étapes réussies: 8/8
   - Durée totale: 02:15
   - Statut global: SUCCESS
```

**Signification :** Tout fonctionne parfaitement ! Vous pouvez commencer à développer.

### ⚠️ Pipeline Partiellement Réussie
```
⚠️ CERTAINS TESTS ONT ÉCHOUÉ
Certains services ont des problèmes.

📈 Statistiques:
   - Étapes réussies: 6/8
   - Durée totale: 02:15
   - Statut global: FAILED
```

**Signification :** L'environnement est démarré mais certains composants ont des problèmes.

### ❌ Pipeline Échouée
```
❌ PIPELINE ÉCHOUÉE
Échec de la vérification des prérequis. Pipeline arrêtée.
```

**Signification :** Problème critique (Docker non démarré, répertoires manquants, etc.)

## 🔧 Dépannage

### Problèmes courants et solutions

#### 1. Docker non démarré
```
❌ Docker n'est pas en cours d'exécution
```
**Solution :** Démarrez Docker Desktop

#### 2. Ports déjà utilisés
```
❌ Erreur lors du démarrage des services
```
**Solution :** 
```powershell
# Arrêter les services existants
.\stop-local.ps1

# Vérifier les ports
netstat -an | findstr 8080
netstat -an | findstr 5432
```

#### 3. Tests qui échouent
```
❌ Itinerary API (Error: Le serveur distant a retourné une erreur)
```
**Solution :**
```powershell
# Vérifier les logs
docker-compose logs -f

# Redémarrer le service
docker-compose restart itinerary-service
```

## 📋 Checklist de validation

### ✅ Avant d'exécuter la pipeline
- [ ] Docker Desktop est démarré
- [ ] Vous êtes dans le répertoire `musafirgo-infra/local`
- [ ] Tous les repositories sont clonés
- [ ] PowerShell est en mode exécution autorisée

### ✅ Après une pipeline réussie
- [ ] Service accessible sur http://localhost:8080
- [ ] API Docs sur http://localhost:8080/v3/api-docs
- [ ] Swagger UI sur http://localhost:8080/swagger-ui/index.html
- [ ] Base de données PostgreSQL sur localhost:5432

## 🔄 Workflow recommandé

### Pour le développement quotidien
1. **Matin :** `.\pipeline-quick-simple.ps1` (5 secondes)
2. **Si problème :** `.\health-check.ps1` pour diagnostiquer
3. **Si nécessaire :** `.\pipeline-local-simple.ps1` pour redémarrer tout

### Pour les nouvelles fonctionnalités
1. **Avant développement :** `.\pipeline-quick-simple.ps1`
2. **Après modifications :** `.\pipeline-local.ps1`
3. **Tests spécifiques :** `.\smoke-tests.ps1`

### Pour le déploiement
1. **Validation locale :** `.\pipeline-local.ps1`
2. **Tests complets :** `.\smoke-tests.ps1`
3. **Monitoring :** `.\monitor-service.ps1`

## 🎯 Avantages des pipelines

### ✅ **Automatisation complète**
- Plus besoin de se souvenir de toutes les commandes
- Processus reproductible et fiable
- Validation automatique de chaque étape

### ✅ **Rapports clairs**
- Statut visuel de chaque composant
- Durée d'exécution mesurée
- Instructions de dépannage automatiques

### ✅ **Gain de temps**
- Pipeline rapide : 5 secondes au lieu de 2-3 minutes manuelles
- Pipeline complète : 2-3 minutes au lieu de 10-15 minutes manuelles
- Détection automatique des problèmes

### ✅ **Fiabilité**
- Tests systématiques de tous les composants
- Validation de la connectivité base de données
- Vérification des endpoints critiques

## 💡 Conseils d'utilisation

1. **Commencez toujours par la pipeline rapide** pour vérifier que tout fonctionne
2. **Utilisez la pipeline complète** uniquement quand nécessaire
3. **Consultez les logs** si des tests échouent
4. **Relancez la pipeline** après avoir résolu des problèmes
5. **Gardez la pipeline rapide** dans votre routine quotidienne

## 🆘 Support

Si vous rencontrez des problèmes :
1. **Vérifiez ce guide** et le README principal
2. **Exécutez** `.\health-check.ps1` pour diagnostiquer
3. **Consultez les logs** avec `docker-compose logs -f`
4. **Créez une issue** dans le repository `musafirgo-infra`

---

**🎉 Avec ces pipelines, vous avez maintenant un environnement local MusafirGO entièrement automatisé et fiable !**
