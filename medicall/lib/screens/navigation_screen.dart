import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class NavigationScreen extends StatefulWidget {
  final Map<String, dynamic> hospital;
  
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
  
  // Simulated current location (would come from GPS in a real app)
  final LatLng _currentLocation = LatLng(37.5642, 126.9742); // Seoul City Hall as sample starting point
  
  // Simulated destination (would come from selected hospital data in a real app)
  late LatLng _destinationLocation;
  
  @override
  void initState() {
    super.initState();
    
    // Get a simulated destination location (in real app, this would be from hospital data)
    // For demonstration, we'll set it to a location near the starting point
    _destinationLocation = LatLng(_currentLocation.latitude + 0.01, _currentLocation.longitude + 0.01);
    
    // Set initial values based on the passed hospital data
    _distance = widget.hospital['distance'] ?? '0 km';
    _duration = widget.hospital['time'] ?? '0 min';
    
    // Calculate ETA (current time + duration)
    final now = DateTime.now();
    final arrivalTime = now.add(Duration(minutes: int.parse(_duration.split(' ')[0])));
    _eta = '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')} ${arrivalTime.hour >= 12 ? 'PM' : 'AM'}';
    
    // Initialize the navigation
    _initNavigation();
  }
  
  Future<void> _initNavigation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // In a real app, this would make an API call to get the route
      await Future.delayed(Duration(seconds: 2)); // Simulate API delay
      
      // Set up markers
      _markers = {
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Current Location'),
        ),
        Marker(
          markerId: MarkerId('hospital'),
          position: _destinationLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.hospital['name'] ?? 'Hospital'),
        ),
      };
      
      // Set up polylines (simulating a route)
      _polylines = {
        Polyline(
          polylineId: PolylineId('route'),
          points: [
            _currentLocation,
            LatLng(_currentLocation.latitude + 0.005, _currentLocation.longitude + 0.002),
            LatLng(_currentLocation.latitude + 0.008, _currentLocation.longitude + 0.006),
            _destinationLocation,
          ],
          color: Colors.blue,
          width: 5,
        ),
      };
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load route: $e';
      });
    }
  }
  
  bool _isSupportedPlatform() {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
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
      body: _isSupportedPlatform()
        ? Column(
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
                              '${widget.hospital['distance']} ahead',
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
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Maps are only supported on iOS and Android devices',
                  style: TextStyle(fontSize: 16),
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
  
  // Helper method to get bounds that include all route points
  LatLngBounds _getBounds() {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    // Include all markers
    for (final marker in _markers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }
    
    // Include all polyline points
    for (final polyline in _polylines) {
      for (final point in polyline.points) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  
  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;
}
