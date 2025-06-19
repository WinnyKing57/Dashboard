import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/placeholder_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/notepad_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/rss_dashboard_widget.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/widgets/webradio_dashboard_widget.dart';
import 'package:flutter_dashboard_app/src/models/dashboard_item.dart';
import 'package:flutter_dashboard_app/src/models/notepad_data.dart';
import 'package:flutter_dashboard_app/src/models/widget_configs/rss_widget_config.dart';
import 'package:flutter_dashboard_app/src/models/rss_feed_source.dart';
import 'package:flutter_dashboard_app/src/services/dashboard_service.dart';
import 'package:flutter_dashboard_app/src/services/rss_service.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../widget_factory.dart'; // Adjusted path

class DashboardScreen extends StatefulWidget {
  final DashboardService? _dashboardServiceForTest;
  final RssService? _rssServiceForTest;

  const DashboardScreen({
    super.key,
    DashboardService? dashboardServiceForTest,
    RssService? rssServiceForTest,
  })  : _dashboardServiceForTest = dashboardServiceForTest,
        _rssServiceForTest = rssServiceForTest;

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
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

  Future<void> _loadDashboardItems() async {
    if (mounted) setState(() => _isLoading = true);
    _dashboardItems = _dashboardService.getDashboardItems();
    if (_dashboardItems.isEmpty) {
      await _addInitialItems();
      _dashboardItems = _dashboardService.getDashboardItems();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addInitialItems() async {
    int currentOrder = 0;
    // Ensure we use the service instance available in the state
    await _dashboardService.createAndSavePlaceholderItem(currentOrder++);
    await _dashboardService.createAndSaveNotepadItem(currentOrder++);

    List<RssFeedSource> sources = _rssService.getFeedSources();
    if (sources.isNotEmpty) {
      await _dashboardService.createAndSaveRssWidgetConfigItem(
        currentOrder++,
        RssWidgetConfig(
          feedSourceId: sources.first.id,
          feedSourceName: sources.first.name ?? sources.first.url,
        ),
      );
    }
    await _dashboardService.createAndSaveWebRadioStatusItem(currentOrder++);
  }

  Future<void> callAddNotepadWidget() async {
    await _dashboardService.createAndSaveNotepadItem(_dashboardItems.length);
    _loadDashboardItems();
  }

  Future<void> callAddPlaceholder() async {
    await _dashboardService.createAndSavePlaceholderItem(_dashboardItems.length);
    _loadDashboardItems();
  }

  Future<void> callAddRssSummaryWidget() async {
    List<RssFeedSource> sources = _rssService.getFeedSources();
    if (sources.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No RSS feeds available. Add some in the RSS tab first.')),
        );
      }
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

  Future<void> callAddWebRadioStatusWidget() async {
    await _dashboardService.createAndSaveWebRadioStatusItem(_dashboardItems.length);
    _loadDashboardItems();
  }

  Future<void> callAddDynamicLabelWidget() async {
    // Example configuration for a new label widget
    final Map<String, dynamic> labelConfig = {
      "text": "Hello from Dynamic Label!",
      "textColor": "#FF00FF" // Magenta color
    };
    // We'll call a new DashboardService method here in a later step.
    // For now, let's assume it will be:
    // await _dashboardService.createAndSaveDynamicWidgetItem(_dashboardItems.length, "label", labelConfig);
    // For this subtask, we'll just log it and call _loadDashboardItems to simulate.
    print("Attempting to add dynamic label with config: $labelConfig");
    // The actual saving logic will be in the DashboardService modification step.
    await _dashboardService.createAndSaveDynamicWidgetItem(
        _dashboardItems.length, "label", labelConfig);
    _loadDashboardItems(); // Reload to see changes
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
      case 'label':
        if (item.widgetData is Map<String, dynamic>) {
          // Construct the JSON object expected by buildWidgetFromJson
          final widgetJson = {
            "widget_id": item.id, // Pass the item's ID
            "type": "label",
            "config": item.widgetData as Map<String, dynamic>,
          };
          content = buildWidgetFromJson(widgetJson);
        } else {
          content = const Text('Error: Label widgetData is not a valid config map');
        }
        break;
      case 'notepad':
        content = NotepadWidget(
          notepadData: item.widgetData as NotepadData,
          dashboardItemId: item.id,
        );
        break;
      case 'rss_summary':
        content = RssDashboardWidget(
          config: item.widgetData as RssWidgetConfig,
          rssServiceForTest: _rssService, // Pass the screen's RssService instance
        );
        break;
      case 'webradio_status':
        content = const WebRadioDashboardWidget();
        break;
      case 'placeholder':
      default:
        content = PlaceholderWidget(); // <- ✅ Correction ici
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
    // Removed Scaffold and AppBar. The body is returned directly.
    // The PopupMenuButton for adding items will need to be moved to MainNavigationScreen's AppBar
    // or handled via another UI element if dashboard-specific actions are needed.
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _dashboardItems.isEmpty
            ? Center(
                child: Text(
                  'No items on dashboard. Add some!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
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
              );
  }
}