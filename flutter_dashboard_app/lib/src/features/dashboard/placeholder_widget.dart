import 'package:flutter/material.dart';

class PlaceholderWidget extends StatelessWidget {
  // Removed 'const' from constructor
  PlaceholderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Container(
        height: 150, // As per previous implementation
        alignment: Alignment.center, // Use alignment for Center effect on Container
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.widgets, size: 40.0, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8.0), // const can be used here
            Text(
              'Placeholder Widget',
              // Using Theme.of(context) here is why constructor cannot be const
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center, // Added for better text centering if it wraps
            ),
          ],
        ),
      ),
    );
  }
}
