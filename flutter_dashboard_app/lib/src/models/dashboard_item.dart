import 'package:hive/hive.dart';

part 'dashboard_item.g.dart';

@HiveType(typeId: 2) // Unique typeId
class DashboardItem extends HiveObject {
  @HiveField(0)
  String id; // Unique identifier

  @HiveField(1)
  String widgetType; // e.g., "notepad", "placeholder"

  @HiveField(2)
  int order; // To maintain the order of widgets

  @HiveField(3)
  dynamic widgetData; // Holds specific data, e.g., NotepadData instance, or Map<String, dynamic> for JSON configs

  DashboardItem({
    required this.id,
    required this.widgetType,
    required this.order,
    this.widgetData,
  });
}
