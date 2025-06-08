import 'package:hive/hive.dart';

part 'rss_feed_item.g.dart';

@HiveType(typeId: 4) // Unique typeId
class RssFeedItem extends HiveObject {
  @HiveField(0)
  String? guid; // Unique identifier for the item, often from <guid> tag

  @HiveField(1)
  String? title;

  @HiveField(2)
  String? link;

  @HiveField(3)
  String? description; // Can be HTML or plain text

  @HiveField(4)
  String? pubDate; // Publication date as a string

  @HiveField(5)
  String feedSourceId; // To link back to RssFeedSource.id

  // It's good practice to have a unique key for Hive, if not using HiveObject's default int key.
  // We can combine feedSourceId and guid (or link if guid is missing)
  @HiveField(6)
  String? itemUniqueKey;


  RssFeedItem({
    this.guid,
    this.title,
    this.link,
    this.description,
    this.pubDate,
    required this.feedSourceId,
  }){
    itemUniqueKey = '${feedSourceId}_${guid ?? link ?? DateTime.now().millisecondsSinceEpoch}';
  }
}
