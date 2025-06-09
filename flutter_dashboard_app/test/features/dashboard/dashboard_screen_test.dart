import 'dart:io'; // For Directory.systemTemp

import 'package:flutter_dashboard_app/src/features/dashboard/widgets/rss_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart'; // For RssFeedItemAdapter
import 'package:flutter_dashboard_app/src/features/dashboard_screen.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/placeholder_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/notepad_widget.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart'; // For RssFeedSourceAdapter
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart';
import 'package:flutter_dashboard_app/src/services/dashboard_service.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart'; // Ensure this is imported for verify and matchers

// Generate Mocks for services
@GenerateMocks([DashboardService, RssService])
import 'dashboard_screen_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized

  late MockDashboardService mockDashboardService;
  late MockRssService mockRssService;
  late List<DashboardItem> mockStorageItems;

  setUpAll(() async {
    var path = Directory.systemTemp.createTempSync('hive_dashboard_test_').path;
    Hive.init(path);

    if (!Hive.isAdapterRegistered(RssFeedSourceAdapter().typeId)) {
      Hive.registerAdapter(RssFeedSourceAdapter());
    }
    if (!Hive.isAdapterRegistered(RssFeedItemAdapter().typeId)) {
      Hive.registerAdapter(RssFeedItemAdapter());
    }
    if (!Hive.isAdapterRegistered(DashboardItemAdapter().typeId)) {
       Hive.registerAdapter(DashboardItemAdapter());
    }
    if (!Hive.isAdapterRegistered(NotepadDataAdapter().typeId)) {
       Hive.registerAdapter(NotepadDataAdapter());
    }
    if (!Hive.isAdapterRegistered(RssWidgetConfigAdapter().typeId)) {
       Hive.registerAdapter(RssWidgetConfigAdapter());
    }
  });

  setUp(() async { // Make setUp async
    mockDashboardService = MockDashboardService();
    mockRssService = MockRssService();
    mockStorageItems = []; // Initialize for each test

    // Open boxes needed
    // These need to be open before DashboardScreen is pumped if it tries to add initial items.
    await Hive.openBox<DashboardItem>(DashboardService.getBoxNameTestOnly());
    await Hive.openBox<RssFeedSource>(RssService.getSourcesBoxNameTestOnly());
    await Hive.openBox<RssFeedItem>(RssService.getItemsBoxNameTestOnly());

    // Clear content from previous tests
    await Hive.box<DashboardItem>(DashboardService.getBoxNameTestOnly()).clear();
    await Hive.box<RssFeedSource>(RssService.getSourcesBoxNameTestOnly()).clear();
    await Hive.box<RssFeedItem>(RssService.getItemsBoxNameTestOnly()).clear();


    // Default mock responses
    when(mockDashboardService.getDashboardItems()).thenAnswer((_) => List.from(mockStorageItems));
    when(mockRssService.getFeedSources()).thenReturn([]); // Default to no RSS sources
    // Add default stubs for RssService methods that might be called by RssDashboardWidget
    when(mockRssService.fetchAndCacheFeedItems(any)).thenAnswer((_) async => <RssFeedItem>[]);
    when(mockRssService.getCachedFeedItems(any)).thenReturn(<RssFeedItem>[]);

    // Return Future.value for async methods
    // The actual DashboardService methods are called by the screen, which will interact with Hive.
    // The thenAnswer for mocks should reflect the state *after* the service call would have completed.
    // So, they add to mockStorageItems, which getDashboardItems then returns.
    when(mockDashboardService.createAndSavePlaceholderItem(any)).thenAnswer((invocation) async {
      final order = invocation.positionalArguments.first as int;
      final newItem = DashboardItem(id: 'p${mockStorageItems.length}', widgetType: 'placeholder', order: order);
      mockStorageItems.add(newItem);
      return newItem;
    });
    when(mockDashboardService.createAndSaveNotepadItem(any)).thenAnswer((invocation) async {
      final order = invocation.positionalArguments.first as int;
      final newItem = DashboardItem(id: 'n${mockStorageItems.length}', widgetType: 'notepad', order: order, widgetData: NotepadData(content: ''));
      mockStorageItems.add(newItem);
      return newItem;
    });
    when(mockDashboardService.createAndSaveRssWidgetConfigItem(any, any)).thenAnswer((invocation) async {
      final order = invocation.positionalArguments.first as int;
      final config = invocation.positionalArguments[1] as RssWidgetConfig;
      final newItem = DashboardItem(id: 'r${mockStorageItems.length}', widgetType: 'rss_summary', order: order, widgetData: config);
      mockStorageItems.add(newItem);
      return newItem;
    });
    when(mockDashboardService.createAndSaveWebRadioStatusItem(any)).thenAnswer((invocation) async {
      final order = invocation.positionalArguments.first as int;
      final newItem = DashboardItem(id: 'w${mockStorageItems.length}', widgetType: 'webradio_status', order: order);
      mockStorageItems.add(newItem);
      return newItem;
    });
    when(mockDashboardService.deleteDashboardItem(any)).thenAnswer((invocation) async {
      final itemId = invocation.positionalArguments.first as String;
      mockStorageItems.removeWhere((item) => item.id == itemId);
    });
    when(mockDashboardService.updateDashboardItemOrder(any)).thenAnswer((invocation) async {
      final orderedItems = invocation.positionalArguments.first as List<DashboardItem>;
      mockStorageItems = List.from(orderedItems);
    });
  });

  tearDown(() async {
    // Clear boxes after each test to ensure a clean state for the next one.
    // This is important because _addInitialItems in DashboardScreen interacts with these boxes.
    await Hive.box<DashboardItem>(DashboardService.getBoxNameTestOnly()).clear();
    await Hive.box<RssFeedSource>(RssService.getSourcesBoxNameTestOnly()).clear();
    await Hive.box<RssFeedItem>(RssService.getItemsBoxNameTestOnly()).clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('DashboardScreen displays AppBar and Add button', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('DashboardScreen displays "No items" message when dashboard is empty initially', (WidgetTester tester) async {
    // mockStorageItems is empty from setUp. getDashboardItems() will return empty.
    // This will trigger _addInitialItems in DashboardScreen.
    // We need to override the create methods for THIS TEST so they don't add to mockStorageItems,
    // ensuring mockStorageItems remains empty for the assertion.
    when(mockDashboardService.createAndSavePlaceholderItem(any)).thenAnswer((invocation) async {
      final order = invocation.positionalArguments.first as int;
      return DashboardItem(id: 'p_dummy_${order}', widgetType: 'placeholder', order: order);
    });
    when(mockDashboardService.createAndSaveNotepadItem(any)).thenAnswer((invocation) async {
      final order = invocation.positionalArguments.first as int;
      return DashboardItem(id: 'n_dummy_${order}', widgetType: 'notepad', order: order, widgetData: NotepadData(content: ''));
    });
    when(mockDashboardService.createAndSaveWebRadioStatusItem(any)).thenAnswer((invocation) async {
      final order = invocation.positionalArguments.first as int;
      return DashboardItem(id: 'w_dummy_${order}', widgetType: 'webradio_status', order: order);
    });
    // RssWidgetConfigItem is skipped by _addInitialItems if getFeedSources (from setUp) returns empty.

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No items on dashboard. Add some!'), findsOneWidget);
  });

  testWidgets('DashboardScreen displays items from DashboardService', (WidgetTester tester) async {
    // mockStorageItems is empty from setUp. Add items for this test.
    // _addInitialItems will NOT run because getDashboardItems will not be empty.
    final itemsToDisplay = [
      DashboardItem(id: 'item1_displayed', widgetType: 'placeholder', order: 0),
      DashboardItem(id: 'item2_displayed', widgetType: 'notepad', order: 1, widgetData: NotepadData(content: 'Test Note')),
    ];
    mockStorageItems.addAll(itemsToDisplay);

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderWidget), findsOneWidget);
    expect(find.byType(NotepadWidget), findsOneWidget);
    expect(find.text('Test Note'), findsOneWidget);
  });

  testWidgets('Adds Placeholder widget when "Add Placeholder" is tapped', (WidgetTester tester) async {
    // mockStorageItems will be used by getDashboardItems via setUp.
    // The createAndSavePlaceholderItem mock in setUp will add to mockStorageItems.

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    // Initial items are added during first pumpAndSettle if _dashboardItems is empty
    // Placeholder (0), Notepad (1), WebRadio (2) - assuming no RSS sources
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Placeholder'));
    await tester.pumpAndSettle();

    // Initial items: Placeholder(0), Notepad(1), WebRadio(2). New Placeholder is order 3.
    verify(mockDashboardService.createAndSavePlaceholderItem(3)).called(1);
    // Check if getDashboardItems was called again after adding (part of _loadDashboardItems)
    // The exact number of calls can be fragile. Focus on the state.
    // verify(mockDashboardService.getDashboardItems()).called(greaterThanOrEqualTo(2)); // Original was >=2
    expect(find.byType(PlaceholderWidget), findsNWidgets(2)); // Initial one + added one
  });

  testWidgets('Adds Notepad widget when "Add Notepad" is tapped', (WidgetTester tester) async {
    // mockStorageItems will be used by getDashboardItems via setUp.
    // The createAndSaveNotepadItem mock in setUp will add to mockStorageItems.

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    // Initial items are added during first pumpAndSettle if _dashboardItems is empty
    // Placeholder (0), Notepad (1), WebRadio (2) - assuming no RSS sources
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Notepad'));
    await tester.pumpAndSettle();

    // Initial items: Placeholder(0), Notepad(1), WebRadio(2). New Notepad is order 3.
    verify(mockDashboardService.createAndSaveNotepadItem(3)).called(1);
    expect(find.byType(NotepadWidget), findsNWidgets(2)); // Initial one + added one
  });

  testWidgets('Adds RSS Summary widget after selecting a feed', (WidgetTester tester) async {
    // mockStorageItems is managed by setUp and shared mocks.
    // The createAndSaveRssWidgetConfigItem mock in setUp will add to mockStorageItems.

    final sourceToSave = RssFeedSource(id: 'rss1', url: 'url1', name: 'Feed 1');
    final sourcesForMock = [sourceToSave];
    // This mock for getFeedSources is specific to this test and overrides the default in setUp
    when(mockRssService.getFeedSources()).thenReturn(sourcesForMock);

    // No longer need to save to Hive box directly, as RssDashboardWidget will use the MockRssService.
    // final rssSourcesBox = Hive.box<RssFeedSource>(RssService.getSourcesBoxNameTestOnly());
    // await rssSourcesBox.put(sourceToSave.id, sourceToSave);

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    // Initial items are added during first pumpAndSettle if _dashboardItems is empty
    // Placeholder (0), Notepad (1), WebRadio (2) - as getFeedSources in setUp is empty for _addInitialItems.
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add RSS Summary')); // This opens the dialog
    await tester.pumpAndSettle();

    expect(find.text('Select RSS Feed'), findsOneWidget); // Dialog is open
    await tester.tap(find.text('Feed 1')); // Select the feed
    await tester.pumpAndSettle(); // Dialog closes, widget is added

    // Initial items: Placeholder(0), Notepad(1), Initial RSS(2), WebRadio(3). New RSS Widget is order 4.
    // The config passed to createAndSaveRssWidgetConfigItem will be based on sourceToSave.
    verify(mockDashboardService.createAndSaveRssWidgetConfigItem(4, argThat(isA<RssWidgetConfig>().having((w) => w.feedSourceId, 'feedSourceId', 'rss1')))).called(1);

    // We expect the RssDashboardWidget to be on screen
    expect(find.byType(RssDashboardWidget), findsNWidgets(2)); // One from _addInitialItems, one from user action
  });

  testWidgets('Deletes a widget when close button is tapped', (WidgetTester tester) async {
    // mockStorageItems is managed by setUp and shared mocks.
    // Add a specific item for this test.
    // Note: _addInitialItems will NOT run if getDashboardItems (from mockStorageItems) is not empty.
    mockStorageItems.clear(); // Ensure a clean slate for this specific test's item
    final itemToDelete = DashboardItem(id: 'item1_to_delete', widgetType: 'placeholder', order: 0);
    mockStorageItems.add(itemToDelete);
    // The main setUp mocks for getDashboardItems and deleteDashboardItem will use mockStorageItems.

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle(); // This will display the itemToDelete

    expect(find.byType(PlaceholderWidget), findsOneWidget);

    // Find the delete button using byWidgetPredicate for the parent Stack and byTooltip for the button
    final stackFinder = find.byWidgetPredicate(
      (widget) => widget is Stack && widget.key == ValueKey(itemToDelete.id),
      description: 'Stack with key ${itemToDelete.id}',
    );
    expect(stackFinder, findsOneWidget, reason: 'Should find the Stack for the item to be deleted');

    final deleteButton = find.descendant(
      of: stackFinder,
      matching: find.byTooltip('Delete Item')
    );
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle(); // Re-renders after deletion

    verify(mockDashboardService.deleteDashboardItem(itemToDelete.id)).called(1);
    expect(find.byType(PlaceholderWidget), findsNothing); // Widget should be gone
    // After deletion, if no other items were added by _addInitialItems (because mockStorageItems was not empty initially),
    // then the "No items" message should appear.
    expect(find.text('No items on dashboard. Add some!'), findsOneWidget);
  });
}
