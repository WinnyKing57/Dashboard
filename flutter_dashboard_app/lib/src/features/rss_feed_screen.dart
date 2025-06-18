import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_dashboard_app/src/features/rss/feed_items_view.dart'; // Import the new view
// import 'package:url_launcher/url_launcher.dart'; // For opening links later


class RssFeedScreen extends StatefulWidget {
  const RssFeedScreen({super.key});

  @override
  State<RssFeedScreen> createState() => _RssFeedScreenState();
}

class _RssFeedScreenState extends State<RssFeedScreen> {
  final RssService _rssService = RssService();
  List<RssFeedSource> _feedSources = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFeedSources();
  }

  Future<void> _loadFeedSources() async {
    setState(() {
      _isLoading = true;
    });
    _feedSources = _rssService.getFeedSources();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addFeedSourceDialog() async {
    final TextEditingController urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add RSS Feed Source'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'Enter feed URL'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a URL';
                }
                if (!(Uri.tryParse(value)?.hasAbsolutePath == true)) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  setState(() { _isLoading = true; });
                  Navigator.of(context).pop(); // Close dialog
                  RssFeedSource? newSource = await _rssService.addFeedSource(urlController.text);
                  if (newSource != null) {
                    // Optionally, fetch items for the new source immediately
                    // await _rssService.fetchAndCacheFeedItems(newSource.id);
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Feed "${newSource.name}" added successfully!')),
                    );
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add feed. Check URL and connectivity.')),
                    );
                  }
                  _loadFeedSources(); // Refresh the list
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFeedSource(String id) async {
    setState(() { _isLoading = true; });
    await _rssService.removeFeedSource(id);
    _loadFeedSources();
    if (mounted) { // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feed source removed.')),
      );
    }
  }

  void _navigateToFeedItems(RssFeedSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedItemsView( // Navigate to the new FeedItemsView
          feedSourceId: source.id,
          feedSourceName: source.name ?? source.url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget bodyContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _feedSources.isEmpty
            ? Center(child: Text('No feed sources. Add some!', style: Theme.of(context).textTheme.bodyLarge))
            : ListView.builder(
                itemCount: _feedSources.length,
                itemBuilder: (context, index) {
                  final source = _feedSources[index];
                  return Slidable(
                    key: ValueKey(source.id),
                    endActionPane: ActionPane(
                      motion: const StretchMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) => _removeFeedSource(source.id),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(source.name ?? 'Unnamed Feed'),
                      subtitle: Text(source.url),
                      onTap: () => _navigateToFeedItems(source),
                    ),
                  );
                },
              );

    return Stack(
      children: [
        bodyContent,
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _addFeedSourceDialog,
            tooltip: 'Add Feed Source',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
