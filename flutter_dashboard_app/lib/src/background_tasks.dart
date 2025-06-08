import 'package:workmanager/workmanager.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:flutter_dashboard_app/src/services/preferences_service.dart'; // If needed for any prefs
import 'package:hive_flutter/hive_flutter.dart'; // Direct import for background isolate
import 'package:flutter_dashboard_app/src/models/user_preferences.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String rssRefreshTask = "rssRefreshBackgroundTask";
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Top-level function
@pragma('vm:entry-point') // Mandatory if using FlutterBackgroundService, good practice for workmanager too
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native Dart task: $task"); //simpleTask will be emitted here.
    if (task == rssRefreshTask) {
      try {
        // Initialize Hive for background isolate
        // Note: PathProvider might not work reliably in background isolates on all platforms.
        // Consider passing path from main isolate via inputData if issues arise,
        // or ensure Hive.initFlutter() without subDirectory works as expected.
        await Hive.initFlutter(); // Use default path

        // Register all adapters - must be done in each isolate
        if (!Hive.isAdapterRegistered(UserPreferencesAdapter().typeId)) {
          Hive.registerAdapter(UserPreferencesAdapter());
        }
        if (!Hive.isAdapterRegistered(NotepadDataAdapter().typeId)) {
          Hive.registerAdapter(NotepadDataAdapter());
        }
        if (!Hive.isAdapterRegistered(DashboardItemAdapter().typeId)) {
          Hive.registerAdapter(DashboardItemAdapter());
        }
        if (!Hive.isAdapterRegistered(RssFeedSourceAdapter().typeId)) {
          Hive.registerAdapter(RssFeedSourceAdapter());
        }
        if (!Hive.isAdapterRegistered(RssFeedItemAdapter().typeId)) {
          Hive.registerAdapter(RssFeedItemAdapter());
        }
        if (!Hive.isAdapterRegistered(RssWidgetConfigAdapter().typeId)) {
          Hive.registerAdapter(RssWidgetConfigAdapter());
        }

        // Open necessary boxes
        // Check if boxes are already open before trying to open them.
        if (!Hive.isBoxOpen('rssFeedSourcesBox')) {
          await Hive.openBox<RssFeedSource>('rssFeedSourcesBox');
        }
        if (!Hive.isBoxOpen('rssFeedItemsBox')) {
          await Hive.openBox<RssFeedItem>('rssFeedItemsBox');
        }
        // Add other boxes if RssService dependencies need them.

        final RssService rssService = RssService();
        print("Background task: Refreshing all RSS feeds...");
        await rssService.refreshAllFeeds();
        print("Background task: RSS feeds refreshed.");

        // Basic notification
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'rssChannelId', 'RSS Feed Updates',
            channelDescription: 'Notifications for updated RSS feeds',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
        );
        const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
        await flutterLocalNotificationsPlugin.show(
            0, 'RSS Feeds Updated', 'New articles may be available.', platformDetails);

        return Future.value(true);
      } catch (e,s) {
        print('Error in background RSS refresh: $e');
        print(s);
        return Future.value(false);
      } finally {
        // Close boxes if they were opened by this isolate,
        // though this might not be strictly necessary if app is also running.
        // await Hive.close(); // Be cautious with this, might affect main isolate
      }
    }
    return Future.value(false);
  });
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('mipmap/ic_launcher'); // Use default app icon
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
