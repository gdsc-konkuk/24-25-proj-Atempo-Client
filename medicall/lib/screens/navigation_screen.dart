import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:medicall/screens/mapbox_navigation_screen.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'error_screen.dart';
import '../theme/app_theme.dart';
import '../models/hospital_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class NavigationScreen extends StatefulWidget {
  final Hospital hospital;
  
  // Constructor takes hospital data
  const NavigationScreen({
    Key? key,
    required this.hospital,
  }) : super(key: key);

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Navigation details
  String _distance = '';
  String _duration = '';
  String _eta = '';
  
  // User location (will be updated from LocationProvider)
  late LatLng _currentLocation;
  
  // Hospital destination location
  late LatLng _destinationLocation;
  
  // Google Maps API key
  final String _googleMapsApiKey = 'AIzaSyAw92wiRgypo3fVZ4-R5CbpB4x_Pcj1gwk';
  
  // Custom marker icons
  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _hospitalLocationIcon;
  
  @override
  void initState() {
    super.initState();
    
    print("[NavigationScreen] Hospital: ${widget.hospital.id} - ${widget.hospital.name}");
    print("[NavigationScreen] Hospital coordinates: latitude=${widget.hospital.latitude}, longitude=${widget.hospital.longitude}");
    
    // Initialize custom markers
    _createCustomMarkers();
    
    // Initialize with default location (will be overridden by LocationProvider)
    _currentLocation = LatLng(37.5662, 126.9785); // Seoul City Hall as default
    
    // Get location from location provider (user's selected location)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      print("[NavigationScreen] User location: latitude=${locationProvider.latitude}, longitude=${locationProvider.longitude}");
      
      // Validate hospital coordinates
      if (!_validateHospitalCoordinates(widget.hospital)) {
        _navigateToErrorScreen("Cannot find hospital location.");
        return;
      }
      
      setState(() {
        _currentLocation = LatLng(locationProvider.latitude, locationProvider.longitude);
      });
      
      // After location is set, initialize navigation
      _initNavigation();
    });
    
    // Get hospital location data from widget
    double? hospitalLat;
    double? hospitalLng;
    
    // Type casting for latitude and longitude
    try {
      hospitalLat = widget.hospital.latitude;
      hospitalLng = widget.hospital.longitude;
      
      print("[NavigationScreen] Checking hospital coordinates: latitude=$hospitalLat, longitude=$hospitalLng");
      
      // If coordinates are still null or invalid, don't set a destination
      if (hospitalLat == null || hospitalLng == null) {
        print("[NavigationScreen] ❌ Hospital coordinates are null.");
        // Don't show error yet, wait for addPostFrameCallback to handle it
        return;
      }
      
      if (hospitalLat < -90 || hospitalLat > 90 || hospitalLng < -180 || hospitalLng > 180) {
        print("[NavigationScreen] ❌ Hospital coordinates are out of valid range: latitude=$hospitalLat, longitude=$hospitalLng");
        // Don't show error yet, wait for addPostFrameCallback to handle it
        return;
      }
      
      // Set destination location
      _destinationLocation = LatLng(hospitalLat, hospitalLng);
      print("[NavigationScreen] ✅ Destination coordinates set: $_destinationLocation");
    } catch (e) {
      print("[NavigationScreen] Error converting hospital coordinates: $e");
      // Don't show error yet, wait for addPostFrameCallback to handle it
      return;
    }
    
    // Set initial values based on the passed hospital data
    _distance = widget.hospital.distance != null ? '${widget.hospital.distance!.toStringAsFixed(1)} km' : '0 km';
    _duration = widget.hospital.travelTime != null ? '${widget.hospital.travelTime} min' : '0 min';
    if (!_duration.contains('min')) {
      _duration += ' min';
    }
    
    // Calculate ETA (current time + duration)
    final now = DateTime.now();
    int durationMinutes = 0;
    try {
      durationMinutes = int.parse(_duration.split(' ')[0]);
    } catch (e) {
      durationMinutes = 10; // Default 10 minutes
    }
    final arrivalTime = now.add(Duration(minutes: durationMinutes));
    _eta = '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')} ${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';
    
    // Don't initialize navigation yet - wait for location provider
  }
  
  // Create custom marker icons
  Future<void> _createCustomMarkers() async {
    try {
      // Create custom user location marker
      final Uint8List userMarkerIcon = await _getBytesFromAsset('assets/images/location_pin.png', 120);
      _userLocationIcon = BitmapDescriptor.fromBytes(userMarkerIcon);
      
      // Create hospital location marker (using default red for now)
      _hospitalLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      
      print("[NavigationScreen] ✅ Custom markers created successfully");
    } catch (e) {
      print("[NavigationScreen] ❌ Error creating custom markers: $e");
      // Fallback to default markers
      _userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _hospitalLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }
  
  // Convert asset image to Uint8List
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
  
  Future<void> _initNavigation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Refresh the current location from the provider
      if (!mounted) return;
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      _currentLocation = LatLng(locationProvider.latitude, locationProvider.longitude);
      
      // Set up markers
      _markers = {
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation,
          icon: _userLocationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Current Location'),
        ),
        Marker(
          markerId: MarkerId('hospital'),
          position: _destinationLocation,
          icon: _hospitalLocationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.hospital.name),
        ),
      };
      
      // Call Google Directions API to get the route
      await _getDirectionsFromGoogleAPI();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load route: $e';
      });
      print("[NavigationScreen] ❌ Error initializing navigation: $e");
    }
  }
  
  // Get directions from Google Directions API
  Future<void> _getDirectionsFromGoogleAPI() async {
    try {
      final origin = "${_currentLocation.latitude},${_currentLocation.longitude}";
      final destination = "${_destinationLocation.latitude},${_destinationLocation.longitude}";
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$origin&'
        'destination=$destination&'
        'mode=driving&'
        'key=$_googleMapsApiKey'
      );
      
      print("[NavigationScreen] 🔄 Requesting directions from Google API: $url");
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          // Extract route points
          final points = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
          
          // Extract distance and duration
          final legs = data['routes'][0]['legs'][0];
          final distance = legs['distance']['text'];
          final duration = legs['duration']['text'];
          
          // Update UI with route info
          setState(() {
            _distance = distance;
            _duration = duration;
            
            // Update ETA based on duration
            final durationInMinutes = legs['duration']['value'] ~/ 60;
            final now = DateTime.now();
            final arrivalTime = now.add(Duration(minutes: durationInMinutes));
            _eta = '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')} ${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';
            
            // Create polyline from points
            _polylines = {
              Polyline(
                polylineId: PolylineId('route'),
                points: points,
                color: AppTheme.primaryColor,
                width: 5,
              ),
            };
          });
          
          print("[NavigationScreen] ✅ Route fetched successfully: $_distance, $_duration");
        } else {
          print("[NavigationScreen] ⚠️ Directions API returned non-OK status: ${data['status']}");
          
          // 오류 유형에 따른 핸들링
          if (data['status'] == 'ZERO_RESULTS') {
            // 경로를 찾을 수 없는 경우: 직선 경로로 fallback
            _createDirectLineRoute();
            
            // 사용자에게 피드백
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not find a driving route. Showing direct line.'),
                  duration: Duration(seconds: 4),
                )
              );
            }
          } else {
            // 다른 API 오류: 일반 fallback 라우트 생성
            _createFallbackRoute();
            throw Exception("Directions API error: ${data['status']}");
          }
        }
      } else {
        print("[NavigationScreen] ❌ HTTP error: ${response.statusCode}");
        _createFallbackRoute();
        throw Exception("Failed to fetch directions: ${response.statusCode}");
      }
    } catch (e) {
      print("[NavigationScreen] ❌ Error getting directions: $e");
      // Fallback to a simulated route if the API call fails
      _createFallbackRoute();
      
      // 오류 메시지 설정 (반드시 setState 내에서 해야 함)
      setState(() {
        _errorMessage = 'Failed to load route: $e';
      });
    }
  }
  
  // 직선 경로 생성 (ZERO_RESULTS 오류 발생 시)
  void _createDirectLineRoute() {
    print("[NavigationScreen] 🔄 Creating direct line route");
    
    // 출발지와 목적지를 직선으로 연결
    List<LatLng> directPoints = [
      _currentLocation,
      _destinationLocation
    ];
    
    // 가상의 거리와 시간 계산
    double distanceKm = _calculateApproximateDistance(_currentLocation, _destinationLocation);
    int estimatedMinutes = (distanceKm * 2).round(); // 대략 km당 2분으로 가정
    
    // UI 업데이트
    setState(() {
      _distance = '${distanceKm.toStringAsFixed(1)} km';
      _duration = '$estimatedMinutes min';
      
      // ETA 업데이트
      final now = DateTime.now();
      final arrivalTime = now.add(Duration(minutes: estimatedMinutes));
      _eta = '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')} ${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';
      
      // 직선 경로 설정
      _polylines = {
        Polyline(
          polylineId: PolylineId('direct_route'),
          points: directPoints,
          color: Colors.red,
          width: 5,
          patterns: [
            PatternItem.dash(20), 
            PatternItem.gap(10),
          ], // 점선으로 표시하여 실제 경로가 아님을 나타냄
        ),
      };
      
      // 오류 메시지 업데이트
      _errorMessage = '';
    });
    
    print("[NavigationScreen] ✅ Created direct line route: $_distance, $_duration");
  }
  
  // 두 좌표 간 대략적인 거리 계산 (km)
  double _calculateApproximateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // 지구 반경 (km)
    
    // 라디안으로 변환
    double startLatRad = start.latitude * math.pi / 180;
    double startLngRad = start.longitude * math.pi / 180;
    double endLatRad = end.latitude * math.pi / 180;
    double endLngRad = end.longitude * math.pi / 180;
    
    // 위도와 경도의 차이
    double latDiff = endLatRad - startLatRad;
    double lngDiff = endLngRad - startLngRad;
    
    // Haversine 공식
    double a = math.sin(latDiff/2) * math.sin(latDiff/2) +
               math.cos(startLatRad) * math.cos(endLatRad) *
               math.sin(lngDiff/2) * math.sin(lngDiff/2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    double distance = earthRadius * c;
    
    return distance;
  }
  
  // Create a fallback route if the API call fails
  void _createFallbackRoute() {
    print("[NavigationScreen] ⚠️ Using fallback route generation");
    List<LatLng> routePoints = _generateRealisticRoute(_currentLocation, _destinationLocation);
    
    // Calculate approximate distance and duration
    double totalDistance = 0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistance += _calculateApproximateDistance(routePoints[i], routePoints[i + 1]);
    }
    
    // Assume average speed of 30 km/h for urban areas
    int estimatedMinutes = (totalDistance / 30 * 60).round();
    
    setState(() {
      _distance = '${totalDistance.toStringAsFixed(1)} km';
      _duration = '$estimatedMinutes min';
      
      // Update ETA
      final now = DateTime.now();
      final arrivalTime = now.add(Duration(minutes: estimatedMinutes));
      _eta = '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')} ${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';
      
      _polylines = {
        Polyline(
          polylineId: PolylineId('route'),
          points: routePoints,
          color: AppTheme.primaryColor,
          width: 5,
        ),
      };
      
      // Clear error message
      _errorMessage = '';
    });
    
    print("[NavigationScreen] ✅ Created fallback route: $_distance, $_duration");
  }
  
  // Decode polyline points from Google Directions API
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    
    while (index < len) {
      int b, shift = 0, result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      
      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      
      double latitude = lat / 1e5;
      double longitude = lng / 1e5;
      
      points.add(LatLng(latitude, longitude));
    }
    
    return points;
  }
  
  // Generate a more realistic route with waypoints following roads (fallback method)
  List<LatLng> _generateRealisticRoute(LatLng start, LatLng end) {
    List<LatLng> points = [];
    
    // Start point
    points.add(start);
    
    // Calculate the direct distance and angle
    double dx = end.longitude - start.longitude;
    double dy = end.latitude - start.latitude;
    double distance = math.sqrt(dx * dx + dy * dy);
    double angle = math.atan2(dy, dx);
    
    // Distance and angle perturbations to simulate road turns
    math.Random random = math.Random(42); // Fixed seed for consistent results
    
    // Calculate number of points based on distance
    int numPoints = math.max(5, (distance * 2000.0).round());
    
    // Generate points with random offsets to simulate a road-like path
    double prevAngle = angle;
    LatLng prevPoint = start;
    
    for (int i = 1; i < numPoints; i++) {
      double t = i / (numPoints - 1.0);
      
      // Perturb the angle slightly to create a curved path
      double angleOffset = (random.nextDouble() - 0.5) * 0.5; // Small random angle offset
      prevAngle = prevAngle * 0.8 + (angle + angleOffset) * 0.2; // Smooth the angle changes
      
      // Create a slight zigzag effect for roads
      double zigzagOffset = (random.nextDouble() - 0.5) * 0.001 * (1.0 - t);
      
      // Interpolate points with the perturbed angle and zigzag
      double lat = start.latitude + t * dy + math.sin(prevAngle + 1.57) * zigzagOffset;
      double lng = start.longitude + t * dx + math.cos(prevAngle + 1.57) * zigzagOffset;
      
      LatLng newPoint = LatLng(lat, lng);
      
      // Only add the point if it's sufficiently far from the previous one
      double ptDistance = _haversineDistance(prevPoint, newPoint);
      if (ptDistance > 0.0002) { // About 20-30 meters
        points.add(newPoint);
        prevPoint = newPoint;
      }
    }
    
    // End point
    points.add(end);
    
    return points;
  }
  
  // Calculate haversine distance between two points (in degrees)
  double _haversineDistance(LatLng start, LatLng end) {
    double lat1 = start.latitude;
    double lon1 = start.longitude;
    double lat2 = end.latitude;
    double lon2 = end.longitude;
    
    double dLat = (lat2 - lat1) * math.pi / 180.0;
    double dLon = (lon2 - lon1) * math.pi / 180.0;
    
    double a = math.pow(math.sin(dLat / 2.0), 2.0) + 
               math.cos(lat1 * math.pi / 180.0) * 
               math.cos(lat2 * math.pi / 180.0) * 
               math.pow(math.sin(dLon / 2.0), 2.0);
    
    return 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
  }
  
  void _startMapboxNavigation() {
    try {
      print("Starting Mapbox Navigation...");
      
      // Print hospital info
      print("Hospital info: id=${widget.hospital.id}, name=${widget.hospital.name}");
      print("Hospital coordinates: latitude=${widget.hospital.latitude}, longitude=${widget.hospital.longitude}");
      
      // Get location provider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      print("User coordinates from provider: latitude=${locationProvider.latitude}, longitude=${locationProvider.longitude}");
      
        // 병원 객체 직접 사용 (toJson 메서드로 변환하지 않음)
        // 병원 좌표 확인
      if (widget.hospital.latitude == null || widget.hospital.longitude == null) {
        print("❌ Hospital coordinates are null!");
        _navigateToErrorScreen("Cannot find hospital location.");
        return;
      }
      
      // 병원과 사용자 위치 정보를 포함하는 데이터 생성
      Map<String, dynamic> navigationData = {
        'id': widget.hospital.id,
        'name': widget.hospital.name,
        'address': widget.hospital.address,
        'latitude': widget.hospital.latitude,
        'longitude': widget.hospital.longitude,
        'phoneNumber': widget.hospital.phoneNumber,
        'user_latitude': locationProvider.latitude,
        'user_longitude': locationProvider.longitude,
        'user_address': locationProvider.address,
      };
      
      print("✅ Navigation data prepared: $navigationData");
      print("Hospital location: ${navigationData['latitude']}, ${navigationData['longitude']}");
      print("User location: ${navigationData['user_latitude']}, ${navigationData['user_longitude']}");
      
      // Display confirmation dialog before starting navigation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Start Navigation'),
          content: Text('Would you like to start navigation to ${widget.hospital.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapboxNavigationScreen(hospital: navigationData),
                  ),
                ).then((value) {
                  print("Navigation screen returned with: $value");
                }).catchError((error) {
                  print("Navigation screen error: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Unable to start navigation: $error"))
                  );
                });
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      print("Error starting navigation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to start navigation: $e"))
      );
    }
  }
  
  Future<LatLng> _getCurrentUserLocation() async {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    
    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    // Return coordinates
    return LatLng(position.latitude, position.longitude);
  }
  
  bool _isSupportedPlatform() {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  LatLngBounds _getBounds() {
    // Initial values
    double minLat = 90.0;  // Latitude range is -90 to 90
    double maxLat = -90.0;
    double minLng = 180.0; // Longitude range is -180 to 180
    double maxLng = -180.0;
    
    bool hasPoints = false;
    
    // Include all markers
    for (final marker in _markers) {
      hasPoints = true;
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }
    
    // Include all polyline points
    for (final polyline in _polylines) {
      for (final point in polyline.points) {
        hasPoints = true;
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }
    }
    
    // If no points or calculated bounds are invalid, use default values
    if (!hasPoints || minLat > maxLat || minLng > maxLng) {
      // Use a small range around Seoul center as default
      return LatLngBounds(
        southwest: LatLng(37.5642 - 0.01, 126.9742 - 0.01),
        northeast: LatLng(37.5642 + 0.01, 126.9742 + 0.01),
      );
    }
    
    // Add some margin if the latitude/longitude difference is too small
    if (maxLat - minLat < 0.001) {
      maxLat += 0.001;
      minLat -= 0.001;
    }
    
    if (maxLng - minLng < 0.001) {
      maxLng += 0.001;
      minLng -= 0.001;
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  
  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
  
  // Validate that hospital has valid coordinates
  bool _validateHospitalCoordinates(Hospital hospital) {
    // Check if the hospital has valid coordinates
    if (hospital.latitude == null || hospital.longitude == null) {
      return false;
    }
    
    // Check if coordinates are in valid range
    if (hospital.latitude! < -90 || hospital.latitude! > 90 ||
        hospital.longitude! < -180 || hospital.longitude! > 180) {
      return false;
    }
    
    return true;
  }
  
  // Navigate to error screen
  void _navigateToErrorScreen(String message) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ErrorScreen(
          errorMessage: message,
          backButtonText: 'Go Back',
          onRetry: () => Navigator.pop(context),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.buildAppBar(
        title: 'Navigation',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isSupportedPlatform()
        ? Column(
            children: [
              // Top navigation info bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppTheme.primaryColor,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.hospital.name,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
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
              // Map with route
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation,
                        zoom: 14,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (controller) {
                        setState(() {
                          _mapController = controller;
                        });
                        
                        // Adjust camera to show the entire route
                        Future.delayed(Duration(milliseconds: 500), () {
                          if (_mapController != null) {
                            LatLngBounds bounds = _getBounds();
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngBounds(bounds, 50),
                            );
                          }
                        });
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.white.withOpacity(0.7),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Color(0xFFE93C4A)),
                              SizedBox(height: 16),
                              Text('Calculating route...'),
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
                              onPressed: _initNavigation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE93C4A),
                              ),
                              child: Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    // Directional arrow for next turn (simulated)
                    Positioned(
                      left: 20,
                      bottom: 100,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              size: 32,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${widget.hospital.distance?.toStringAsFixed(1)} km ahead',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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
                          style: AppTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${_duration} (${_distance})',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _startMapboxNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        textStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Start Navigation'),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Map is supported on iOS and Android devices only',
                  style: AppTheme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
