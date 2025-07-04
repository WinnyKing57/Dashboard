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
  // final preferencesService = PreferencesService(); // No longer needed here
  // final userPreferences = await preferencesService.getUserPreferences(); // No longer needed here

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // final String initialThemeModeName; // Removed
  const MyApp({super.key}); // Removed required this.initialThemeModeName

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late Color _currentColorSeed; // Added state variable for color seed
  late PreferencesService _preferencesService; // Added PreferencesService instance

  @override
  void initState() {
    super.initState();
    _preferencesService = PreferencesService(); // Initialize PreferencesService
    UserPreferences prefs = _preferencesService.getUserPreferences();
    _themeMode = _getThemeModeFromString(prefs.themeModeName); // Use loaded themeModeName

    // Initialize _currentColorSeed
    if (prefs.colorSeedValue != null) {
      _currentColorSeed = Color(prefs.colorSeedValue!);
    } else {
      _currentColorSeed = Colors.blue; // Default seed color
    }
  }

  Future<void> _updateColorSeed(Color newColor) async {
    if (_currentColorSeed != newColor) {
      setState(() {
        _currentColorSeed = newColor;
      });
      await _preferencesService.setColorSeedValue(newColor.value);
    }
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
      title: 'WinBoard',
      theme: ThemeData(
        colorSchemeSeed: _currentColorSeed, // Use state variable
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: _currentColorSeed, // Use state variable
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: MainNavigationScreen(
        onThemeChanged: _updateThemeMode,
        onColorSeedChanged: _updateColorSeed, // Add this line
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(Color) onColorSeedChanged; // Add this line

  const MainNavigationScreen({
    super.key,
    required this.onThemeChanged,
    required this.onColorSeedChanged, // Add this line
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class ScreenConfig {
  final String title;
  final Widget screenWidget;
  final List<Widget> appBarActions; // List of actions for the AppBar

  ScreenConfig({
    required this.title,
    required this.screenWidget,
    this.appBarActions = const [], // Default to no actions
  });
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey<DashboardScreenState> _dashboardScreenKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<RssFeedScreenState> _rssFeedScreenKey = GlobalKey<RssFeedScreenState>(); // Added GlobalKey for RSS

  late final List<ScreenConfig> _screenConfigurations; // New configuration list

  @override
  void initState() {
    super.initState();
    _screenConfigurations = <ScreenConfig>[
      ScreenConfig(
        title: 'Dashboard',
        screenWidget: DashboardScreen(key: _dashboardScreenKey), // Pass the key
        appBarActions: <Widget>[
          Builder(
            builder: (context) => PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              onSelected: (value) {
                if (value == 'add_dynamic_label') {
                  _dashboardScreenKey.currentState?.callAddDynamicLabelWidget();
                } else if (value == 'add_notepad') {
                  _dashboardScreenKey.currentState?.callAddNotepadWidget();
                } else if (value == 'add_placeholder') {
                  _dashboardScreenKey.currentState?.callAddPlaceholder();
                } else if (value == 'add_rss_summary') {
                  _dashboardScreenKey.currentState?.callAddRssSummaryWidget();
                } else if (value == 'add_webradio_status') {
                  _dashboardScreenKey.currentState?.callAddWebRadioStatusWidget();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'add_dynamic_label', child: Text('Add Dynamic Label')),
                const PopupMenuItem<String>(value: 'add_notepad', child: Text('Add Notepad')),
                const PopupMenuItem<String>(value: 'add_placeholder', child: Text('Add Placeholder')),
                const PopupMenuItem<String>(value: 'add_rss_summary', child: Text('Add RSS Summary')),
                const PopupMenuItem<String>(value: 'add_webradio_status', child: Text('Add WebRadio Status')),
              ],
            ),
          ),
        ],
      ),
      ScreenConfig(
        title: 'RSS Feeds',
        screenWidget: RssFeedScreen(key: _rssFeedScreenKey), // Pass the key
        appBarActions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Feed Source',
              onPressed: () {
                _rssFeedScreenKey.currentState?.callAddFeedSourceDialog();
              },
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh All Feeds',
              onPressed: () {
                _rssFeedScreenKey.currentState?.callRefreshAllFeeds();
              },
            ),
          ),
        ],
      ),
      ScreenConfig(
        title: 'Web Radio',
        screenWidget: const WebRadioScreen(),
      ),
      ScreenConfig(
        title: 'Settings',
        screenWidget: SettingsScreen(
          onThemeChanged: widget.onThemeChanged,
          onColorSeedChanged: widget.onColorSeedChanged,
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenConfigurations[_selectedIndex].title), // Use title from config
        actions: _screenConfigurations[_selectedIndex].appBarActions, // Use actions from config
      ),
      body: Center(child: _screenConfigurations[_selectedIndex].screenWidget), // Use widget from config
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'WinBoard Menu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(_screenConfigurations[0].title), // Use title from config
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.rss_feed),
              title: Text(_screenConfigurations[1].title), // Use title from config
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.radio),
              title: Text(_screenConfigurations[2].title), // Use title from config
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(_screenConfigurations[3].title), // Use title from config
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}