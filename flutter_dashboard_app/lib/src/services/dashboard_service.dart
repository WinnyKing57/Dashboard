import 'package:hive/hive.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart'; // Import new config model
import 'package:uuid/uuid.dart'; // For generating unique IDs

class DashboardService {
  static const String _dashboardBoxName = 'dashboardItemsBox';
  // static const String _notepadBoxName = 'notepadDataBox'; // If storing NotepadData separately
  final Uuid _uuid = const Uuid();

  // FOR TEST PURPOSES ONLY
  static String getBoxNameTestOnly() => _dashboardBoxName;

  Box<DashboardItem> get _dashboardBox => Hive.box<DashboardItem>(_dashboardBoxName);
  // Box<NotepadData> get _notepadBox => Hive.box<NotepadData>(_notepadBoxName);


  // DashboardItem Methods
  Future<void> saveDashboardItem(DashboardItem item) async {
    await _dashboardBox.put(item.id, item);
  }

  Future<void> deleteDashboardItem(String id) async {
    // Also need to handle deletion of associated widgetData if it's not automatically handled
    // For embedded HiveObjects, Hive should handle this.
    // If widgetData were a key to another box, we'd delete that entry too.
    await _dashboardBox.delete(id);
  }

  List<DashboardItem> getDashboardItems() {
    final items = _dashboardBox.values.toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  Future<DashboardItem> createAndSaveNotepadItem(int order) async {
    final notepadData = NotepadData(content: ''); // Create new NotepadData
    // Since NotepadData is a HiveObject, it doesn't need its own box if embedded.
    // It will be saved as part of DashboardItem.

    final newItem = DashboardItem(
      id: _uuid.v4(),
      widgetType: 'notepad',
      order: order,
      widgetData: notepadData, // Embed NotepadData directly
    );
    await saveDashboardItem(newItem);
    return newItem;
  }

  Future<DashboardItem> createAndSavePlaceholderItem(int order) async {
    final newItem = DashboardItem(
      id: _uuid.v4(),
      widgetType: 'placeholder',
      order: order,
      widgetData: null, // Placeholders might not have specific data
    );
    await saveDashboardItem(newItem);
    return newItem;
  }

  // Specific method to update NotepadData within a DashboardItem
  // This is called from NotepadWidget
  Future<void> updateNotepadData(String dashboardItemId, NotepadData newNotepadData) async {
    final item = _dashboardBox.get(dashboardItemId);
    if (item != null && item.widgetData is NotepadData) {
      // Since NotepadData is a HiveObject and part of DashboardItem,
      // modifying its fields and then saving the parent DashboardItem should persist changes.
      // HiveObjects track their changes.
      (item.widgetData as NotepadData).content = newNotepadData.content;
      await item.save(); // This should save the DashboardItem with the updated NotepadData
    }
  }

  Future<void> updateDashboardItemOrder(List<DashboardItem> items) async {
    // Use a batch operation if Hive supports it well, or loop and save.
    // For simplicity, looping and saving. Consider Hive batch for performance on large lists.
    for (int i = 0; i < items.length; i++) {
      items[i].order = i;
      await items[i].save(); // Call save() on HiveObject directly
    }
  }

  Future<DashboardItem> createAndSaveRssWidgetConfigItem(int order, RssWidgetConfig config) async {
    final newItem = DashboardItem(
      id: _uuid.v4(),
      widgetType: 'rss_summary', // New widget type
      order: order,
      widgetData: config, // Store the RssWidgetConfig
    );
    await saveDashboardItem(newItem);
    return newItem;
  }

  Future<DashboardItem> createAndSaveWebRadioStatusItem(int order) async {
    // For now, WebRadio widget might not have specific data, or it could be a placeholder
    final newItem = DashboardItem(
      id: _uuid.v4(),
      widgetType: 'webradio_status', // New widget type
      order: order,
      widgetData: null, // Or some basic config if needed later
    );
    await saveDashboardItem(newItem);
    return newItem;
  }

  Future<void> clearAllDashboardItems() async {
    // This needs to be careful if widgetData HiveObjects are stored separately
    // and not just embedded. If they are embedded, clearing the DashboardItem
    // should be enough for Hive to eventually reclaim space if these objects are not referenced elsewhere.
    // If widgetData itself is a HiveObject stored in its own box, you would clear that box too.
    // For current setup (NotepadData embedded, RssWidgetConfig embedded):
    await _dashboardBox.clear();
  }

  Future<void> importDashboardItems(List<dynamic> itemsJson) async {
    for (var itemData in itemsJson) {
      if (itemData is Map<String, dynamic>) {
        HiveObject? widgetData;
        Map<String, dynamic>? widgetDataJson = itemData['widgetData'];

        if (widgetDataJson != null) {
          String type = widgetDataJson['type'];
          if (type == 'NotepadData') {
            widgetData = NotepadData(content: widgetDataJson['content'] ?? '');
          } else if (type == 'RssWidgetConfig') {
            widgetData = RssWidgetConfig(
              feedSourceId: widgetDataJson['feedSourceId'] ?? '',
              feedSourceName: widgetDataJson['feedSourceName'] ?? '',
            );
            // Ensure feedSourceId is not empty if it's critical
            if ((widgetData as RssWidgetConfig).feedSourceId.isEmpty) {
                print("Warning: Importing RssWidgetConfig with empty feedSourceId for item ${itemData['id']}");
            }
          }
        }

        final item = DashboardItem(
          id: itemData['id'] ?? _uuid.v4(), // Generate new ID if missing, though import should have IDs
          widgetType: itemData['widgetType'] ?? 'placeholder',
          order: itemData['order'] ?? 0,
          widgetData: widgetData,
        );
        await saveDashboardItem(item);
      }
    }
  }
}
