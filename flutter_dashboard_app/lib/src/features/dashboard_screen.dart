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
  // For test injection
  final DashboardService? _dashboardServiceForTest;
  final RssService? _rssServiceForTest;

  const DashboardScreen({
    super.key,
    DashboardService? dashboardServiceForTest,
    RssService? rssServiceForTest,
  }) : _dashboardServiceForTest = dashboardServiceForTest,
       _rssServiceForTest = rssServiceForTest;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _dashboardService;
  late final RssService _rssService;
  List<DashboardItem> _dashboardItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget._dashboardServiceForTest ?? DashboardService();
    _rssService = widget._rssServiceForTest ?? RssService();
    _loadDashboardItems();
  }

  // Methods like _loadDashboardItems, _addInitialItems, etc. remain the same as the correct version from read_files output
  // ... (assuming the rest of the methods from the read_files output are here and correct) ...
  Future<void> _loadDashboardItems() async {
    if(mounted) setState(() { _isLoading = true; });
    _dashboardItems = _dashboardService.getDashboardItems();
    if (_dashboardItems.isEmpty) {
      await _addInitialItems();
       _dashboardItems = _dashboardService.getDashboardItems();
    }
    if(mounted) setState(() { _isLoading = false; });
  }

  Future<void> _addInitialItems() async {
    await _dashboardService.createAndSavePlaceholderItem(0);
    await _dashboardService.createAndSaveNotepadItem(1);
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
      _dashboardService.updateDashboardItemOrder(_dashboardItems);
    });
  }

  Widget _buildWidgetItem(DashboardItem item, BuildContext context) {
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
    return Stack(
      key: ValueKey(item.id),
      children: [
        content,
        Positioned(
          top: 0,
          right: 0,
          child: Material(
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
              ? Center(child: Text('No items on dashboard. Add some!', style: Theme.of(context).textTheme.bodyLarge))
              : ReorderableGridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 3 / 2,
                  ),
                  itemCount: _dashboardItems.length,
                  itemBuilder: (context, index) {
                    final item = _dashboardItems[index];
                    return _buildWidgetItem(item, context);
                  },
                  onReorder: _onReorder,
                ),
    );
  }
}
