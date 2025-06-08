import 'package:flutter/material.dart'; // Added for Icon/Text etc.
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dashboard_app/main.dart' as app;
// Import specific widgets to find them by type if needed
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/rss_dashboard_widget.dart';
import 'package:flutter_dashboard_app/src/features/webradio/webradio_screen.dart'; // For ValueKey reference if needed

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App End-to-End Flows', () {
    // Using a real feed that's likely to be stable.
    final String testFeedUrl = 'https://www.nasa.gov/news/releases/feed/'; // NASA Releases RSS

    testWidgets('Add RSS feed and display its summary on dashboard', (WidgetTester tester) async {
      // 1. Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // --- Part 1: Add RSS Feed ---
      final rssTabIcon = find.byIcon(Icons.rss_feed);
      expect(rssTabIcon, findsOneWidget, reason: "RSS tab icon should be present");
      await tester.tap(rssTabIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final addFeedButton = find.byIcon(Icons.add);
      expect(addFeedButton, findsOneWidget, reason: "Add RSS Feed button should be present");
      await tester.tap(addFeedButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget, reason: "Add RSS Feed dialog should appear");
      expect(find.byType(TextField), findsOneWidget, reason: "TextField for URL should be in dialog");
      await tester.enterText(find.byType(TextField), testFeedUrl);

      final addButtonInDialog = find.widgetWithText(TextButton, 'Add');
      expect(addButtonInDialog, findsOneWidget, reason: "'Add' button in dialog should be present");
      await tester.tap(addButtonInDialog);
      await tester.pumpAndSettle(const Duration(seconds: 7));

      expect(find.textContaining('NASA Releases', findRichText: true), findsOneWidget, reason: "Feed title should be in the list");

      // --- Part 2: Add RSS Widget to Dashboard ---
      final dashboardTabIcon = find.byIcon(Icons.dashboard);
      expect(dashboardTabIcon, findsOneWidget, reason: "Dashboard tab icon should be present");
      await tester.tap(dashboardTabIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final addWidgetButton = find.byIcon(Icons.add);
      expect(addWidgetButton, findsOneWidget, reason: "Add widget button on Dashboard should be present");
      await tester.tap(addWidgetButton);
      await tester.pumpAndSettle();

      final addRssSummaryMenuItem = find.text('Add RSS Summary');
      expect(addRssSummaryMenuItem, findsOneWidget, reason: "'Add RSS Summary' menu item should be present");
      await tester.tap(addRssSummaryMenuItem);
      await tester.pumpAndSettle();

      expect(find.text('Select RSS Feed'), findsOneWidget, reason: "Select RSS Feed dialog should appear");
      final feedInDialog = find.textContaining('NASA Releases', findRichText: true);
      expect(feedInDialog, findsOneWidget, reason: "Previously added feed should be listed in dialog");
      await tester.tap(feedInDialog);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(RssDashboardWidget), findsOneWidget, reason: "RssDashboardWidget should be on the dashboard");
      await tester.pumpAndSettle(const Duration(seconds: 7));

      final rssWidgetFinder = find.byType(RssDashboardWidget);
      final textInRssWidget = find.descendant(
        of: rssWidgetFinder,
        matching: find.textContaining('NASA', findRichText: true)
      );
      expect(textInRssWidget, findsWidgets, reason: "Text from the RSS feed should be displayed within the RssDashboardWidget");
    });

    testWidgets('Search for and play a radio station', (WidgetTester tester) async {
      // 1. Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Navigate to WebRadio Screen
      final webRadioTabIcon = find.byIcon(Icons.radio);
      expect(webRadioTabIcon, findsOneWidget, reason: "WebRadio tab icon should be present");
      await tester.tap(webRadioTabIcon);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 3. Find the search input field and enter a search term
      final String searchTerm = "classical";
      final searchField = find.byType(TextField); // Assuming it's the only prominent TextField
      expect(searchField, findsOneWidget, reason: "Search field should be present on WebRadio screen");
      await tester.enterText(searchField, searchTerm);

      final searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget, reason: "Search button should be present");
      await tester.tap(searchButton);
      await tester.pumpAndSettle(const Duration(seconds: 10)); // Allow ample time for API search

      // 4. Find a station in the results and tap it
      final Finder stationListTileFinder = find.byType(ListTile).first;
      // Ensure at least one station is found from the search
      expect(stationListTileFinder, findsOneWidget,
          reason: "No station found in the list for search term: '$searchTerm'. API might be slow or no results.");

      // Get the name of the station to verify later in the player
      final stationNameFinder = find.descendant(of: stationListTileFinder, matching: find.byType(Text)).first;
      final String stationName = (tester.widget(stationNameFinder) as Text).data!;

      await tester.tap(stationListTileFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Allow time for stream to start buffering/playing

      // 5. Verify playback state (UI changes)
      // Assumes player controls are wrapped in a widget with ValueKey('webradio_player_controls')
      final Finder playerControlArea = find.byKey(const ValueKey('webradio_player_controls'));
      expect(playerControlArea, findsOneWidget, reason: "Player control area not found. Add ValueKey('webradio_player_controls') to its container.");

      expect(find.descendant(of: playerControlArea, matching: find.text(stationName)), findsOneWidget,
          reason: "Playing station name '$stationName' not found in player controls.");

      // Assuming pause icon indicates playback
      // Note: Icons can vary (e.g. pause, pause_circle_filled, pause_circle_outline)
      // Making this check more flexible by looking for any common pause icon.
      final findPauseIcon = find.descendant(
          of: playerControlArea,
          matching: find.byWidgetPredicate((widget) => widget is Icon && (widget.icon == Icons.pause || widget.icon == Icons.pause_circle_filled || widget.icon == Icons.pause_circle_outline))
      );
      expect(findPauseIcon, findsOneWidget, reason: "Pause button not found in player controls after playing.");

      // 6. Tap Pause and verify UI changes back
      await tester.tap(findPauseIcon);
      await tester.pumpAndSettle();

      final findPlayIcon = find.descendant(
          of: playerControlArea,
          matching: find.byWidgetPredicate((widget) => widget is Icon && (widget.icon == Icons.play_arrow || widget.icon == Icons.play_circle_filled || widget.icon == Icons.play_circle_outline))
      );
      expect(findPlayIcon, findsOneWidget, reason: "Play button not found after tapping pause.");
    });
  });
}
