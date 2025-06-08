import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/features/dashboard/placeholder_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PlaceholderWidget renders correctly', (WidgetTester tester) async {
    // Build our widget and trigger a frame.
    await tester.pumpWidget(
      MaterialApp( // Removed const
        home: Scaffold(
          body: PlaceholderWidget(), // Removed const
        ),
      ),
    );

    // Verify that the PlaceholderWidget displays its text.
    expect(find.text('Placeholder Widget'), findsOneWidget);

    // Verify that the PlaceholderWidget displays an Icon.
    // We used Icons.widgets in the implementation.
    expect(find.byIcon(Icons.widgets), findsOneWidget);
  });
}
