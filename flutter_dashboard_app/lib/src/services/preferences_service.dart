import 'package:hive/hive.dart';
import 'package:flutter_dashboard_app/src/models/user_preferences.dart';

class PreferencesService {
  static const String _boxName = 'userPreferencesBox';
  static const String _prefsKey = 'currentUserPrefs';

  // FOR TEST PURPOSES ONLY
  static String getBoxNameTestOnly() => _boxName;

  Future<void> saveUserPreferences(UserPreferences preferences) async {
    final box = Hive.box<UserPreferences>(_boxName);
    await box.put(_prefsKey, preferences);
  }

  UserPreferences getUserPreferences() {
    final box = Hive.box<UserPreferences>(_boxName);
    final prefs = box.get(_prefsKey);
    if (prefs is UserPreferences) {
      // Ensure all fields have a value, even if loading older saved prefs
      return UserPreferences(
        themeModeName: prefs.themeModeName,
        rssNotificationsEnabled: prefs.rssNotificationsEnabled,
        rssRefreshFrequencyHours: prefs.rssRefreshFrequencyHours,
        colorSeedValue: prefs.colorSeedValue, // Add this line
      );
    }
    return UserPreferences.defaults();
  }

  Future<void> setThemeModeName(String themeModeName) async {
    final prefs = getUserPreferences();
    prefs.themeModeName = themeModeName;
    await saveUserPreferences(prefs);
  }

  Future<void> setRssNotificationsEnabled(bool enabled) async {
    final prefs = getUserPreferences();
    prefs.rssNotificationsEnabled = enabled;
    await saveUserPreferences(prefs);
  }

  Future<void> setRssRefreshFrequency(int hours) async {
    final prefs = getUserPreferences();
    prefs.rssRefreshFrequencyHours = hours;
    await saveUserPreferences(prefs);
    // Note: Re-registering workmanager task should happen elsewhere,
    // typically where workmanager is initially configured or from UI.
  }

  Future<void> setColorSeedValue(int? colorSeedValue) async {
    final prefs = getUserPreferences();
    prefs.colorSeedValue = colorSeedValue;
    await saveUserPreferences(prefs);
  }

  // Optional: A method to get the box if direct access is needed elsewhere
  Box<UserPreferences> getPreferencesBox() {
    return Hive.box<UserPreferences>(_boxName);
  }
}
