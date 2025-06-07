import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/models/user_preferences.dart';
import 'package:flutter_dashboard_app/src/services/preferences_service.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:flutter_dashboard_app/src/services/dashboard_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_dashboard_app/src/background_tasks.dart' show rssRefreshTask; // For task name

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged; // Callback to update theme in MyApp

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefsService = PreferencesService();
  final RssService _rssService = RssService();
  final DashboardService _dashboardService = DashboardService();
  final RadioService _radioService = RadioService(); // For favorites export/import

  late UserPreferences _currentPrefs;
  bool _isLoading = true;

  final List<int> _refreshFrequencies = [1, 3, 6, 12, 24]; // Hours

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() { _isLoading = true; });
    _currentPrefs = _prefsService.getUserPreferences();
    setState(() { _isLoading = false; });
  }

  Future<void> _updateThemeMode(ThemeMode? newMode) async {
    if (newMode == null) return;
    String themeModeName;
    switch (newMode) {
      case ThemeMode.light:
        themeModeName = 'light';
        break;
      case ThemeMode.dark:
        themeModeName = 'dark';
        break;
      default:
        themeModeName = 'system';
    }
    await _prefsService.setThemeModeName(themeModeName);
    widget.onThemeChanged(newMode); // Call callback to update theme in MaterialApp
    _loadPreferences();
  }

  Future<void> _updateRssNotificationsEnabled(bool enabled) async {
    await _prefsService.setRssNotificationsEnabled(enabled);
    _loadPreferences();
    // Note: This only updates the setting. Actual notification logic is in background_task.
  }

  Future<void> _updateRssRefreshFrequency(int? hours) async {
    if (hours == null) return;
    await _prefsService.setRssRefreshFrequency(hours);
    // Re-register WorkManager task with new frequency
    await Workmanager().cancelByUniqueName("1"); // Cancel existing task
    Workmanager().registerPeriodicTask(
      "1",
      rssRefreshTask,
      frequency: Duration(hours: hours),
      initialDelay: const Duration(minutes: 5), // Give some time before first run after change
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace, // Replace if already exists
    );
    _loadPreferences();
     if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSS refresh frequency updated to $hours hours. Change will apply from next cycle.'))
    );
  }

  Future<void> _exportData() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting data...')));

    try {
      final prefsData = _prefsService.getUserPreferences(); // Already a HiveObject, need to map to JSON
      final dashboardItems = _dashboardService.getDashboardItems(); // List of HiveObjects
      final rssSources = _rssService.getFeedSources(); // List of HiveObjects
      final rssItems = _rssService.getCachedFeedItems("*"); // Special case to get all items or per source

      Map<String, dynamic> exportJson = {
        "userPreferences": {
          "themeModeName": prefsData.themeModeName,
          "rssNotificationsEnabled": prefsData.rssNotificationsEnabled,
          "rssRefreshFrequencyHours": prefsData.rssRefreshFrequencyHours,
        },
        "dashboardItems": dashboardItems.map((item) {
          dynamic widgetDataJson;
          if (item.widgetData is NotepadData) {
            widgetDataJson = {"type": "NotepadData", "content": (item.widgetData as NotepadData).content};
          } else if (item.widgetData is RssWidgetConfig) {
            widgetDataJson = {
              "type": "RssWidgetConfig",
              "feedSourceId": (item.widgetData as RssWidgetConfig).feedSourceId,
              "feedSourceName": (item.widgetData as RssWidgetConfig).feedSourceName,
            };
          }
          return {
            "id": item.id,
            "widgetType": item.widgetType,
            "order": item.order,
            "widgetData": widgetDataJson,
          };
        }).toList(),
        "rssSources": rssSources.map((source) => {"id": source.id, "url": source.url, "name": source.name}).toList(),
        "rssItems": rssItems.map((item) => {
            "guid": item.guid, "title": item.title, "link": item.link, "description": item.description,
            "pubDate": item.pubDate, "feedSourceId": item.feedSourceId, "itemUniqueKey": item.itemUniqueKey
        }).toList(),
        "radioFavorites": _radioService.exportFavorites(), // Export radio favorites
      };

      String jsonString = jsonEncode(exportJson);

      // Use file_picker to save the file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'dashboard_backup_${DateTime.now().toIso8601String().split('T').first}.json',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data exported to $outputFile')));

        // Optional: Use share_plus to share the file
        // await Share.shareXFiles([XFile(outputFile)], text: 'Dashboard App Backup');

      } else {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export cancelled.')));
      }

    } catch (e) {
      print('Error exporting data: $e');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
    }
  }

  Future<void> _importData() async {
     FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      try {
        String jsonString = await file.readAsString();
        Map<String, dynamic> importJson = jsonDecode(jsonString);

        // Show confirmation dialog
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Confirm Import'),
            content: const Text('This will overwrite existing data. Are you sure you want to proceed?'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Import')),
            ],
          ),
        );

        if (confirmed != true) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import cancelled.')));
          return;
        }

        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Importing data... This may take a moment.')));


        // Clear existing data (carefully!)
        // This part needs to be implemented in each service
        await _dashboardService.clearAllDashboardItems();
        await _rssService.clearAllRssData();
        await _radioService.importFavorites([]); // Clear existing radio favorites by importing empty list first

        // Import UserPreferences
        if (importJson['userPreferences'] != null) {
          Map<String,dynamic> prefsJson = importJson['userPreferences'];
          UserPreferences importedPrefs = UserPreferences(
            themeModeName: prefsJson['themeModeName'] ?? 'system',
            rssNotificationsEnabled: prefsJson['rssNotificationsEnabled'] ?? true,
            rssRefreshFrequencyHours: prefsJson['rssRefreshFrequencyHours'] ?? 6,
          );
          await _prefsService.saveUserPreferences(importedPrefs);
           // Update theme immediately
          _updateThemeMode(ThemeMode.values.firstWhere((e) => e.toString().split('.').last == importedPrefs.themeModeName, orElse: () => ThemeMode.system));
          _updateRssRefreshFrequency(importedPrefs.rssRefreshFrequencyHours); // This will also re-register workmanager
        }

        // Import RSS Sources
        if (importJson['rssSources'] is List) {
          for (var sourceJson in importJson['rssSources']) {
            await _rssService.addFeedSourceWithDetails( // You'll need to create this method in RssService
              id: sourceJson['id'],
              url: sourceJson['url'],
              name: sourceJson['name']
            );
          }
        }

        // Import RSS Items
        if (importJson['rssItems'] is List) {
            await _rssService.importFeedItems(importJson['rssItems']); // You'll need to create this
        }

        // Import Dashboard Items
        if (importJson['dashboardItems'] is List) {
           await _dashboardService.importDashboardItems(importJson['dashboardItems']); // You'll need to create this
        }

        _loadPreferences(); // Reload settings screen state
        // Import Radio Favorites
        if (importJson['radioFavorites'] is List) {
          await _radioService.importFavorites(importJson['radioFavorites']);
        }

        _loadPreferences(); // Reload settings screen state
        // Potentially trigger a reload of other screens or notify user to restart for all changes to take effect.
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data imported successfully! Restart app if necessary.')));

      } catch (e) {
        print('Error importing data: $e');
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing data: $e')));
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file selected.')));
    }
  }

  Future<void> _clearRssCache() async {
     bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear RSS Cache'),
        content: const Text('Are you sure you want to delete all cached RSS articles? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear Cache')),
        ],
      ),
    );
    if (confirmed == true) {
      await _rssService.clearAllCachedItems(); // You'll need to implement this in RssService
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RSS article cache cleared.')));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildSectionTitle('Appearance'),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: ThemeMode.values.firstWhere(
                (e) => e.toString().split('.').last == _currentPrefs.themeModeName,
                orElse: () => ThemeMode.system,
              ),
              items: ThemeMode.values.map((ThemeMode mode) {
                return DropdownMenuItem<ThemeMode>(
                  value: mode,
                  child: Text(mode.toString().split('.').last.capitalize(), style: Theme.of(context).textTheme.bodyMedium),
                );
              }).toList(),
              onChanged: _updateThemeMode,
            ),
          ),
          const Divider(),
          _buildSectionTitle('RSS Feed'),
          SwitchListTile(
            title: const Text('Enable RSS Notifications'),
            value: _currentPrefs.rssNotificationsEnabled,
            onChanged: _updateRssNotificationsEnabled,
          ),
          ListTile(
            title: const Text('Refresh Frequency'),
            trailing: DropdownButton<int>(
              value: _refreshFrequencies.contains(_currentPrefs.rssRefreshFrequencyHours)
                     ? _currentPrefs.rssRefreshFrequencyHours
                     : _refreshFrequencies.first,
              items: _refreshFrequencies.map((int hours) {
                return DropdownMenuItem<int>(
                  value: hours,
                  child: Text('$hours hours', style: Theme.of(context).textTheme.bodyMedium),
                );
              }).toList(),
              onChanged: _updateRssRefreshFrequency,
            ),
          ),
          const Divider(),
          _buildSectionTitle('Data Management'),
          ListTile(
            title: const Text('Export Data'),
            trailing: const Icon(Icons.file_upload),
            onTap: _exportData,
          ),
          ListTile(
            title: const Text('Import Data'),
            trailing: const Icon(Icons.file_download),
            onTap: _importData,
          ),
           ListTile(
            title: const Text('Clear RSS Article Cache'),
            trailing: const Icon(Icons.delete_sweep),
            onTap: _clearRssCache,
          ),
          // ... other settings ...
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
