import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // For date formatting

class FeedItemsView extends StatefulWidget {
  final String feedSourceId;
  final String feedSourceName;

  const FeedItemsView({
    super.key,
    required this.feedSourceId,
    required this.feedSourceName,
  });

  @override
  State<FeedItemsView> createState() => _FeedItemsViewState();
}

class _FeedItemsViewState extends State<FeedItemsView> {
  final RssService _rssService = RssService();
  List<RssFeedItem> _feedItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeedItems(showLoadingIndicator: true);
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'No date';
    }
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy HH:mm').format(dateTime); // Example: Jan 1, 2023 14:30
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  Future<void> _loadFeedItems({bool showLoadingIndicator = false}) async {
    if (mounted) {
      setState(() {
        if (showLoadingIndicator) _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // First, try to load cached items quickly
      final cachedItems = _rssService.getCachedFeedItems(widget.feedSourceId);
      if (mounted && cachedItems.isNotEmpty) {
        setState(() {
          _feedItems = cachedItems;
        });
      }

      // Then, fetch from network
      final fetchedItems = await _rssService.fetchAndCacheFeedItems(widget.feedSourceId);
      if (mounted) {
        setState(() {
          _feedItems = fetchedItems;
          if (_feedItems.isEmpty) {
            _errorMessage = 'No items found for this feed.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading feed items: ${e.toString()}';
        });
      }
    } finally {
      if (mounted && showLoadingIndicator) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feedSourceName),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFeedItems(showLoadingIndicator: false), // Already have pull-to-refresh indicator
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error))))
                : _feedItems.isEmpty
                    ? Center(child: Text('No items found for "${widget.feedSourceName}". Pull to refresh.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center,))
                    : ListView.builder(
                        itemCount: _feedItems.length,
                        itemBuilder: (context, index) {
                          final item = _feedItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: ListTile(
                              title: Text(item.title ?? 'No title'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description?.replaceAll(RegExp(r'<[^>]*>'), '') ?? 'No description', // Basic HTML strip
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(item.pubDate),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              onTap: item.link != null ? () => _launchUrl(item.link!) : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
