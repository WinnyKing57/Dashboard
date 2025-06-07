import 'package:flutter/material.dart';
import 'package:flutter_dashboard_app/src/features/webradio/webradio_screen.dart'; // To access GlobalRadioState and navigate
import 'package:flutter_dashboard_app/src/models/radio_station.dart'; // To use RadioStation type

class WebRadioDashboardWidget extends StatefulWidget {
  const WebRadioDashboardWidget({super.key});

  @override
  State<WebRadioDashboardWidget> createState() => _WebRadioDashboardWidgetState();
}

class _WebRadioDashboardWidgetState extends State<WebRadioDashboardWidget> {
  RadioStation? _currentStation;
  // No direct player state needed here for now, just observing current station

  Stream<RadioStation?>? _currentStationStream;

  @override
  void initState() {
    super.initState();
    _currentStation = GlobalRadioState.currentStation;
    _currentStationStream = GlobalRadioState.currentStationStream;
    _currentStationStream?.listen((station) {
      if (mounted) {
        setState(() {
          _currentStation = station;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Aligns children
          children: <Widget>[
            const Text(
              'Web Radio Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.radio,
                      size: 30.0,
                      color: _currentStation != null ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _currentStation?.name ?? 'No station playing',
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentStation != null)
                      Text(
                        _currentStation!.countryDisplay,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                child: const Text('Open Player'),
                onPressed: () {
                  // Navigate to the WebRadioScreen.
                  // This assumes BottomNavigationBar handles switching to the correct tab
                  // if WebRadioScreen is one of the main tabs.
                  // For now, let's find the index of WebRadioScreen in main.dart's _widgetOptions
                  // This is a bit of a hack. Proper navigation/state would be better.

                  // A simple direct navigation for now if not using tab indices:
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const WebRadioScreen()),
                  // );

                  // To switch tab, we'd typically call a method on the MainNavigationScreen's state.
                  // This requires a more global way to access that state or a different navigation pattern.
                  // For this task, we'll just print a message, as direct tab switching is complex from here.
                  print("Navigate to WebRadioScreen - implementation depends on main navigation setup.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigation to full Web Radio screen TBD.'))
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
