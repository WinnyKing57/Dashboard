Voici votre README.md corrigé avec l'orthographe et la mise en forme améliorées :

```markdown
# 📊 Flutter Dashboard App

Une application Flutter polyvalente servant de **tableau de bord personnel**, intégrant plusieurs modules fonctionnels comme un lecteur de webradio, un agrégateur RSS, des widgets personnalisables et bien plus.

---

## 🚀 Fonctionnalités

- 🎵 **WebRadio** : écoute de stations favorites via `just_audio`
- 📰 **Lecteur RSS** : agrégation de flux d'actualités (via `webfeed`), mis à jour automatiquement
- 🗂️ **Widgets personnalisables** : gestion via une grille réorganisable (`reorderable_grid_view`)
- 🧠 **Préférences utilisateur** stockées localement avec Hive
- ⏰ **Notifications locales** et rappels
- ⚙️ **Paramètres** : choix du thème clair/sombre/système
- 🛠 **Tâches en arrière-plan** : rafraîchissement périodique des flux RSS (`workmanager`)
- 📁 **Partage et sélection de fichiers**, grâce à `file_picker` et `share_plus`

---

## 📦 Structure

```
flutter_dashboard_app/
├── lib/
│   ├── src/
│   │   ├── features/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── rss_feed_screen.dart
│   │   │   ├── web_radio_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── models/        # Modèles Hive : préférences, RSS, favoris, etc.
│   │   ├── services/      # Gestion des préférences utilisateur
│   │   └── background_tasks.dart
├── pubspec.yaml
```

---

## 🛠 Installation & Exécution

1. **Cloner le dépôt** :
```bash
git clone https://github.com/WinnyKing57/Dashboard.git
cd Dashboard/flutter_dashboard_app
```

2. **Installer les dépendances** :
```bash
flutter pub get
```

3. **Générer les fichiers Hive** :
```bash
flutter pub run build_runner build
```

4. **Lancer l'application** :
```bash
flutter run
```

---

## 🔧 Personnalisation

- **Thème** : la couleur et la luminosité s'adaptent à vos préférences
- **Modularité** : ajoutez vos propres widgets dans le dashboard en modifiant la grille
- **Flux RSS** : sources personnalisables via l'interface utilisateur

---

## 📲 Captures d'écran (à ajouter)

- Dashboard principal
- Lecteur RSS
- Lecteur WebRadio
- Écran Paramètres

---

## 🧪 Tests

Exécuter les tests unitaires ou d'intégration :
```bash
flutter test
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

---

## 📃 Licence

Ajoutez un fichier `LICENSE` pour spécifier vos droits.

---

## 🤝 Contribuer

Les contributions sont les bienvenues. Ouvrez une issue ou une pull request pour toute amélioration ou correction.

---

## 👤 Auteur

Développé par [@WinnyKing57](https://github.com/WinnyKing57)
