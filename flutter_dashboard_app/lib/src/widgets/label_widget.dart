import 'package:flutter/material.dart';

// Helper function to parse color strings (e.g., "#RRGGBB")
// Returns Colors.black if parsing fails or color string is invalid.
Color _parseColor(String? colorString, {Color defaultColor = Colors.black}) {
  if (colorString == null || !colorString.startsWith('#') || (colorString.length != 7 && colorString.length != 9)) {
    return defaultColor;
  }
  try {
    final String hexColor = colorString.length == 7
        ? colorString.replaceFirst('#', '0xFF') // Add FF for opaque if only RGB
        : colorString.replaceFirst('#', '0x');  // Use provided alpha if ARGB
    return Color(int.parse(hexColor));
  } catch (e) {
    // Log error or handle as needed in a real app
    // print('Error parsing color: $colorString, $e');
    return defaultColor;
  }
}

class LabelWidget extends StatelessWidget {
  final Map<String, dynamic> config;

  const LabelWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final String text = config['text'] as String? ?? 'No text provided';
    final String? textColorString = config['textColor'] as String?;

    // Default to Theme.of(context).textTheme.bodyLarge?.color for more adaptability,
    // or a hardcoded default like Colors.black if a theme-aware default is not desired.
    final Color defaultTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color textColor = _parseColor(textColorString, defaultColor: defaultTextColor);

    return Padding(
      padding: const EdgeInsets.all(8.0), // Add some padding for better visuals
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 16), // Added default font size
      ),
    );
  }
}
