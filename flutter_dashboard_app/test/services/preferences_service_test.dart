import 'package:flutter_dashboard_app/src/models/user_preferences.dart';
import 'package:flutter_dashboard_app/src/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io'; // Added for Directory

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService preferencesService;
  late Box<UserPreferences> userPreferencesBox;
  // Use a unique name for the box for each test suite run to avoid conflicts
  final String baseBoxName = PreferencesService.getBoxNameTestOnly();

  setUpAll(() async {
    var path = Directory.systemTemp.createTempSync('hive_prefs_test_').path;
    Hive.init(path);

    if (!Hive.isAdapterRegistered(UserPreferencesAdapter().typeId)) {
      Hive.registerAdapter(UserPreferencesAdapter());
    }
  });

  setUp(() async {
    preferencesService = PreferencesService();
    // Use a unique box name for each test by appending a timestamp, or ensure full deletion.
    // For simplicity, we'll ensure the actual box the service uses is clean.
    if(Hive.isBoxOpen(baseBoxName)) {
        await Hive.box(baseBoxName).deleteFromDisk();
    }
    userPreferencesBox = await Hive.openBox<UserPreferences>(baseBoxName);
    // No need to clear after deleteFromDisk, openBox will create a new one.
  });

  tearDown(() async {
    // Closing the box is good practice after each test if opened in setUp.
    if (userPreferencesBox.isOpen) {
      await userPreferencesBox.deleteFromDisk(); // Or just .close() if deleteFromDisk is too slow/problematic
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('getUserPreferences returns default preferences when box is empty', () {
    final prefs = preferencesService.getUserPreferences();
    expect(prefs.themeModeName, 'system');
    expect(prefs.rssNotificationsEnabled, true);
    expect(prefs.rssRefreshFrequencyHours, 6);
  });

  test('saveUserPreferences and getUserPreferences work correctly', () async {
    final newPrefs = UserPreferences(
      themeModeName: 'dark',
      rssNotificationsEnabled: false,
      rssRefreshFrequencyHours: 12,
    );
    await preferencesService.saveUserPreferences(newPrefs);

    final retrievedPrefs = preferencesService.getUserPreferences();
    expect(retrievedPrefs.themeModeName, 'dark');
    expect(retrievedPrefs.rssNotificationsEnabled, false);
    expect(retrievedPrefs.rssRefreshFrequencyHours, 12);
  });

  test('setThemeModeName updates theme mode name', () async {
    await preferencesService.setThemeModeName('light');
    final prefs = preferencesService.getUserPreferences();
    expect(prefs.themeModeName, 'light');
  });

  test('setRssNotificationsEnabled updates RSS notification preference', () async {
    await preferencesService.setRssNotificationsEnabled(false);
    final prefs = preferencesService.getUserPreferences();
    expect(prefs.rssNotificationsEnabled, false);

    await preferencesService.setRssNotificationsEnabled(true);
    final prefs2 = preferencesService.getUserPreferences();
    expect(prefs2.rssNotificationsEnabled, true);
  });

  test('setRssRefreshFrequency updates RSS refresh frequency', () async {
    await preferencesService.setRssRefreshFrequency(3);
    final prefs = preferencesService.getUserPreferences();
    expect(prefs.rssRefreshFrequencyHours, 3);
  });

  test('getUserPreferences reconstruction logic provides defaults for new fields', () async {
    await userPreferencesBox.clear(); // Start fresh for this specific case

    var prefs = preferencesService.getUserPreferences(); // Should be defaults
    expect(prefs.themeModeName, 'system');
    expect(prefs.rssNotificationsEnabled, true);
    expect(prefs.rssRefreshFrequencyHours, 6);

    await preferencesService.setThemeModeName('dark');
    prefs = preferencesService.getUserPreferences();
    expect(prefs.themeModeName, 'dark');
    expect(prefs.rssNotificationsEnabled, true);
    expect(prefs.rssRefreshFrequencyHours, 6);

    await preferencesService.setRssNotificationsEnabled(false);
    prefs = preferencesService.getUserPreferences();
    expect(prefs.themeModeName, 'dark');
    expect(prefs.rssNotificationsEnabled, false);
    expect(prefs.rssRefreshFrequencyHours, 6);
  });
}
