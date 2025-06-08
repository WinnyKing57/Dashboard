import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_item.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:flutter_dashboard_app/src/features/rss/feed_items_view.dart'; // To navigate to full feed view
import 'package:url_launcher/url_launcher.dart';


class RssDashboardWidget extends StatefulWidget {
  final RssWidgetConfig config;
  final RssService? rssServiceForTest; // New field

  const RssDashboardWidget({
    super.key,
    required this.config,
    this.rssServiceForTest, // Added to constructor
  });

  @override
  State<RssDashboardWidget> createState() => _RssDashboardWidgetState();
}

class _RssDashboardWidgetState extends State<RssDashboardWidget> {
  late RssService _rssService; // Made late
  List<RssFeedItem> _feedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rssService = widget.rssServiceForTest ?? RssService(); // Use injected or default
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      // Fetch new items, then get cached (which will include the new ones)
      await _rssService.fetchAndCacheFeedItems(widget.config.feedSourceId);
      _feedItems = _rssService.getCachedFeedItems(widget.config.feedSourceId);
    } catch (e) {
      print('Error fetching RSS items for dashboard widget: $e');
      // Load cached items even if fetch fails
      _feedItems = _rssService.getCachedFeedItems(widget.config.feedSourceId);
    }
    if (mounted) {
      setState(() { _isLoading = false; });
    }
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


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: InkWell( // Added InkWell for general tap feedback if desired on the whole card (optional)
        onTap: () {
          // Optional: action if the whole card is tapped
          // For now, specific actions are on buttons/items
        },
        splashColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        highlightColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'RSS: ${widget.config.feedSourceName}',
                      style: Theme.of(context).textTheme.titleMedium, // Corrected style assignment
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton( // Already has feedback
                    icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                    onPressed: _fetchItems,
                    tooltip: 'Refresh Feed',
                  )
                ],
              ),
              const SizedBox(height: 8.0),
              Expanded( // Ensure this Expanded takes the remaining space
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _feedItems.isEmpty
                      ? Center(child: Text('No articles found.', style: Theme.of(context).textTheme.bodyMedium))
                        : ListView.builder(
                            // Take top 3-5 items for summary
                            itemCount: _feedItems.length > 5 ? 5 : _feedItems.length,
                            itemBuilder: (context, index) {
                              final item = _feedItems[index];
                              return ListTile( // ListTile provides its own feedback
                                dense: true,
                                title: Text(item.title ?? 'No Title', maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text(item.pubDate != null ? item.pubDate!.substring(0,10) : '', maxLines: 1),
                                onTap: item.link != null ? () => _launchUrl(item.link!) : null,
                              );
                            },
                          ),
              ), // End of Expanded, ensure comma if TextButton follows
              TextButton( // Already has feedback
                child: const Text('View all items...'),
                onPressed: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedItemsView(
                      feedSourceId: widget.config.feedSourceId,
                      feedSourceName: widget.config.feedSourceName,
                    ),
                  ),
                );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
