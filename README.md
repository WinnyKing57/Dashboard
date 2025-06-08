```markdown
# 📊 Flutter Dashboard App

[![AGPLv3 License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.19-blue)](https://flutter.dev)

Application Flutter modulaire offrant un tableau de bord personnel avec lecteur audio, agrégation de contenu et widgets personnalisables.

## 📌 Aperçu

<div align="center">
  <img src="assets/screenshots/dashboard.png" width="30%" alt="Dashboard">
  <img src="assets/screenshots/rss.png" width="30%" alt="Lecteur RSS"> 
  <img src="assets/screenshots/radio.png" width="30%" alt="WebRadio">
</div>

## 🚀 Fonctionnalités

### 🎯 Modules Principaux
- **🎵 Lecteur WebRadio**  
  Intégration avec `just_audio` pour le streaming audio
- **📰 Agrégateur RSS**  
  Synchronisation automatique via `webfeed`
- **🧩 Widgets Dynamiques**  
  Grille personnalisable avec `reorderable_grid_view`

### ⚙️ Infrastructure
- **🗄️ Stockage Local**  
  Gestion des données avec Hive
- **🔄 Tâches Background**  
  Actualisation périodique via `workmanager`
- **🔔 Système de Notifications**  
  Alertes et rappels personnalisés

### 🎨 Personnalisation
- Thème clair/sombre adaptable
- Disposition modifiable des widgets
- Gestion des flux RSS personnels

## 📦 Architecture Technique

```plaintext
lib/
├── src/
│   ├── core/
│   │   ├── app_widgets/    # Composants réutilisables
│   │   └── utils/          # Helpers et extensions
│   ├── features/
│   │   ├── dashboard/      # Écran principal
│   │   ├── rss/           # Module RSS
│   │   └── radio/         # Player audio  
│   ├── data/
│   │   ├── models/        # Structures Hive
│   │   └── repositories/  # Gestion des données
│   └── presentation/
│       ├── bloc/          # Gestion d'état
│       └── pages/         # Écrans
```

## 🛠 Guide d'Installation

### Prérequis
- Flutter 3.19+
- Android Studio/Xcode (pour le build natif)

### 🚀 Lancement
```bash
git clone https://github.com/WinnyKing57/Dashboard.git
cd Dashboard/flutter_dashboard_app

# Installer les dépendances
flutter pub get

# Générer le code Hive
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer en mode développement
flutter run
```

## 📜 Licence AGPLv3

Ce projet est distribué sous licence [GNU Affero General Public License v3.0](LICENSE).

**Obligations principales** :
- Toute modification doit être publiée sous la même licence
- Obligation de fournir le code source complet
- Applicable même pour une utilisation en réseau (SaaS)

```text
Copyright (C) 2024 WinnyKing57

Ce programme est libre : vous pouvez le redistribuer et/ou le modifier
selon les termes de la GNU Affero General Public License telle que publiée
par la Free Software Foundation, soit la version 3 de la Licence, soit
(à votre choix) toute version ultérieure.
```

## 🤝 Contribution

### Processus recommandé :
1. Ouvrir une issue pour discuter des changements
2. Créer une branche (`feat/feature-name` ou `fix/bug-description`)
3. Soumettre une Pull Request avec :
   - Tests unitaires pertinents
   - Documentation mise à jour
   - Exemple d'utilisation si applicable

## 📞 Support

Pour toute question :
- 📧 Email : Démarrer une conversation ()
- 🐛 [Ouvrir une issue](https://github.com/WinnyKing57/Dashboard/issues)

---

<div align="center">
  Développé avec ❤️ par <a href="https://github.com/WinnyKing57">WinnyKing57</a>
</div>
```
