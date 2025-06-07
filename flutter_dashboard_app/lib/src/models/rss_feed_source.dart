import 'package:hive/hive.dart';

part 'rss_feed_source.g.dart';

@HiveType(typeId: 3) // Unique typeId
class RssFeedSource extends HiveObject {
  @HiveField(0)
  String id; // Unique identifier (e.g., generated from URL or UUID)

  @HiveField(1)
  String url; // The URL of the RSS feed

  @HiveField(2)
  String? name; // Optional name, can be fetched from the feed itself

  RssFeedSource({
    required this.id,
    required this.url,
    this.name,
  });
}
