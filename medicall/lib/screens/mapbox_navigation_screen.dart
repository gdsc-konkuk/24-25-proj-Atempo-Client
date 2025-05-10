import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'emt_license_verification_screen.dart';
import '../services/hospital_service.dart';

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
  
  // Navigation state
  bool _isNavigating = false;
  bool _routeBuilt = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  String _errorMessage = '';
  bool _isCheckingAuth = true;
  
  // Mapbox token (fetched from environment variable)
  String? _mapboxPublicToken;
  
  // Navigation options
  late MapBoxOptions _options;
  
  // Origin and destination coordinates
  WayPoint? _origin;
  late WayPoint _destination;

  @override
  void initState() {
    super.initState();
    print("Initializing MapboxNavigationScreen...");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAuthorization();
    });

    // Get starting and destination coordinates
    double? startLat = widget.hospital['user_latitude'];
    double? startLng = widget.hospital['user_longitude'];
    double? destLat = widget.hospital['latitude'];
    double? destLng = widget.hospital['longitude'];

    // Use default coordinates if not available
    startLat ??= 37.5662; // Default: Seoul City Hall
    startLng ??= 126.9785;
    destLat ??= 37.5765; // Default: Seoul National University Hospital
    destLng ??= 126.9773;

    // Set starting point and destination
    _origin = "${startLng},${startLat}";
    _destination = "${destLng},${destLat}";
  }
  
  // Check user authorization
  Future<void> _checkUserAuthorization() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadCurrentUser();
    
    final user = authProvider.currentUser;
    if (user == null) {
      _redirectToLicenseVerification('Login required.');
      return;
    }
    
    // Removed certification check, only verify that the user object exists
    setState(() {
      _isCheckingAuth = false;
    });
    _initializeNavigation();
  }
  
  void _redirectToLicenseVerification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red)
      );
      
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => EmtLicenseVerificationScreen()),
          );
        }
      });
    }
  }
  
  void _initializeNavigation() {
    _mapboxPublicToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    print("Mapbox token: $_mapboxPublicToken");
    
    if (_mapboxPublicToken == null || _mapboxPublicToken!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Mapbox token is not set. Please check the .env file.";
      });
      return;
    }
    
    // Set navigation options
    _options = MapBoxOptions(
      mapStyleUrlDay: "mapbox://styles/mapbox/navigation-day-v1",
      mapStyleUrlNight: "mapbox://styles/mapbox/navigation-night-v1",
      zoom: 15.0,
      tilt: 0.0,
      bearing: 0.0,
      enableRefresh: true,
      alternatives: true,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: true,
      language: "en",
    );
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapbox Navigation'),
        backgroundColor: Color(0xFFE93C4A),
      ),
      body: _isCheckingAuth
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE93C4A)),
                  SizedBox(height: 16),
                  Text('Checking authorization...'),
                ],
              ),
            )
          : _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? _buildErrorWidget()
                  : _buildNavigationWidget(),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE93C4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationWidget() {
    // Improved navigation widget - always display MapBoxNavigationView
    return Container(
      color: Colors.white,
      child: MapBoxNavigationView(
        options: _options,
        onRouteEvent: _onRouteEvent,
        onCreated: _onNavigationViewCreated,
      ),
    );
  }
  
  Future<void> _buildRoute() async {
    if (_controller == null || _origin == null) {
      print("❌ Route build failed: Controller or origin is missing");
      return;
    }
    
    print("Starting route building");
    print("Origin: ${_origin?.latitude}, ${_origin?.longitude}");
    print("Destination: ${_destination.latitude}, ${_destination.longitude}");
    
    List<WayPoint> wayPoints = [_origin!, _destination];
    
    try {
      await _controller!.buildRoute(wayPoints: wayPoints);
      print("✅ Route build complete");
      
      setState(() {
        _routeBuilt = true;
      });
    } catch (e) {
      print("❌ Route build failed: $e");
      setState(() {
        _errorMessage = "Unable to build route: $e";
      });
    }
  }
  
  Future<void> _startEmbeddedNavigation() async {
    try {
      print("Starting navigation...");
      setState(() {
        _routeBuilt = true;
        _isNavigating = true;
      });
      print("Navigation state updated: _routeBuilt = $_routeBuilt, _isNavigating = $_isNavigating");
    } catch (e) {
      print("Error starting navigation: $e");
      setState(() {
        _errorMessage = "Unable to start navigation: $e";
      });
    }
  }
  
  void _onNavigationViewCreated(MapBoxNavigationViewController controller) async {
    print("Navigation controller created");
    _controller = controller;
    
    try {
      await _controller!.initialize();
      print("✅ Controller initialization successful");
      
      setState(() {
        _isInitialized = true;
      });
      
      _origin = WayPoint(
        name: "Current Location",
        latitude: 37.5642,  // Sample starting point (replace with real location)
        longitude: 126.9742,
      );
      
      await _buildRoute();
      
      if (_routeBuilt) {
        await _controller!.startNavigation();
        print("✅ Navigation started");
        setState(() {
          _isNavigating = true;
        });
      }
    } catch (e) {
      print("❌ Mapbox Navigation initialization error: $e");
      setState(() {
        _errorMessage = "Navigation initialization failed: $e";
      });
    }
  }
  
  Future<void> _onRouteEvent(e) async {
    print("🔵 Route event occurred: ${e.eventType}");
    
    switch (e.eventType) {
      case MapBoxEvent.route_building:
        print("🔄 Building route...");
        break;
      case MapBoxEvent.route_built:
        print("✅ Route built successfully");
        setState(() => _routeBuilt = true);
        break;
      case MapBoxEvent.route_build_failed:
        print("❌ Route build failed");
        print("🚨 Failure details: ${e.data}");
        setState(() {
          _routeBuilt = false;
          _errorMessage = "Unable to build route: ${e.data}";
        });
        break;
      case MapBoxEvent.navigation_running:
        print("Navigation running");
        setState(() => _isNavigating = true);
        break;
      case MapBoxEvent.on_arrival:
        print("Arrived at destination");
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        print("Navigation finished");
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      default:
        break;
    }
  }
  
  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }
}