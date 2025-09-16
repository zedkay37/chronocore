# Focus World - Application Flutter de Productivité Gamifiée

## Vue d'ensemble

Focus World est une application Flutter qui combine productivité et gamification dans un concept unique d'idle/rogue-lite 2.5D. L'utilisateur utilise des sessions Pomodoro et la marche pour générer des "Fragments de Temps" (FT) qui débloquent du contenu dans un monde mystérieux.

### Concept Central
- **Ressource unique** : Fragments de Temps (FT)
- **Génération** : Sessions Pomodoro (25/45/90 min) + Marche (podomètre)
- **Utilisation** : Déverrouillage de contenu, temps de jeu actif
- **Style** : Interface sans bordures, couleurs adaptatives au thème

## Architecture Implémentée

### Stack Technologique
- **Framework** : Flutter 3.9+
- **Gestion d'état** : Provider
- **Stockage** : SQLite (sqflite) + SharedPreferences
- **Sensors** : pedometer, permission_handler
- **Design** : Material 3 avec thème adaptatif

### Modules Principaux

#### 1. **Services Core (`lib/services/`)**
- `GameService` : Orchestration générale du jeu
- `TimeFragmentService` : Gestion des FT avec validation
- `StorageService` : Persistence SQLite et SharedPreferences

#### 2. **Modules Métier (`lib/modules/`)**
- **Pomodoro** : `PomodoroTimer` + `FocusTracker` avec proof-of-focus
- **Pedometer** : `StepCounter` + `StepValidator` avec anti-triche

#### 3. **Modèles de Données (`lib/models/`)**
- `TimeFragment` : Ressource centrale avec métadonnées
- `PomodoroSession` : Session avec tracking du focus
- `WorldState` : État du monde 2.5D avec tuiles révélées
- `PlayerProgress` : Progression avec achievements
- `CombatStats` : Statistiques de combat
- `GameSave` : Sauvegarde complète

#### 4. **Interface Utilisateur (`lib/screens/` + `lib/widgets/`)**
- **HomeScreen** : Hub principal avec onglets
- **PomodoroScreen** : Timer avec progression circulaire
- **WorldScreen** : Carte 2.5D simplifiée avec exploration
- **Widgets** : Composants réutilisables avec design adaptatif

## Fonctionnalités Implémentées

### ✅ Core Gameplay
- [x] Sessions Pomodoro (25/45/90 min) avec proof-of-focus
- [x] Génération de FT : 1 FT/minute + bonus fin de session
- [x] Tracking des pas avec validation anti-triche (100 pas = 1 FT)
- [x] Économie FT : achat de temps d'exploration (10 FT = 1 min)

### ✅ Système de Monde
- [x] Carte 2.5D avec grille 5x5 représentant le monde
- [x] Révélation progressive de tuiles via TimeLapse
- [x] Types de tuiles : terrain, forêt, eau, stèles, ponts, reliques, portails boss
- [x] Mode exploration actif vs mode idle

### ✅ Progression
- [x] Système d'achievements avec récompenses FT
- [x] Niveaux de monde avec progression
- [x] Statistiques détaillées (sessions, pas, FT)
- [x] Sauvegarde automatique toutes les 30s

### ✅ Interface Utilisateur
- [x] Design sans bordures selon préférences utilisateur
- [x] Couleurs adaptatives au thème clair/sombre
- [x] Animations fluides (pulse, scale, gradients)
- [x] Navigation par onglets (Hub, Pomodoro, Monde)
- [x] Feedback visuel pour les actions

## Règles de Jeu

### Génération de FT
- **Pomodoro** : 1 FT par minute + 5 FT bonus si session complète
- **Marche** : 1 FT pour 100 pas (max 20,000 pas/jour comptabilisés)
- **Échec** : 0 FT si l'app est quittée > 30 secondes
- **Bonus quotidien** : +10 FT pour 10,000 pas

### Utilisation des FT
- **Exploration** : 10 FT = 1 minute (cap 45 min/jour)
- **Révélation tuiles** : 20-500 FT selon le type
- **TimeLapse** : Automatique après sessions Pomodoro

### Progression
- **Ratio temps** : 1h focus = 15 min exploration
- **Achievements** : Premier pas, Marcheur, Explorateur, Maître du temps, Vainqueur
- **Mondes** : Plaines Oubliées → Forêt Temporelle → Ruines Mystiques → Pic Éternel

## Installation et Lancement

### Prérequis
```bash
# Vérifier Flutter
flutter doctor

# Version requise
Flutter >= 3.9.0
Dart >= 3.0.0
```

### Installation
```bash
# Cloner le projet
git clone <repository>
cd Chronocore

# Installer les dépendances
flutter pub get

# Lancer en mode debug
flutter run

# Builder pour Android
flutter build apk --debug
```

### Permissions Requises
- **Reconnaissance d'activité** : Pour le podomètre
- **Stockage** : Pour la sauvegarde SQLite

## Structure des Fichiers

```
lib/
├── main.dart                 # Point d'entrée avec providers
├── models/                   # Modèles de données
│   ├── time_fragment.dart
│   ├── pomodoro_session.dart
│   ├── world_state.dart
│   ├── player_progress.dart
│   ├── combat_stats.dart
│   └── game_save.dart
├── services/                 # Services core
│   ├── game_service.dart
│   ├── time_fragment_service.dart
│   └── storage_service.dart
├── modules/                  # Modules métier
│   ├── pomodoro/
│   │   ├── pomodoro_timer.dart
│   │   └── focus_tracker.dart
│   └── pedometer/
│       ├── step_counter.dart
│       └── step_validator.dart
├── screens/                  # Écrans principaux
│   ├── home_screen.dart
│   ├── pomodoro_screen.dart
│   └── world_screen.dart
└── widgets/                  # Composants réutilisables
    ├── time_fragment_display.dart
    └── pomodoro_timer_widget.dart
```

## Fonctionnalités à Implémenter

### 🚧 Système de Combat (Prévu)
- Combat par vagues avec ennemis progressifs
- Mécaniques rogue-lite avec soutien tactique
- Boss de fin de monde

### 🚧 Monde 2.5D Avancé (Prévu)
- Intégration Flame Engine pour rendu isométrique
- Animations TimeLapse plus sophistiquées
- Interactions avec structures (stèles, ponts, reliques)

### 🚧 Améliorations UX (Prévu)
- Notifications push pour rappels
- Vibrations haptiques
- Sons et musique d'ambiance
- Écran de settings complet

## Notes Techniques

### Conformité aux Préférences Utilisateur
- ✅ Interface sans bordures (BorderRadius.circular au lieu de Border)
- ✅ Couleurs adaptatives (theme.colorScheme au lieu de couleurs hardcodées)
- ✅ Design épuré pour mode sombre

### Anti-Triche Implémenté
- Validation des pas (max 200/min, 20k/jour)
- Proof-of-focus pour Pomodoro (échec si app quittée > 30s)
- Filtrage des données anormales

### Performance
- Sauvegarde automatique toutes les 30s
- Nettoyage des données anciennes (30 jours)
- Gestion mémoire optimisée

## Conclusion

Focus World implémente avec succès un système de productivité gamifiée unique, combinant sessions Pomodoro et activité physique dans un monde mystérieux à explorer. L'architecture modulaire permet une extension facile vers les fonctionnalités avancées prévues (combat, Flame Engine, etc.).

L'application respecte parfaitement les préférences utilisateur pour un design sans bordures et des couleurs adaptatives, offrant une expérience utilisateur cohérente et moderne.
