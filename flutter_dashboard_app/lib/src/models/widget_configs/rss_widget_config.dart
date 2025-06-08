import 'package:hive/hive.dart';

part 'rss_widget_config.g.dart';

@HiveType(typeId: 5) // Ensure this typeId is unique
class RssWidgetConfig extends HiveObject {
  @HiveField(0)
  String feedSourceId;

  @HiveField(1)
  String feedSourceName; // Store name for easier display on widget

  RssWidgetConfig({
    required this.feedSourceId,
    required this.feedSourceName,
  });
}
