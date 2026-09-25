# 👁️ Vision Quest — Application de Rééducation Visuelle Flutter

Application mobile gamifiée de rééducation orthoptique pour enfants atteints de troubles de la vision binoculaire (amblyopie, strabisme, insuffisance de convergence, etc.).

---

## 🏗️ Architecture du projet

```
lib/
├── main.dart                          # Point d'entrée, Provider setup
├── models/
│   └── models.dart                    # Exercise, UserProfile, ExerciseResult
├── services/
│   └── user_service.dart              # Persistence SharedPreferences, logique XP/niveaux
├── utils/
│   └── app_theme.dart                 # Couleurs, gradients, ThemeData
├── widgets/
│   └── neon_button.dart               # NeonButton + OutlineNeonButton réutilisables
└── screens/
    ├── splash_screen.dart             # Splash animé
    ├── onboarding_screen.dart         # Création de profil (4 étapes)
    ├── home_screen.dart               # Écran principal : grille d'exercices + mission
    ├── exercise_screen.dart           # Fiche détail + lancement
    ├── stats_screen.dart              # Statistiques et progression
    └── exercises/
        ├── base_exercise.dart         # Mixin générique : timer, HUD, overlay résultat
        ├── stereogram_exercise.dart   # 🔴🟢 Fusion binoculaire / orbes laser
        ├── convergence_exercise.dart  # ⭐ Suivi de convergence (étoile vers le nez)
        ├── saccade_exercise.dart      # ☄️ Saccades oculaires (astéroïdes à toucher)
        ├── pursuit_exercise.dart      # 🚀 Poursuite lisse (vaisseau orbital)
        ├── patch_exercise.dart        # 👁️ Occlusion monoculaire (puzzles QCM)
        └── fusion_exercise.dart       # 🌀 Fusion binoculaire (images œil droit/gauche)
```

---

## 🎮 Exercices implémentés

| Exercice | Type clinique | Mécanique de jeu |
|----------|--------------|------------------|
| **Orbes Laser** | Stéréogramme / fusion | Fais converger 2 orbes lumineux, détecte la fusion centrale |
| **Attrape l'Étoile** | Convergence | Suis une étoile qui se rapproche de ton nez sur 4 cycles |
| **Chasseur d'Astéroïdes** | Saccades oculaires | Touche les cibles qui apparaissent aléatoirement (tap) |
| **Pilote Stellaire** | Poursuite lisse | Garde le doigt sur le vaisseau en orbite (drag) |
| **Mission Œil Gauche** | Occlusion monoculaire | Puzzles QCM avec l'œil fort masqué |
| **Fusion Galactique** | Fusion binoculaire | Superpose deux images (rivalité binoculaire) |
| **Portail Dimensionnel** | Stéréogramme avancé | Fusion niveau difficile |
| **Défense Planétaire** | Saccades multi-cibles | 3 cibles simultanées, vitesse x2 |

---

## 🚀 Installation & lancement

### Prérequis
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android Studio / Xcode pour émulateur

### Démarrage rapide

```bash
# Cloner le projet
git clone <repo-url>
cd vision_quest

# Installer les dépendances
flutter pub get

# Lancer en mode debug
flutter run

# Build Android release
flutter build apk --release

# Build iOS release
flutter build ios --release
```

---

## 🎨 Design System

### Palette "Espace Bioluminescent"

| Token | Hex | Usage |
|-------|-----|-------|
| `bgDeep` | `#0A0E2E` | Fond principal |
| `bgCard` | `#141842` | Cartes / overlays |
| `accentCyan` | `#00E5FF` | Primaire, stéréogrammes |
| `accentGreen` | `#39FF14` | Succès, convergence |
| `accentPurple` | `#9B59FF` | Fusion, XP |
| `accentGold` | `#FFD700` | Score, étoiles |
| `accentRed` | `#FF3B5C` | Saccades, patch, alertes |

### Principes UX
- **Rétroaction haptique** à chaque action (HapticFeedback)
- **Animations spring** pour les boutons (élasticité)
- **Countdown 3-2-1** avant chaque exercice
- **Résultat avec étoiles** (1-3) et overlay animé
- **Système d'énergie** (12/jour) pour limiter la fatigue oculaire
- **Mission quotidienne** : 3 exercices/jour

---

## 📊 Système de progression

```
Score → XP → Niveau
  └─ level * 1000 XP pour passer au niveau suivant
  └─ Combo multiplier : +10% par frappe consécutive

Étoiles par exercice :
  ⭐⭐⭐  ≥ 85% du score max
  ⭐⭐    ≥ 50%
  ⭐      < 50%
```

---

## 🏥 Note clinique

Cette application est un **outil de rééducation complémentaire** destiné à être utilisé sous la supervision d'un orthoptiste. Elle ne remplace pas les séances orthoptiques professionnelles.

**Conditions ciblées :**
- Amblyopie (œil paresseux)
- Strabisme convergent / divergent
- Insuffisance de convergence
- Troubles de la fusion binoculaire
- Astigmatisme avec amblyopie associée

**Recommandations d'usage :**
- Sessions de 15-20 min/jour maximum
- Respecter le système d'énergie (12 exercices/jour)
- Consulter l'orthoptiste toutes les 4-6 semaines

---

## 🔧 Dépendances principales

```yaml
provider: ^6.1.1          # State management
flutter_animate: ^4.5.0   # Animations déclaratives
shared_preferences: ^2.2.2 # Persistence locale
sensors_plus: ^4.0.2      # Gyroscope / accéléromètre
vibration: ^1.9.0         # Retour haptique riche
fl_chart: ^0.68.0         # Graphiques statistiques
```

---

## 📱 Screens & navigation

```
SplashScreen (2.8s)
    │
    ├── OnboardingScreen (nouveau profil)
    │       └── HomeScreen
    │
    └── HomeScreen (profil existant)
            ├── ExerciseScreen (fiche)
            │       └── [ExerciseType]Exercise
            │               └── ResultOverlay → HomeScreen
            └── StatsScreen
```

---

## 🔮 Prochaines fonctionnalités

- [ ] Stéréogrammes SIRDS générés algorithmiquement
- [ ] Mode anaglyphe (rouge/cyan avec lunettes)
- [ ] Rapport PDF exportable pour l'orthoptiste
- [ ] Mode multijoueur parent/enfant
- [ ] Notifications de rappel quotidien
- [ ] Calibration de la distance téléphone-yeux
- [ ] Exercices de lecture (dyslexie associée)
- [ ] Intégration caméra (eye tracking simplifié)
