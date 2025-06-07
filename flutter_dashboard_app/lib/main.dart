import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:flutter_dashboard_app/src/models/user_preferences.dart'; // Import UserPreferences
import 'package:flutter_dashboard_app/src/features/dashboard_screen.dart';
import 'package:flutter_dashboard_app/src/features/rss_feed_screen.dart';
import 'package:flutter_dashboard_app/src/features/web_radio_screen.dart';
import 'package:flutter_dashboard_app/src/features/settings_screen.dart';
import 'package:flutter_dashboard_app/src/services/preferences_service.dart'; // Import PreferencesService

// Import generated adapters
import 'package:flutter_dashboard_app/src/models/user_preferences.g.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.g.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.g.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.g.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_item.g.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.g.dart'; // Will be generated
import 'package:flutter_dashboard_app/src/models/notepad_data.dart'; // Needed for adapter registration
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart'; // Needed for adapter registration
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart'; // Needed for adapter registration
import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart'; // Needed for adapter registration
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart'; // Needed for adapter registration
import 'package:workmanager/workmanager.dart'; // Import workmanager
import 'package:flutter_dashboard_app/src/background_tasks.dart'; // Import background tasks


void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(UserPreferencesAdapter());
  Hive.registerAdapter(NotepadDataAdapter());
  Hive.registerAdapter(DashboardItemAdapter());
  Hive.registerAdapter(RssFeedSourceAdapter());
  Hive.registerAdapter(RssFeedItemAdapter());
  Hive.registerAdapter(RssWidgetConfigAdapter());

  // Open Boxes
  await Hive.openBox<UserPreferences>('userPreferencesBox');
  await Hive.openBox<DashboardItem>('dashboardItemsBox');
  await Hive.openBox<RssFeedSource>('rssFeedSourcesBox');
  await Hive.openBox<RssFeedItem>('rssFeedItemsBox');
  // No separate box for NotepadData as it's embedded in DashboardItem

  // Initialize Notifications
  await initializeNotifications();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher, // The top-level callback function
    isInDebugMode: true, // Set to false for production
  );

  // Register periodic task
  Workmanager().registerPeriodicTask(
    "1", // Unique name for the task
    rssRefreshTask, // Task name defined in background_tasks.dart
    frequency: const Duration(hours: 6), // Adjust frequency as needed
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run when connected to a network
    ),
  );

  // Load preferences
  final preferencesService = PreferencesService();
  final userPreferences = preferencesService.getUserPreferences();

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
    switch (themeString) {
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
        colorSchemeSeed: Colors.blue, // Using colorSchemeSeed for M3
        brightness: Brightness.light,
        // fontFamily: 'YourCustomFont',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue, // Using colorSchemeSeed for M3
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode, // Use state variable
      home: MainNavigationScreen(onThemeChanged: _updateThemeMode), // Pass callback
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
  int _selectedIndex = 0; // Default to Dashboard screen

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    RssFeedScreen(),
    WebRadioScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            label: 'RSS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio),
            label: 'Web Radio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Example color
        unselectedItemColor: Colors.grey, // Example color
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To ensure all labels are visible
      ),
    );
  }
}
