import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/library.dart';

class NavigationExample extends StatefulWidget {
  @override
  _NavigationExampleState createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  late MapBoxNavigation _directions;
  late MapBoxOptions _options;

  @override
  void initState() {
    super.initState();
    _directions = MapBoxNavigation(onRouteEvent: _onRouteEvent);
    _options = MapBoxOptions(
      initialLatitude: 37.7749,
      initialLongitude: -122.4194,
      zoom: 15.0,
      tilt: 0.0,
      bearing: 0.0,
      enableRefresh: false,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: false,
      language: "en",
    );
  }

  void _onRouteEvent(e) {
    // 이벤트 처리 로직
  }

  void _startNavigation() async {
    var wayPoints = <WayPoint>[];
    wayPoints.add(WayPoint(name: "Start", latitude: 37.7749, longitude: -122.4194));
    wayPoints.add(WayPoint(name: "Destination", latitude: 37.7849, longitude: -122.4094));

    await _directions.startNavigation(
      wayPoints: wayPoints,
      options: _options,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mapbox Navigation')),
      body: Center(
        child: ElevatedButton(
          onPressed: _startNavigation,
          child: Text('Start Navigation'),
        ),
      ),
    );
  }
}
