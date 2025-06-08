import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart';
import 'package:flutter_dashboard_app/src/services/dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io'; // For Directory for Hive path

// MockHiveBox is not used with this strategy

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DashboardService dashboardService;
  late Box<DashboardItem> dashboardBox;
  final String boxName = DashboardService.getBoxNameTestOnly();

  setUpAll(() async {
    var path = Directory.systemTemp.createTempSync('hive_dashboard_test_').path;
    Hive.init(path);
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

  setUp(() async {
    dashboardService = DashboardService();
    if(Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).deleteFromDisk();
    }
    dashboardBox = await Hive.openBox<DashboardItem>(boxName);
  });

  tearDown(() async {
    if (dashboardBox.isOpen) {
      await dashboardBox.deleteFromDisk();
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('DashboardService Tests', () {
    test('createAndSaveNotepadItem creates and saves a notepad item', () async {
      final item = await dashboardService.createAndSaveNotepadItem(0);

      expect(item.widgetType, 'notepad');
      expect(item.order, 0);
      expect(item.widgetData, isA<NotepadData>());
      expect((item.widgetData as NotepadData).content, '');
      expect(dashboardBox.containsKey(item.id), isTrue);
    });

    test('createAndSavePlaceholderItem creates and saves a placeholder item', () async {
      final item = await dashboardService.createAndSavePlaceholderItem(1);

      expect(item.widgetType, 'placeholder');
      expect(item.order, 1);
      expect(item.widgetData, isNull);
      expect(dashboardBox.containsKey(item.id), isTrue);
    });

    test('createAndSaveRssWidgetConfigItem creates and saves an RSS widget item', () async {
      final rssConfig = RssWidgetConfig(feedSourceId: 'rss-id-1', feedSourceName: 'Tech News');
      final item = await dashboardService.createAndSaveRssWidgetConfigItem(2, rssConfig);

      expect(item.widgetType, 'rss_summary');
      expect(item.order, 2);
      expect(item.widgetData, isA<RssWidgetConfig>());
      expect((item.widgetData as RssWidgetConfig).feedSourceId, 'rss-id-1');
      expect(dashboardBox.containsKey(item.id), isTrue);
    });

    test('getDashboardItems retrieves and orders items correctly', () async {
      final item1 = DashboardItem(id: 'id1', widgetType: 'notepad', order: 1, widgetData: NotepadData());
      final item0 = DashboardItem(id: 'id0', widgetType: 'placeholder', order: 0, widgetData: null);

      await dashboardBox.put(item1.id, item1);
      await dashboardBox.put(item0.id, item0);

      final items = dashboardService.getDashboardItems();
      expect(items.length, 2);
      expect(items[0].id, 'id0');
      expect(items[1].id, 'id1');
    });

    test('deleteDashboardItem removes an item', () async {
      final item = await dashboardService.createAndSaveNotepadItem(0);
      expect(dashboardBox.containsKey(item.id), isTrue);

      await dashboardService.deleteDashboardItem(item.id);
      expect(dashboardBox.containsKey(item.id), isFalse);
    });

    test('updateDashboardItemOrder updates order of items and saves them', () async {
      final itemA_initial = await dashboardService.createAndSaveNotepadItem(0);
      final itemB_initial = await dashboardService.createAndSavePlaceholderItem(1);
      final itemC_initial = await dashboardService.createAndSaveRssWidgetConfigItem(2, RssWidgetConfig(feedSourceId: "test", feedSourceName: "Test"));

      final itemA = dashboardBox.get(itemA_initial.id)!;
      final itemB = dashboardBox.get(itemB_initial.id)!;
      final itemC = dashboardBox.get(itemC_initial.id)!;

      final reorderedItemsInput = [ itemC, itemA, itemB ];

      await dashboardService.updateDashboardItemOrder(reorderedItemsInput);

      final storedItemC = dashboardBox.get(itemC.id);
      final storedItemA = dashboardBox.get(itemA.id);
      final storedItemB = dashboardBox.get(itemB.id);

      expect(storedItemC?.order, 0);
      expect(storedItemA?.order, 1);
      expect(storedItemB?.order, 2);
    });
  });
}
