# 📊 Flutter Dashboard App

[![Build Status](https://github.com/WinnyKing57/Dashboard/actions/workflows/flutter.yml/badge.svg)](https://github.com/WinnyKing57/Dashboard/actions/workflows/flutter.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPLv3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.19-blue.svg)](https://flutter.dev)

Application Flutter modulaire pour tableau de bord personnel : lecteur audio, agrégateur de contenu et widgets personnalisables.

---

## 📸 Aperçu

| Tableau de bord | Lecteur RSS | WebRadio |
|:---------------:|:-----------:|:--------:|
| ![Dashboard](assets/screenshots/dashboard.png) | ![RSS](assets/screenshots/rss.png) | ![Radio](assets/screenshots/radio.png) |

---

## 🚀 Fonctionnalités

### 🎯 Modules principaux
- **🎵 Lecteur WebRadio** — Streaming avec `just_audio`
- **📰 Agrégateur RSS** — Synchronisation via `webfeed`
- **🧩 Widgets dynamiques** — Grille personnalisable avec `reorderable_grid_view`

### ⚙️ Infrastructure
- **🗄️ Stockage local** — Persisté avec Hive
- **🔄 Tâches en arrière-plan** — `workmanager` pour actualisation périodique
- **🔔 Notifications** — Alertes locales et rappels

### 🎨 Personnalisation
- Thème clair / sombre
- Disposition des widgets
- Flux RSS configurables

---

## 🧠 Architecture technique

lib/ ├── src/ │   ├── core/ │   │   ├── app_widgets/    # Composants réutilisables │   │   └── utils/          # Fonctions utilitaires │   ├── features/ │   │   ├── dashboard/      # Écran principal │   │   ├── rss/            # Module RSS │   │   └── radio/          # Lecteur audio │   ├── data/ │   │   ├── models/         # Modèles Hive │   │   └── repositories/   # Accès aux données │   └── presentation/ │       ├── bloc/           # Gestion d'état │       └── pages/          # Écrans UI

---

## 🛠 Installation

### ✅ Prérequis
- Flutter ≥ 3.19
- Android Studio / Xcode

### ▶️ Démarrage

```bash
git clone https://github.com/WinnyKing57/Dashboard.git
cd Dashboard/flutter_dashboard_app

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

📄 Licence

Ce projet est distribué sous la licence GNU AGPLv3.

> Résumé des obligations :

Toute modification doit être publiée sous la même licence

Fourniture du code source intégral

Valable même pour les services hébergés (SaaS)




© 2024 WinnyKing57

Ce programme est libre : vous pouvez le redistribuer et/ou le modifier selon les termes
de la GNU Affero General Public License, version 3 ou ultérieure, publiée par la Free Software Foundation.


---

🤝 Contribution

1. Créer une issue pour discuter d’une amélioration ou correction


2. Créer une branche feat/nom-fonctionnalité ou fix/description-bug


3. Ouvrir une Pull Request contenant :

Tests si applicables

Documentation mise à jour

Exemple d’utilisation ou capture si nécessaire

---

📬 Support

🐞 Signaler un bug ou une suggestion

---
```bash
<p align="center">
  Développé avec ❤️ par <a href="https://github.com/WinnyKing57">WinnyKing57</a>
</p>
```