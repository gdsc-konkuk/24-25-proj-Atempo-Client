import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class MapboxNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> hospital;
  
  const MapboxNavigationScreen({
    Key? key,
    required this.hospital,
  }) : super(key: key);

  @override
  _MapboxNavigationScreenState createState() => _MapboxNavigationScreenState();
}

class _MapboxNavigationScreenState extends State<MapboxNavigationScreen> {
  // Mapbox Navigation Controller
  MapBoxNavigationViewController? _controller;
  
  // Navigation information
  String _distance = '0 km';
  String _duration = '0 min';
  String _eta = 'Calculating...';
  double _distanceRemaining = 0;
  double _durationRemaining = 0;
  
  // Navigation state
  bool _isNavigating = false;
  bool _routeBuilt = false;
  bool _isInitialized = false;
  String _errorMessage = '';
  
  // Target destination from hospital data
  late WayPoint _destination;
  WayPoint? _origin;

  // Mapbox access token from .env file
  String? _mapboxAccessToken;

  // Navigation options
  late MapBoxOptions _options;

  @override
  void initState() {
    super.initState();
    _mapboxAccessToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    _initializeOptions();
    _initialize();
  }

  void _initializeOptions() {
    _options = MapBoxOptions(
      // Using direct style URLs instead of non-existent constants
      mapStyleUrlDay: "mapbox://styles/mapbox/navigation-day-v1",
      mapStyleUrlNight: "mapbox://styles/mapbox/navigation-night-v1",
      zoom: 15.0,
      tilt: 0.0,
      bearing: 0.0,
      enableRefresh: true,
      alternatives: true,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      units: VoiceUnits.metric,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      language: "ko",
      simulateRoute: false,
      isOptimized: true,
      allowsUTurnAtWayPoints: true,
      animateBuildRoute: true,
      longPressDestinationEnabled: false,
    );
  }

  Future<void> _initialize() async {
    // Load destination from hospital data
    double destLat = double.tryParse(widget.hospital['latitude']?.toString() ?? '0') ?? 0;
    double destLng = double.tryParse(widget.hospital['longitude']?.toString() ?? '0') ?? 0;
    
    // Fallback to sample coordinates if needed
    if (destLat == 0 || destLng == 0) {
      destLat = 37.5742;
      destLng = 126.9842;
    }
    
    _destination = WayPoint(
      name: widget.hospital['name'] ?? 'Hospital',
      latitude: destLat,
      longitude: destLng,
    );
    
    // Set initial values
    _distance = widget.hospital['distance'] ?? '0 km';
    _duration = widget.hospital['time'] ?? '0 min';
    
    // Calculate initial ETA
    final now = DateTime.now();
    final minutesInt = int.tryParse(_duration.split(' ')[0]) ?? 0;
    final arrivalTime = now.add(Duration(minutes: minutesInt));
    _eta = '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')} ${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';
    
    try {
      // Get user's current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      _origin = WayPoint(
        name: "Current Location",
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Location error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _startNavigation() async {
    if (_origin == null) {
      setState(() {
        _errorMessage = 'Unable to get current location';
      });
      return;
    }
    
    try {
      // Start the navigation
      // 1. 경로 먼저 생성
        await _controller?.buildRoute(
        wayPoints: [_origin!, _destination], // ✅ 올바른 메서드
    );

    // 2. 네비게이션 시작
    await _controller?.startNavigation();
      
      setState(() {
        _isNavigating = true;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Navigation error: ${e.toString()}';
      });
    }
  }

  Future _updateNavigationInfo() async {
    if (_controller == null) return;

    try {
      final distance = await _controller!.distanceRemaining;
      final duration = await _controller!.durationRemaining;

      if (!mounted) return;

      setState(() {
        _distanceRemaining = distance;
        _durationRemaining = duration;
        
        _distance = '${(distance / 1000).toStringAsFixed(1)} km';
        _duration = '${(duration / 60).ceil()} min';
        
        final eta = DateTime.now().add(Duration(seconds: duration.toInt()));
        _eta = '${eta.hour}:${eta.minute.toString().padLeft(2, '0')} ${eta.hour >= 12 ? 'PM' : 'AM'}';
      });
    } catch (e) {
      print("네비게이션 정보 업데이트 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Navigation',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFE93C4A),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Top navigation info bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Color(0xFFE93C4A),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.hospital['name'] ?? 'Hospital',
                        style: GoogleFonts.notoSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem(
                      icon: Icons.directions_car,
                      value: _distance,
                      label: 'Distance',
                    ),
                    _buildInfoItem(
                      icon: Icons.access_time,
                      value: _duration,
                      label: 'Duration',
                    ),
                    _buildInfoItem(
                      icon: Icons.watch_later_outlined,
                      value: _eta,
                      label: 'ETA',
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Mapbox navigation view
          Expanded(
            child: Stack(
              children: [
                MapBoxNavigationView(
                  options: _options,
                  onRouteEvent: _onRouteEvent,
                  onCreated: (MapBoxNavigationViewController controller) {
                    _controller = controller;
                    if (_isInitialized && !_isNavigating) {
                      _startNavigation();
                    }
                  },
                ),
                
                if (!_isInitialized)
                  Container(
                    color: Colors.white.withOpacity(0.7),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFFE93C4A)),
                          SizedBox(height: 16),
                          Text('Initializing navigation...'),
                        ],
                      ),
                    ),
                  ),
                  
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Color(0xFFE93C4A), size: 48),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _startNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE93C4A),
                          ),
                          child: Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Bottom navigation controls
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETA: $_eta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_duration} (${_distance})',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE93C4A),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('End Navigation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _onRouteEvent(RouteEvent event) {
    switch (event.eventType) {
      case MapBoxEvent.progress_change:
        _updateNavigationInfo();
        break;
        
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() => _routeBuilt = true);
        break;
        
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
          _errorMessage = '경로 생성 실패';
        });
        break;
        
      case MapBoxEvent.navigation_running:
        setState(() => _isNavigating = true);
        break;
        
      case MapBoxEvent.on_arrival:
        _showArrivalDialog();
        break;
        
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
        
      default:
        break;
    }
  }
  
  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('You have arrived!'),
          content: Text('You have reached ${widget.hospital['name'] ?? 'the hospital'}.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildInfoItem({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.notoSans(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _controller?.finishNavigation();
    super.dispose();
  }
}
