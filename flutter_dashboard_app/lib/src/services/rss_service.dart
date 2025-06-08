import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:uuid/uuid.dart';

class RssService {
  final http.Client client; // Added for dependency injection

  static const String _sourcesBoxName = 'rssFeedSourcesBox';
  static const String _itemsBoxName = 'rssFeedItemsBox';
  final Uuid _uuid = const Uuid();

  // Constructor updated to accept an http.Client
  RssService({http.Client? client}) : client = client ?? http.Client();

  // FOR TEST PURPOSES ONLY
  static String getSourcesBoxNameTestOnly() => _sourcesBoxName;
  static String getItemsBoxNameTestOnly() => _itemsBoxName;

  Box<RssFeedSource> get _sourcesBox => Hive.box<RssFeedSource>(_sourcesBoxName);
  Box<RssFeedItem> get _itemsBox => Hive.box<RssFeedItem>(_itemsBoxName);

  Future<RssFeedSource?> addFeedSource(String url) async {
    try {
      // Use the injected client
      final response = await client.get(Uri.parse(url), headers: {'User-Agent': 'FlutterDashboardApp/1.0'});
      if (response.statusCode == 200) {
        String? feedTitle;
        try {
          // Try parsing as RSS
          var rssFeed = RssFeed.parse(response.body);
          feedTitle = rssFeed.title;
        } catch (e) {
          // Try parsing as Atom
          try {
            var atomFeed = AtomFeed.parse(response.body);
            feedTitle = atomFeed.title;
          } catch (e) {
            print('Error parsing feed as RSS or Atom: $e');
            // Could not parse as either, use URL as name or return null/throw error
          }
        }

        final newSource = RssFeedSource(
          id: _uuid.v4(),
          url: url,
          name: feedTitle ?? url, // Use fetched title or fallback to URL
        );
        await _sourcesBox.put(newSource.id, newSource);
        return newSource;
      } else {
        print('Error fetching feed source: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error adding feed source: $e');
      return null;
    }
  }

  Future<void> removeFeedSource(String id) async {
    await _sourcesBox.delete(id);
    // Also remove all items associated with this feed source
    final itemsToRemove = _itemsBox.values.where((item) => item.feedSourceId == id).toList();
    for (var item in itemsToRemove) {
      await _itemsBox.delete(item.itemUniqueKey);
    }
  }

  List<RssFeedSource> getFeedSources() {
    return _sourcesBox.values.toList();
  }

  Future<List<RssFeedItem>> fetchAndCacheFeedItems(String feedSourceId) async {
    final source = _sourcesBox.get(feedSourceId);
    if (source == null) {
      print('Feed source not found: $feedSourceId');
      return [];
    }

    List<RssFeedItem> fetchedItems = [];
    try {
      // Use the injected client
      final response = await client.get(Uri.parse(source.url), headers: {'User-Agent': 'FlutterDashboardApp/1.0'});
      if (response.statusCode == 200) {
        dynamic feed; // Can be RssFeed or AtomFeed
        try {
          feed = RssFeed.parse(response.body);
        } catch (e) {
          try {
            feed = AtomFeed.parse(response.body);
          } catch (e) {
            print('Failed to parse feed from ${source.url}: $e');
            return getCachedFeedItems(feedSourceId); // Return cached on error
          }
        }

        if (feed != null) {
          if (feed is RssFeed) {
            for (var item in feed.items ?? []) {
              final rssItem = RssFeedItem(
                guid: item.guid,
                title: item.title,
                link: item.link,
                description: item.description ?? item.content?.value,
                pubDate: item.pubDate?.toIso8601String(),
                feedSourceId: feedSourceId,
              );
              await _itemsBox.put(rssItem.itemUniqueKey, rssItem);
              fetchedItems.add(rssItem);
            }
          } else if (feed is AtomFeed) {
            for (var item in feed.items ?? []) {
              String? extractedLink;
              if (item.links != null && item.links!.isNotEmpty) {
                AtomLink? linkToUse;
                // Try to find 'alternate'
                for (final link in item.links!) {
                  if (link.rel == 'alternate') {
                    linkToUse = link;
                    break;
                  }
                }
                // If no 'alternate', use the first link
                if (linkToUse == null) {
                  linkToUse = item.links!.first;
                }
                extractedLink = linkToUse.href; // Assuming href is non-null on AtomLink
              }

              final rssItem = RssFeedItem(
                // Atom uses 'id' for guid, 'updated' for pubDate
                guid: item.id,
                title: item.title,
                link: extractedLink,
                description: item.summary ?? item.content,
                pubDate: item.updated?.toIso8601String(),
                feedSourceId: feedSourceId,
              );
              await _itemsBox.put(rssItem.itemUniqueKey, rssItem);
              fetchedItems.add(rssItem);
            }
          }
        }
      } else {
        print('Error fetching items from ${source.url}: ${response.statusCode}');
        return getCachedFeedItems(feedSourceId); // Return cached on error
      }
    } catch (e) {
      print('Error fetching or parsing items from ${source.url}: $e');
      return getCachedFeedItems(feedSourceId); // Return cached on error
    }
    // Sort by date, newest first, if pubDate is available
    fetchedItems.sort((a, b) {
      if (a.pubDate == null && b.pubDate == null) return 0;
      if (a.pubDate == null) return 1; // items with no date go last
      if (b.pubDate == null) return -1;
      return DateTime.parse(b.pubDate!).compareTo(DateTime.parse(a.pubDate!));
    });
    return fetchedItems;
  }

  List<RssFeedItem> getCachedFeedItems(String feedSourceId) {
    final items = _itemsBox.values.where((item) => item.feedSourceId == feedSourceId).toList();
    // Sort by date, newest first
    items.sort((a, b) {
      if (a.pubDate == null && b.pubDate == null) return 0;
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return DateTime.parse(b.pubDate!).compareTo(DateTime.parse(a.pubDate!));
    });
    return items;
  }

  Future<void> refreshAllFeeds() async {
    final sources = getFeedSources();
    for (var source in sources) {
      await fetchAndCacheFeedItems(source.id);
    }
  }

  Future<void> clearAllRssData() async {
    // Clears both sources and items. Used for full import.
    await _sourcesBox.clear();
    await _itemsBox.clear();
  }

  Future<void> clearAllCachedItems() async {
    // Clears only downloaded feed items, keeps the sources.
    await _itemsBox.clear();
  }

  Future<RssFeedSource?> addFeedSourceWithDetails({required String id, required String url, String? name}) async {
    // Used during import, assumes ID is provided from backup.
    // Or could generate new if ID conflicts, though backup implies restoring same IDs.
    if (_sourcesBox.containsKey(id)) {
      print("Warning: RSS Source with ID $id already exists. Overwriting during import.");
    }
    final newSource = RssFeedSource(
      id: id,
      url: url,
      name: name ?? url,
    );
    await _sourcesBox.put(newSource.id, newSource);
    return newSource;
  }

  Future<void> importFeedItems(List<dynamic> itemsJson) async {
    for (var itemData in itemsJson) {
      if (itemData is Map<String, dynamic>) {
         final item = RssFeedItem(
            guid: itemData['guid'],
            title: itemData['title'],
            link: itemData['link'],
            description: itemData['description'],
            pubDate: itemData['pubDate'],
            feedSourceId: itemData['feedSourceId'],
            // itemUniqueKey is auto-generated in constructor if needed based on other fields
         );
         // Ensure itemUniqueKey is correctly formed or explicitly set if it was part of export
         if (itemData.containsKey('itemUniqueKey') && itemData['itemUniqueKey'] != null) {
            item.itemUniqueKey = itemData['itemUniqueKey'];
         } else {
            // Re-ensure it's set if not in backup (older backups might miss this)
            item.itemUniqueKey = '${item.feedSourceId}_${item.guid ?? item.link ?? DateTime.now().millisecondsSinceEpoch.toString()}';
         }

        // Check if feedSourceId exists before putting item
        if (_sourcesBox.containsKey(item.feedSourceId)) {
            await _itemsBox.put(item.itemUniqueKey, item);
        } else {
            print("Warning: Skipping RSS item for missing source ID: ${item.feedSourceId}");
        }
      }
    }
  }
}
