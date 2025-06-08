# 📊 Flutter Dashboard App

[![License: AGPL v3](https://img.shields.io/badge/License-AGPLv3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.19-blue.svg)](https://flutter.dev)

Application Flutter modulaire pour tableau de bord personnel : lecteur audio, agrégateur de contenu et widgets personnalisables.

---

## 📸 Aperçu

<p align="center">
  <img src="assets/screenshots/dashboard.png" width="30%" alt="Dashboard">
  <img src="assets/screenshots/rss.png" width="30%" alt="Lecteur RSS"> 
  <img src="assets/screenshots/radio.png" width="30%" alt="WebRadio">
</p>

---

## 🚀 Fonctionnalités

### 🎯 Modules Principaux
- **🎵 Lecteur WebRadio** : Streaming audio avec `just_audio`
- **📰 Agrégateur RSS** : Récupération automatique via `webfeed`
- **🧩 Widgets Dynamiques** : Grille réorganisable avec `reorderable_grid_view`

### ⚙️ Infrastructure
- **🗄️ Stockage local** : Données persistées avec Hive
- **🔄 Tâches en arrière-plan** : Rafraîchissement avec `workmanager`
- **🔔 Notifications** : Alertes personnalisées intégrées

### 🎨 Personnalisation
- Thème clair/sombre
- Disposition des widgets modulable
- Gestion des flux RSS personnalisés

---

## 🧠 Architecture Technique

```plaintext
lib/
├── src/
│   ├── core/
│   │   ├── app_widgets/    # Composants réutilisables
│   │   └── utils/          # Fonctions utilitaires & extensions
│   ├── features/
│   │   ├── dashboard/      # Écran principal
│   │   ├── rss/            # Module RSS
│   │   └── radio/          # Lecteur audio
│   ├── data/
│   │   ├── models/         # Modèles Hive
│   │   └── repositories/   # Abstraction des données
│   └── presentation/
│       ├── bloc/           # Gestion d'état
│       └── pages/          # Écrans UI


---

🛠 Installation

✅ Prérequis

Flutter ≥ 3.19

Android Studio / Xcode


▶️ Lancement

git clone https://github.com/WinnyKing57/Dashboard.git
cd Dashboard/flutter_dashboard_app

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run


---

📄 Licence

Distribué sous la licence GNU AGPLv3.

> Résumé :

Obligation de publier les modifications sous la même licence

Code source requis même en cas d'hébergement distant (SaaS)

Protection forte de la liberté logicielle




© 2024 WinnyKing57

Ce programme est libre : vous pouvez le redistribuer et/ou le modifier selon les termes de la
GNU Affero General Public License publiée par la Free Software Foundation, version 3 ou ultérieure.


---

🤝 Contribution

1. Créer une issue pour discuter d'une amélioration ou correction


2. Utiliser une branche nommée feat/... ou fix/...


3. Soumettre une Pull Request :

Avec tests si applicable

Documentation mise à jour

Exemple ou capture d’écran si pertinent





---

📬 Support

📧 Email : à compléter

🐞 Ouvrir une issue



---

<p align="center">
  Développé avec ❤️ par <a href="https://github.com/WinnyKing57">WinnyKing57</a>
</p>
```