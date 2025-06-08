import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
// http_testing.dart is no longer needed as we inject the client
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'rss_service_test.mocks.dart';
import 'dart:io';


@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RssService rssService;
  late Box<RssFeedSource> rssSourcesBox;
  late Box<RssFeedItem> rssItemsBox;
  late MockClient mockHttpClient; // MockClient will be injected

  final String sourcesBoxName = RssService.getSourcesBoxNameTestOnly();
  final String itemsBoxName = RssService.getItemsBoxNameTestOnly();

  setUpAll(() async {
    var path = Directory.systemTemp.createTempSync('hive_rss_test_').path;
    Hive.init(path);
    if (!Hive.isAdapterRegistered(RssFeedSourceAdapter().typeId)) {
      Hive.registerAdapter(RssFeedSourceAdapter());
    }
    if (!Hive.isAdapterRegistered(RssFeedItemAdapter().typeId)) {
      Hive.registerAdapter(RssFeedItemAdapter());
    }
  });

  setUp(() async {
    mockHttpClient = MockClient(); // Create mock client
    rssService = RssService(client: mockHttpClient); // Inject mock client

    if(Hive.isBoxOpen(sourcesBoxName)) await Hive.box(sourcesBoxName).deleteFromDisk();
    rssSourcesBox = await Hive.openBox<RssFeedSource>(sourcesBoxName);

    if(Hive.isBoxOpen(itemsBoxName)) await Hive.box(itemsBoxName).deleteFromDisk();
    rssItemsBox = await Hive.openBox<RssFeedItem>(itemsBoxName);
  });

  tearDown(() async {
    if (rssSourcesBox.isOpen) await rssSourcesBox.deleteFromDisk();
    if (rssItemsBox.isOpen) await rssItemsBox.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
  });


  group('RssService Hive Interactions', () {
    const sampleFeedUrl = 'https://www.example.com/feed.xml';
    const sampleFeedId = 'test-feed-id';

    // addFeedSourceWithDetails does not use HTTP client, so it's a pure Hive interaction test
    test('addFeedSourceWithDetails successfully adds a new feed source', () async {
      await rssService.addFeedSourceWithDetails(id: sampleFeedId, url: sampleFeedUrl, name: 'Test Feed');

      final sources = rssService.getFeedSources();
      expect(sources.length, 1);
      expect(sources.first.url, sampleFeedUrl);
      expect(sources.first.name, 'Test Feed');
      expect(rssSourcesBox.containsKey(sampleFeedId), isTrue);
    });

    test('removeFeedSource removes source and its items', () async {
      final source = RssFeedSource(id: sampleFeedId, url: sampleFeedUrl, name: 'Test Feed');
      await rssSourcesBox.put(sampleFeedId, source);
      final item1 = RssFeedItem(feedSourceId: sampleFeedId, title: 'Item 1', link: 'link1', guid: 'guid1');
      item1.itemUniqueKey = '${sampleFeedId}_guid1';
      final item2 = RssFeedItem(feedSourceId: sampleFeedId, title: 'Item 2', link: 'link2', guid: 'guid2');
      item2.itemUniqueKey = '${sampleFeedId}_guid2';
      await rssItemsBox.put(item1.itemUniqueKey!, item1);
      await rssItemsBox.put(item2.itemUniqueKey!, item2);

      await rssService.removeFeedSource(sampleFeedId);

      expect(rssService.getFeedSources().isEmpty, isTrue);
      expect(rssSourcesBox.containsKey(sampleFeedId), isFalse);
      expect(rssItemsBox.isEmpty, isTrue);
    });

    test('getFeedSources retrieves sources from box', () async {
      final source1 = RssFeedSource(id: 'id1', url: 'url1', name: 'Feed 1');
      final source2 = RssFeedSource(id: 'id2', url: 'url2', name: 'Feed 2');
      await rssSourcesBox.put('id1', source1);
      await rssSourcesBox.put('id2', source2);

      final sources = rssService.getFeedSources();
      expect(sources.length, 2);
    });

    test('getCachedFeedItems retrieves and sorts items correctly', () async {
      final item1 = RssFeedItem(feedSourceId: sampleFeedId, title: 'Older Item', pubDate: DateTime(2023, 1, 1).toIso8601String(), guid: "1");
      item1.itemUniqueKey = '${sampleFeedId}_1';
      final item2 = RssFeedItem(feedSourceId: sampleFeedId, title: 'Newer Item', pubDate: DateTime(2023, 1, 2).toIso8601String(), guid: "2");
      item2.itemUniqueKey = '${sampleFeedId}_2';
      final item3 = RssFeedItem(feedSourceId: "otherId", title: 'Other Feed Item', pubDate: DateTime(2023, 1, 3).toIso8601String(), guid: "3");
      item3.itemUniqueKey = 'otherId_3';

      await rssItemsBox.put(item1.itemUniqueKey!, item1);
      await rssItemsBox.put(item2.itemUniqueKey!, item2);
      await rssItemsBox.put(item3.itemUniqueKey!, item3);

      final cachedItems = rssService.getCachedFeedItems(sampleFeedId);
      expect(cachedItems.length, 2);
      expect(cachedItems.first.title, 'Newer Item');
      expect(cachedItems.last.title, 'Older Item');
    });
  });

  group('RssService Network Operations', () {
    const sampleRssUrl = 'https://www.validfeed.com/rss.xml';
    const sampleAtomUrl = 'https://www.validfeed.com/atom.xml';
    const malformedUrl = 'https://www.malformedfeed.com/rss.xml';

    test('addFeedSource handles successful RSS response', () async {
      when(mockHttpClient.get(Uri.parse(sampleRssUrl), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
            '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>Test RSS Feed</title></channel></rss>',
            200));

      final source = await rssService.addFeedSource(sampleRssUrl);
      expect(source, isNotNull);
      expect(source?.name, 'Test RSS Feed');
      if (source != null) {
        expect(rssSourcesBox.containsKey(source.id), isTrue);
      }
      verify(mockHttpClient.get(Uri.parse(sampleRssUrl), headers: anyNamed('headers'))).called(1);
    });

    test('addFeedSource handles successful Atom response', () async {
      when(mockHttpClient.get(Uri.parse(sampleAtomUrl), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
            '<?xml version="1.0" encoding="UTF-8"?><feed xmlns="http://www.w3.org/2005/Atom"><title>Test Atom Feed</title></feed>',
            200));

      final source = await rssService.addFeedSource(sampleAtomUrl);
      expect(source, isNotNull);
      expect(source?.name, 'Test Atom Feed');
      verify(mockHttpClient.get(Uri.parse(sampleAtomUrl), headers: anyNamed('headers'))).called(1);
    });

    test('addFeedSource handles HTTP error', () async {
      when(mockHttpClient.get(Uri.parse(sampleRssUrl), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final source = await rssService.addFeedSource(sampleRssUrl);
      expect(source, isNull);
      verify(mockHttpClient.get(Uri.parse(sampleRssUrl), headers: anyNamed('headers'))).called(1);
    });

    test('addFeedSource handles parsing error (malformed XML)', () async {
      when(mockHttpClient.get(Uri.parse(malformedUrl), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('this is not xml', 200));

      final source = await rssService.addFeedSource(malformedUrl);
      expect(source, isNotNull);
      expect(source?.name, malformedUrl); // Falls back to URL as name
      verify(mockHttpClient.get(Uri.parse(malformedUrl), headers: anyNamed('headers'))).called(1);
    });

    test('fetchAndCacheFeedItems successfully fetches and parses RSS', () async {
        final source = RssFeedSource(id: 'test-rss', url: sampleRssUrl, name: 'Test RSS');
        await rssSourcesBox.put(source.id, source);

        when(mockHttpClient.get(Uri.parse(sampleRssUrl), headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>Test RSS Feed</title><item><title>Item 1</title><link>link1</link><guid>guid1</guid></item></channel></rss>',
                200));

        final items = await rssService.fetchAndCacheFeedItems(source.id);
        expect(items, isNotEmpty);
        expect(items.first.title, 'Item 1');
        expect(rssItemsBox.values.where((item) => item.feedSourceId == source.id).length, 1);
        verify(mockHttpClient.get(Uri.parse(sampleRssUrl), headers: anyNamed('headers'))).called(1);
    });

     test('fetchAndCacheFeedItems successfully fetches and parses Atom', () async {
        final source = RssFeedSource(id: 'test-atom', url: sampleAtomUrl, name: 'Test Atom');
        await rssSourcesBox.put(source.id, source);

        when(mockHttpClient.get(Uri.parse(sampleAtomUrl), headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
                '<?xml version="1.0" encoding="UTF-8"?><feed xmlns="http://www.w3.org/2005/Atom"><title>Test Atom Feed</title><entry><title>Atom Item 1</title><id>atom-guid1</id><link href="atom-link1"/></entry></feed>',
                200));

        final items = await rssService.fetchAndCacheFeedItems(source.id);
        expect(items, isNotEmpty);
        expect(items.first.title, 'Atom Item 1');
        expect(rssItemsBox.values.where((item) => item.feedSourceId == source.id).length, 1);
        verify(mockHttpClient.get(Uri.parse(sampleAtomUrl), headers: anyNamed('headers'))).called(1);
    });
  });
}
