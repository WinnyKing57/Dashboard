import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode)? onThemeChanged;
  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            if (onThemeChanged != null) {
              // Example: toggle between light and dark mode for demonstration
              // A more robust implementation might check current theme.
              final currentTheme = Theme.of(context).brightness;
              if (currentTheme == Brightness.dark) {
                onThemeChanged!(ThemeMode.light);
              } else {
                onThemeChanged!(ThemeMode.dark);
              }
            }
          },
          child: const Text('Switch Theme (Example)'),
        ),
      )
    );
  }
}
