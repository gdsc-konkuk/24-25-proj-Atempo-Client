import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/patient_info_widget.dart';
import 'emergency_room_list_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';
import 'emt_license_verification_screen.dart';
import 'user_profile_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _currentAddress = "Finding your location...";
  Position? _currentPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _isMapLoading = true;
  String _mapLoadError = "";
  bool _isCheckingAuth = true;

  String get _googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Neutral initial position in global coordinate system (mid-Atlantic point)
  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 2.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAuthorization();
    });
  }

  // User authorization check
  Future<void> _checkUserAuthorization() async {
    try {
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      
      print('MapScreen - Token check: Access token ${accessToken != null ? "present" : "missing"}, Refresh token ${refreshToken != null ? "present" : "missing"}');
      
      if (accessToken == null || accessToken.isEmpty) {
        print('MapScreen - No access token, redirecting to EMT screen');
        _redirectToLicenseVerification('Login required');
        return;
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Try to load user info, but continue even if it fails
      try {
        await authProvider.loadCurrentUser();
        final user = authProvider.currentUser;
        print('MapScreen - Current user: ${user?.name}, Role: ${user?.role}, Certification: ${user?.certificationType}');
      } catch (e) {
        print('MapScreen - Failed to load user info, continuing anyway: $e');
      }
      
      // Continue to map screen if token exists, regardless of user info
      setState(() {
        _isCheckingAuth = false;
      });
      _safeInitialize();
      
    } catch (e) {
      print('MapScreen - Error checking authorization: $e');
      
      // Continue if token exists, even with errors
      final storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      if (accessToken != null && accessToken.isNotEmpty) {
        print('MapScreen - Error occurred but token exists, continuing to display map');
        setState(() {
          _isCheckingAuth = false;
        });
        _safeInitialize();
      } else {
        _redirectToLicenseVerification('Error occurred while checking authorization');
      }
    }
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

  Future<void> _safeInitialize() async {
    try {
      if (kIsWeb) {
        _checkMapsApiLoaded();
      }

      try {
        await _getCurrentLocation();
      } catch (e) {
        debugPrint('Location services initialization error: $e');
        if (mounted) {
          setState(() {
            _isMapLoading = false;
            _currentAddress = "Unable to retrieve location.";
          });
        }
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _mapLoadError = "An error occurred during initialization: $e";
        });
      }
    }
  }

  Future<bool> _handleLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location services are disabled. Please enable them in settings.')));
        }
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location permission denied.')));
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permission permanently denied. Please enable it in settings.')));
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();

      if (!hasPermission) {
        setState(() {
          _isMapLoading = false;
          _currentAddress = "Location permission not granted. Please enable it in settings.";
        });
        return;
      }

      debugPrint('Location permission granted, fetching current location...');
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      debugPrint('Location received: $position');

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isMapLoading = false;

          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: InfoWindow(title: 'Current Location'),
            ),
          );

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude),
                16.0,
              ),
            );
          }
        });
      }

      await _getAddressFromLatLng(position);
    } catch (e) {
      debugPrint('Error retrieving location: $e');
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _currentAddress = "Failed to retrieve location. Please check your network connection.";
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      debugPrint('Location info: Latitude ${position.latitude}, Longitude ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
          localeIdentifier: 'ko_KR');

      Placemark place = placemarks[0];
      debugPrint('Received location info: $place');

      String address = "";
      if (place.country == 'South Korea' || place.country == '대한민국') {
        address = "${place.administrativeArea ?? ''} ${place.locality ?? ''} ${place.subLocality ?? ''} ${place.thoroughfare ?? ''} ${place.subThoroughfare ?? ''}";
      } else {
        address = "${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.administrativeArea}";
      }

      address = address.replaceAll(RegExp(r'\s+'), ' ').trim();

      setState(() {
        _currentAddress = address;
      });
    } catch (e) {
      debugPrint('Address conversion error: $e');
      setState(() {
        _currentAddress = "Lat: ${position.latitude}, Lng: ${position.longitude}";
      });
    }
  }

  void _checkMapsApiLoaded() {
    if (kIsWeb) {
      Future.delayed(Duration(seconds: 3), () {
        try {
          final bool? mapsLoaded = true;

          if (mapsLoaded != true) {
            setState(() {
              _mapLoadError = "Failed to load Google Maps API. Please refresh.";
            });
          }
        } catch (e) {
          setState(() {
            _mapLoadError = "Maps API initialization error: $e";
          });
        }
      });
    }
  }

  void _showChatBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: PatientInfoWidget(
                scrollController: scrollController,
                currentAddress: _currentAddress,
              ),
            );
          },
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _mapController = controller;
        });

        if (_currentPosition != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              16.0,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Map controller initialization error: $e');
    }
  }

  bool _isSupportedPlatform() {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  void navigateToEmergencyRoomList() async {
    if (mounted) {
      _showChatBottomSheet(context);
    }
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicall'),
        backgroundColor: const Color(0xFFD94B4B),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _isCheckingAuth
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: const Color(0xFFD94B4B)),
                  SizedBox(height: 16),
                  Text('Checking authorization...'),
                ],
              ),
            )
          : Column(
        children: [
          Expanded(
            child: _isSupportedPlatform()
                ? Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _initialCameraPosition,
                        onMapCreated: (GoogleMapController controller) {
                          print("Map created!");
                          setState(() {
                            _mapController = controller;
                            _isMapLoading = false;
                          });
                          if (_currentPosition != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                16.0,
                              ),
                            );
                          }
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: _markers,
                        zoomControlsEnabled: false,
                        compassEnabled: true,
                        buildingsEnabled: true,
                        padding: EdgeInsets.only(bottom: 50),
                        onTap: (_) {},
                      ),
                      if (_isMapLoading)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: const Color(0xFFD94B4B)),
                              SizedBox(height: 16),
                              Text('Loading map...'),
                            ],
                          ),
                        ),
                      if (_mapLoadError.isNotEmpty)
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(16),
                            margin: EdgeInsets.all(24),
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
                                Icon(Icons.error_outline, color: const Color(0xFFD94B4B), size: 48),
                                SizedBox(height: 16),
                                Text(
                                  _mapLoadError,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _mapLoadError = "";
                                      _isMapLoading = true;
                                    });
                                    _checkMapsApiLoaded();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD94B4B)),
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 100, color: Colors.grey),
                          SizedBox(height: 30),
                          Text(
                            'Maps are only supported on iOS and Android devices',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Current location: $_currentAddress',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          GestureDetector(
            onTap: () => _showChatBottomSheet(context),
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              child: Text(
                'Chat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSupportedPlatform() 
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFD94B4B),
              onPressed: _getCurrentLocation,
              child: Icon(Icons.my_location),
            )
          : null,
    );
  }
}