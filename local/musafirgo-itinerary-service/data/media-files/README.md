# 📁 Dossier des Fichiers Médias de Test

Ce dossier contient les fichiers de test pour les médias (photos et vidéos) associés aux itinéraires.

## 📋 Structure

```
media-files/
├── README.md                    # Ce fichier
├── casablanca/                  # Médias pour Casablanca
│   ├── mosquee-hassan-ii.jpg
│   └── corniche.mp4
├── marrakech/                   # Médias pour Marrakech
│   ├── jemaa-el-fnaa.jpg
│   ├── souks.jpg
│   └── atlas-trekking.mp4
├── fes/                        # Médias pour Fès
│   └── tanneries.jpg
├── chefchaouen/                # Médias pour Chefchaouen
│   ├── blue-streets.jpg
│   └── cascades-akchour.jpg
└── essaouira/                  # Médias pour Essaouira
    ├── ramparts.jpg
    └── surf-session.mp4
```

## 🎯 Utilisation

Ces fichiers sont utilisés pour :
- Tester l'upload de médias
- Valider la gestion des fichiers
- Simuler des scénarios réels d'utilisation

## 📝 Notes

- Les fichiers sont montés en lecture seule dans le conteneur
- Les URLs dans la base de données pointent vers Azure Blob Storage
- Les fichiers locaux servent uniquement pour les tests

## 🔧 Configuration

Les fichiers sont montés dans le conteneur via docker-compose.yml :
```yaml
volumes:
  - ./data/media-files:/app/media:ro
```
