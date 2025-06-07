import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/placeholder_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/notepad_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/rss_dashboard_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/webradio_dashboard_widget.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart'; // For selecting RSS feed
import 'package:flutter_dashboard_app/src/services/dashboard_service.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart'; // For fetching RSS sources
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  final RssService _rssService = RssService(); // For selecting RSS feed
  List<DashboardItem> _dashboardItems = [];
  bool _isLoading = false; // For loading state

  @override
  void initState() {
    super.initState();
    _loadDashboardItems();
  }

  Future<void> _loadDashboardItems() async {
    if(mounted) setState(() { _isLoading = true; });
    _dashboardItems = _dashboardService.getDashboardItems();
    // If empty, add some default items
    if (_dashboardItems.isEmpty) {
      await _addInitialItems();
       _dashboardItems = _dashboardService.getDashboardItems(); // reload after adding
    }
    if(mounted) setState(() { _isLoading = false; });
  }

  Future<void> _addInitialItems() async {
    await _dashboardService.createAndSavePlaceholderItem(0);
    await _dashboardService.createAndSaveNotepadItem(1);
    // Optionally add a default RSS widget if feeds exist
    List<RssFeedSource> sources = _rssService.getFeedSources();
    if (sources.isNotEmpty) {
      await _dashboardService.createAndSaveRssWidgetConfigItem(
        2,
        RssWidgetConfig(feedSourceId: sources.first.id, feedSourceName: sources.first.name ?? sources.first.url)
      );
    }
    await _dashboardService.createAndSaveWebRadioStatusItem(3);
  }

  Future<void> _addNotepadWidget() async {
    await _dashboardService.createAndSaveNotepadItem(_dashboardItems.length);
    _loadDashboardItems();
  }

  Future<void> _addPlaceholder() async {
    await _dashboardService.createAndSavePlaceholderItem(_dashboardItems.length);
    _loadDashboardItems();
  }

  Future<void> _addRssSummaryWidget() async {
    // Show dialog to select an RSS feed
    List<RssFeedSource> sources = _rssService.getFeedSources();
    if (sources.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No RSS feeds available. Add some in the RSS tab first.')),
      );
      return;
    }

    RssFeedSource? selectedSource = await showDialog<RssFeedSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select RSS Feed'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sources.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(sources[index].name ?? sources[index].url),
                  onTap: () {
                    Navigator.of(context).pop(sources[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedSource != null) {
      final config = RssWidgetConfig(
        feedSourceId: selectedSource.id,
        feedSourceName: selectedSource.name ?? selectedSource.url,
      );
      await _dashboardService.createAndSaveRssWidgetConfigItem(_dashboardItems.length, config);
      _loadDashboardItems();
    }
  }

  Future<void> _addWebRadioStatusWidget() async {
    await _dashboardService.createAndSaveWebRadioStatusItem(_dashboardItems.length);
    _loadDashboardItems();
  }

  Future<void> _deleteDashboardItem(String id) async {
    await _dashboardService.deleteDashboardItem(id);
    _loadDashboardItems();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _dashboardItems.removeAt(oldIndex);
      _dashboardItems.insert(newIndex, item);
      // Update order field and persist
      _dashboardService.updateDashboardItemOrder(_dashboardItems);
    });
  }

  Widget _buildWidgetItem(DashboardItem item, BuildContext context) { // Added context for potential navigation
    Widget content;
    switch (item.widgetType) {
      case 'notepad':
        content = NotepadWidget(
          notepadData: item.widgetData as NotepadData,
          dashboardItemId: item.id,
        );
        break;
      case 'rss_summary':
        content = RssDashboardWidget(
          config: item.widgetData as RssWidgetConfig,
        );
        break;
      case 'webradio_status':
        content = const WebRadioDashboardWidget();
        break;
      case 'placeholder':
      default:
        content = const PlaceholderWidget();
    }
    // Wrap with Stack for delete button
    return Stack(
      key: ValueKey(item.id), // Important for reordering
      children: [
        content,
        Positioned(
          top: 0,
          right: 0,
          child: Material( // Ensures IconButton has Material parent for ink splash
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18.0),
              onPressed: () => _deleteDashboardItem(item.id),
              tooltip: 'Delete Item',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_notepad') _addNotepadWidget();
              if (value == 'add_placeholder') _addPlaceholder();
              if (value == 'add_rss_summary') _addRssSummaryWidget();
              if (value == 'add_webradio_status') _addWebRadioStatusWidget();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'add_notepad', child: Text('Add Notepad')),
              const PopupMenuItem<String>(value: 'add_placeholder', child: Text('Add Placeholder')),
              const PopupMenuItem<String>(value: 'add_rss_summary', child: Text('Add RSS Summary')),
              const PopupMenuItem<String>(value: 'add_webradio_status', child: Text('Add WebRadio Status')),
            ],
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dashboardItems.isEmpty
              ? const Center(child: Text('No items on dashboard. Add some!'))
              : ReorderableGridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 3 / 2, // Adjust as needed, might need to be more dynamic for different widget heights
                  ),
                  itemCount: _dashboardItems.length,
                  itemBuilder: (context, index) {
                    // Each item must have a unique key for ReorderableGridView
                    final item = _dashboardItems[index];
                    return _buildWidgetItem(item, context);
                  },
                  onReorder: _onReorder,
                ),
    );
  }
}
