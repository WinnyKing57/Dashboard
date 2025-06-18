import 'package:flutter/material.dart';
import './widgets/label_widget.dart'; // Assuming label_widget.dart is in a sub-directory 'widgets'

// Definition for the function type we might use if we need to pass this factory around.
// typedef WidgetBuilderFromJson = Widget Function(Map<String, dynamic> widgetJson);

Widget buildWidgetFromJson(Map<String, dynamic> widgetJson) {
  final type = widgetJson['type'] as String?;
  // widget_id might be used later for providing a Key to the widget if needed for state management in lists
  // final widgetId = widgetJson['widget_id'] as String?;
  final config = widgetJson['config'] as Map<String, dynamic>? ?? const {}; // Ensure config is always a Map

  // Create a key for the widget, can be useful if widgets are reordered or rebuilt in a list
  // If widgetId is null or not provided, a UniqueKey can be used, or it can be omitted.
  // For now, let's make it optional and not pass it to LabelWidget unless LabelWidget is designed to use it.
  // final Key? widgetKey = widgetId != null ? ValueKey(widgetId) : null;

  switch (type) {
    case 'label':
      return LabelWidget(config: config); // Pass the key here if LabelWidget takes it: key: widgetKey
    // Add other widget types here in the future
    // case 'weather':
    //   return WeatherWidget(config: config, key: widgetKey);
    default:
      // Return a more informative placeholder for unknown widget types
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Unknown widget type: $type',
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
  }
}
