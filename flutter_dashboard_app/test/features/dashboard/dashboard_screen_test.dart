import 'package:flutter_dashboard_app/src/features/dashboard/widgets/rss_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/features/dashboard_screen.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/placeholder_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/notepad_widget.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart';
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
  late MockDashboardService mockDashboardService;
  late MockRssService mockRssService;

  setUp(() {
    mockDashboardService = MockDashboardService();
    mockRssService = MockRssService();

    // Default mock responses
    when(mockDashboardService.getDashboardItems()).thenReturn([]);
    when(mockRssService.getFeedSources()).thenReturn([]);
    // Return Future.value for async methods
    // when(mockDashboardService.createAndSavePlaceholderItem(any)).thenAnswer((_) async => DashboardItem(id: 'p${DateTime.now().millisecondsSinceEpoch}', widgetType: 'placeholder', order: 0));
    // when(mockDashboardService.createAndSaveNotepadItem(any)).thenAnswer((_) async => DashboardItem(id: 'n${DateTime.now().millisecondsSinceEpoch}', widgetType: 'notepad', order: 0, widgetData: NotepadData(content: '')));
    // when(mockDashboardService.createAndSaveRssWidgetConfigItem(any, any)).thenAnswer((_) async => DashboardItem(id: 'r${DateTime.now().millisecondsSinceEpoch}', widgetType: 'rss_summary', order: 0, widgetData: RssWidgetConfig(feedSourceId: 'id', feedSourceName: 'name')));
    // when(mockDashboardService.createAndSaveWebRadioStatusItem(any)).thenAnswer((_) async => DashboardItem(id: 'w${DateTime.now().millisecondsSinceEpoch}', widgetType: 'webradio_status', order: 0));
    // when(mockDashboardService.deleteDashboardItem(any)).thenAnswer((_) async {});
    // when(mockDashboardService.updateDashboardItemOrder(any)).thenAnswer((_) async {});
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
    // Specific setup for this test: getDashboardItems returns empty,
    // and ensure _addInitialItems doesn't effectively change this for the test's verification period.
    when(mockDashboardService.getDashboardItems()).thenReturn([]);
    // If create methods are called by _addInitialItems, they will use the default thenAnswer from setUp.
    // The important part is that the *next* call to getDashboardItems (after _addInitialItems) still returns empty for this test.
    // This can be tricky. A robust way is to ensure _addInitialItems itself doesn't run or its effects are controlled.
    // For this test, we'll assume that if getDashboardItems *consistently* returns [], that's what UI will see.

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
    final items = [
      DashboardItem(id: 'item1', widgetType: 'placeholder', order: 0),
      DashboardItem(id: 'item2', widgetType: 'notepad', order: 1, widgetData: NotepadData(content: 'Test Note')),
    ];
    when(mockDashboardService.getDashboardItems()).thenReturn(items);

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
    List<DashboardItem> currentItems = [];
    when(mockDashboardService.getDashboardItems()).thenAnswer((_) => currentItems);

    final placeholderItem = DashboardItem(id: 'p1', widgetType: 'placeholder', order: 0);
    when(mockDashboardService.createAndSavePlaceholderItem(any)).thenAnswer((invocation) async {
      currentItems = [placeholderItem]; // Update the list that getDashboardItems will return
      return placeholderItem;
    });

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle(); // Initial load (empty)

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Placeholder'));
    await tester.pumpAndSettle();

    verify(mockDashboardService.createAndSavePlaceholderItem(0)).called(1);
    // Check if getDashboardItems was called again after adding (part of _loadDashboardItems)
    // First call in initState, second in _loadDashboardItems after add.
    verify(mockDashboardService.getDashboardItems()).called(greaterThanOrEqualTo(2));
    expect(find.byType(PlaceholderWidget), findsOneWidget);
  });

  testWidgets('Adds Notepad widget when "Add Notepad" is tapped', (WidgetTester tester) async {
    List<DashboardItem> currentItems = [];
    when(mockDashboardService.getDashboardItems()).thenAnswer((_) => currentItems);
    final notepadItem = DashboardItem(id: 'n1', widgetType: 'notepad', order: 0, widgetData: NotepadData(content: ''));
     when(mockDashboardService.createAndSaveNotepadItem(any)).thenAnswer((_) async {
      currentItems = [notepadItem];
      return notepadItem;
    });

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Notepad'));
    await tester.pumpAndSettle();

    verify(mockDashboardService.createAndSaveNotepadItem(0)).called(1);
    expect(find.byType(NotepadWidget), findsOneWidget);
  });

  testWidgets('Adds RSS Summary widget after selecting a feed', (WidgetTester tester) async {
    List<DashboardItem> currentItems = [];
    when(mockDashboardService.getDashboardItems()).thenAnswer((_) => currentItems);

    final sources = [
      RssFeedSource(id: 'rss1', url: 'url1', name: 'Feed 1'),
    ];
    when(mockRssService.getFeedSources()).thenReturn(sources);

    final rssConfig = RssWidgetConfig(feedSourceId: 'rss1', feedSourceName: 'Feed 1');
    final rssWidgetItem = DashboardItem(id: 'rss_w1', widgetType: 'rss_summary', order: 0, widgetData: rssConfig);

    when(mockDashboardService.createAndSaveRssWidgetConfigItem(any, any)).thenAnswer((invocation) async {
        currentItems = [rssWidgetItem];
        return rssWidgetItem;
    });

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add RSS Summary'));
    await tester.pumpAndSettle();

    expect(find.text('Select RSS Feed'), findsOneWidget);
    await tester.tap(find.text('Feed 1'));
    await tester.pumpAndSettle();

    verify(mockDashboardService.createAndSaveRssWidgetConfigItem(0, any)).called(1);
    // We expect the RssDashboardWidget to be on screen
    // Further testing of its internal state (fetching items) is for RssDashboardWidget's own test.
    expect(find.byType(RssDashboardWidget), findsOneWidget);
  });

  testWidgets('Deletes a widget when close button is tapped', (WidgetTester tester) async {
    final itemToDelete = DashboardItem(id: 'item1', widgetType: 'placeholder', order: 0);
    List<DashboardItem> currentItems = [itemToDelete];

    // Initial state: one item
    when(mockDashboardService.getDashboardItems()).thenAnswer((_) => currentItems);

    when(mockDashboardService.deleteDashboardItem(itemToDelete.id)).thenAnswer((_) async {
      currentItems = []; // Simulate item removal
    });

    await tester.pumpWidget(createTestableWidget(
      DashboardScreen(
        dashboardServiceForTest: mockDashboardService,
        rssServiceForTest: mockRssService,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderWidget), findsOneWidget);

    final deleteButton = find.descendant(
      of: find.byType(PlaceholderWidget),
      matching: find.byIcon(Icons.close)
    );
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    verify(mockDashboardService.deleteDashboardItem(itemToDelete.id)).called(1);
    expect(find.byType(PlaceholderWidget), findsNothing);
    expect(find.text('No items on dashboard. Add some!'), findsOneWidget);
  });
}
