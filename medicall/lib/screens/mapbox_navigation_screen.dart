import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import 'emt_license_verification_screen.dart';
import '../services/hospital_service.dart';
import 'error_screen.dart';
import '../theme/app_theme.dart';

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
  WayPoint? _destination;

  @override
  void initState() {
    super.initState();
    print("Initializing MapboxNavigationScreen...");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAuthorization();
    });
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
    
    // Get location from location provider (user's selected location)
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    double startLat = locationProvider.latitude;
    double startLng = locationProvider.longitude;
    
    print("User location from provider: $startLat, $startLng");
    
    // Get hospital location
    double? hospitalLat;
    double? hospitalLng;
    String hospitalName = widget.hospital['name'] ?? "Hospital";
    
    try {
      // Type casting for hospital coordinates
      if (widget.hospital['latitude'] is String) {
        hospitalLat = double.parse(widget.hospital['latitude']);
      } else if (widget.hospital['latitude'] != null) {
        hospitalLat = widget.hospital['latitude'].toDouble();
      }
      
      if (widget.hospital['longitude'] is String) {
        hospitalLng = double.parse(widget.hospital['longitude']);
      } else if (widget.hospital['longitude'] != null) {
        hospitalLng = widget.hospital['longitude'].toDouble();
      }
      
      // Validate coordinates
      if (hospitalLat == null || hospitalLng == null) {
        _navigateToErrorScreen("Can't find location for ${hospitalName}");
        return;
      }
      
      // Validate coordinate ranges
      if (hospitalLat < -90 || hospitalLat > 90 || hospitalLng < -180 || hospitalLng > 180) {
        _navigateToErrorScreen("Invalid coordinates for ${hospitalName}");
        return;
      }
    } catch (e) {
      print("Error parsing hospital coordinates: $e");
      _navigateToErrorScreen("Error converting hospital coordinates: $e");
      return;
    }
    
    print("Hospital location: $hospitalLat, $hospitalLng");
    
    // Create origin and destination waypoints
    _origin = WayPoint(
      name: "Current Location",
      latitude: startLat,
      longitude: startLng,
    );
    
    _destination = WayPoint(
      name: hospitalName,
      latitude: hospitalLat,
      longitude: hospitalLng,
    );
    
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
      simulateRoute: false,
      language: "en",
    );
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Navigate to error screen
  void _navigateToErrorScreen(String errorMessage) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ErrorScreen(
            title: 'Can\'t start navigation',
            errorMessage: errorMessage,
            onRetry: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.buildAppBar(
        title: 'Hospital Navigation',
        leading: AppTheme.buildBackButton(context),
      ),
      body: _isCheckingAuth
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text('Checking authorization...', style: AppTheme.textTheme.bodyMedium),
                ],
              ),
            )
          : _isLoading
              ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
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
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 64),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: AppTheme.textTheme.bodyLarge,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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
    if (_controller == null) {
      print("❌ Route build failed: Controller is not initialized");
      return;
    }
    
    if (_origin == null) {
      print("❌ Route build failed: Origin WayPoint is null");
      setState(() {
        _errorMessage = "Unable to determine your current location";
      });
      return;
    }
    
    if (_destination == null) {
      print("❌ Route build failed: Destination WayPoint is null");
      setState(() {
        _errorMessage = "Unable to determine hospital location";
      });
      return;
    }
    
    print("Starting route building");
    print("Origin: ${_origin?.name} (${_origin?.latitude}, ${_origin?.longitude})");
    print("Destination: ${_destination?.name} (${_destination?.latitude}, ${_destination?.longitude})");
    
    try {
      List<WayPoint> wayPoints = [_origin!, _destination!];
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
      
      // Use the _origin and _destination that were already created in _initializeNavigation
      print("Using origin: ${_origin?.latitude}, ${_origin?.longitude}");
      print("Using destination: ${_destination?.latitude}, ${_destination?.longitude}");
      
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
    // When the screen is exited, end the navigation connection
    if (_controller != null && _isNavigating) {
      _controller!.finishNavigation();
    }
    _controller = null;
    super.dispose();
  }
}