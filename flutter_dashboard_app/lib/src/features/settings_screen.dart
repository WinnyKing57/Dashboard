import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function(Color)? onColorSeedChanged; // Add this new callback

  const SettingsScreen({
    super.key,
    this.onThemeChanged,
    this.onColorSeedChanged, // Add to constructor
  });

  // Helper method to show ThemeMode selection dialog
  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Theme Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light, // Approximate current
                onChanged: (ThemeMode? value) {
                  if (value != null && onThemeChanged != null) {
                    onThemeChanged!(value);
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                onChanged: (ThemeMode? value) {
                  if (value != null && onThemeChanged != null) {
                    onThemeChanged!(value);
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light, // This needs to be improved if we store actual ThemeMode
                onChanged: (ThemeMode? value) {
                  if (value != null && onThemeChanged != null) {
                    onThemeChanged!(value);
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to show Color selection dialog
  void _showColorDialog(BuildContext context) {
    final List<Color> predefinedColors = [
      Colors.blue, Colors.teal, Colors.indigo, Colors.red, Colors.green, Colors.orange, Colors.purple
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select App Color'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: predefinedColors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Adjust for better layout
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemBuilder: (BuildContext context, int index) {
                final color = predefinedColors[index];
                return InkWell(
                  onTap: () {
                    if (onColorSeedChanged != null) {
                      onColorSeedChanged!(color);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.black38,
                        width: 1.5
                      )
                    ),
                    // Optional: show a checkmark if this is the current color
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current seed color to display (approximation, real value is in MyAppState)
    // This is just for display in the ListTile, MyAppState holds the truth.
    Color currentSeedColorDisplay = Theme.of(context).colorScheme.primary;

    // Removed Scaffold and AppBar. The ListView is returned directly.
    return ListView(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            // Subtitle could show current theme, e.g., "Light", "Dark", "System"
            // This would require getting the actual current ThemeMode from MyAppState
            subtitle: Text(Theme.of(context).brightness == Brightness.dark ? "Dark" : "Light"), // Simplified
            onTap: () {
              if (onThemeChanged != null) {
                _showThemeModeDialog(context);
              }
            },
          ), // End of first ListTile

        /* Temporarily commented out:
        ListTile(
          leading: Icon(Icons.color_lens, color: currentSeedColorDisplay),
          title: const Text('App Color'),
          subtitle: const Text('Select the primary color for the app theme'),
          onTap: () {
            if (onColorSeedChanged != null) {
              _showColorDialog(context);
            }
          },
        )
        */
          // Add other settings here in the future
        ],
      ),
    );
  }
}
