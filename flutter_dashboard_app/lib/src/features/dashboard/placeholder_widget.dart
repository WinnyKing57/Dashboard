import 'package:flutter/material.dart';

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Container(
        height: 150, // Fixed height for now
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.widgets, size: 40.0, color: Colors.blueAccent),
              SizedBox(height: 8.0),
              Text(
                'Placeholder Widget',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
