import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dashboard_app/src/models/user_preferences.dart';
import 'package:flutter_dashboard_app/src/features/dashboard_screen.dart';
import 'package:flutter_dashboard_app/src/features/rss_feed_screen.dart';
import 'package:flutter_dashboard_app/src/features/web_radio_screen.dart';
import 'package:flutter_dashboard_app/src/features/settings_screen.dart';
import 'package:flutter_dashboard_app/src/services/preferences_service.dart';

// Import generated adapters
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart';
import 'package:flutter_dashboard_app/src/models/favorite_station.dart';

import 'package:workmanager/workmanager.dart';
import 'package:flutter_dashboard_app/src/background_tasks.dart';

// Il faut que initializeNotifications() soit définie quelque part dans ton code.
// Assure-toi qu’elle est importée ici si elle est dans un autre fichier.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive
  await Hive.initFlutter();

  // Enregistre les adaptateurs Hive
  Hive.registerAdapter(UserPreferencesAdapter());
  Hive.registerAdapter(NotepadDataAdapter());
  Hive.registerAdapter(DashboardItemAdapter());
  Hive.registerAdapter(RssFeedSourceAdapter());
  Hive.registerAdapter(RssFeedItemAdapter());
  Hive.registerAdapter(RssWidgetConfigAdapter());
  Hive.registerAdapter(FavoriteStationAdapter());

  // Ouvre les boîtes Hive
  await Hive.openBox<UserPreferences>('userPreferencesBox');
  await Hive.openBox<DashboardItem>('dashboardItemsBox');
  await Hive.openBox<RssFeedSource>('rssFeedSourcesBox');
  await Hive.openBox<RssFeedItem>('rssFeedItemsBox');
  await Hive.openBox<FavoriteStation>('favoriteStationsBox');

  // Initialise les notifications (fonction à définir)
  // await initializeNotifications();

  // Initialise Workmanager pour les tâches en arrière-plan
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // false en production
  );

  // Enregistre la tâche périodique
  Workmanager().registerPeriodicTask(
    "1",
    rssRefreshTask,
    frequency: const Duration(hours: 6),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // Charge les préférences utilisateur
  final preferencesService = PreferencesService();
  final userPreferences = await preferencesService.getUserPreferences();

  runApp(MyApp(initialThemeModeName: userPreferences.themeModeName));
}

class MyApp extends StatefulWidget {
  final String initialThemeModeName;
  const MyApp({super.key, required this.initialThemeModeName});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = _getThemeModeFromString(widget.initialThemeModeName);
  }

  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void _updateThemeMode(ThemeMode newThemeMode) {
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dashboard App',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: MainNavigationScreen(onThemeChanged: _updateThemeMode),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  const MainNavigationScreen({super.key, required this.onThemeChanged});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const DashboardScreen(),
      const RssFeedScreen(),
      const WebRadioScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.rss_feed), label: 'RSS'),
          BottomNavigationBarItem(icon: Icon(Icons.radio), label: 'Web Radio'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}