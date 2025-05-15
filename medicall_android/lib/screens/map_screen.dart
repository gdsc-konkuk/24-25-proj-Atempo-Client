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
import '../providers/location_provider.dart';
import 'settings_screen.dart';
import 'emt_license_verification_screen.dart';
import 'user_profile_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'chat_page.dart';
import '../services/hospital_service.dart';
import '../theme/app_theme.dart';

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
  
  late HospitalService _hospitalService;
  bool _sseSubscribed = false;
  
  // Reverse geocoding loading state
  bool _isReverseGeocodingLoading = false;
  
  // Image asset path
  final String _pinAsset = 'assets/images/location_pin.png';  // Pin image asset path (modify with actual path if needed)

  String get _googleMapsApiKey => 'AIzaSyAw92wiRgypo3fVZ4-R5CbpB4x_Pcj1gwk';

  // Neutral initial position in global coordinate system (mid-Atlantic point)
  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 16.0,
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
      // Initialize hospital service
      _hospitalService = HospitalService();
      
      if (kIsWeb) {
        _checkMapsApiLoaded();
      }

      try {
        await _getCurrentLocation();
        
        // SSE 초기화는 필요할 때만 하도록 코드 수정 (주석 처리)
        // Start SSE subscription when app starts
        // if (!_sseSubscribed) {
        //   print('[MapScreen] 🔄 Start SSE subscription');
        //   _subscribeToSSE();
        // }
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

  // SSE 구독 메소드 - MapScreen에서는 사용하지 않음
  // void _subscribeToSSE() {
  //   try {
  //     print('[MapScreen] 📡 Starting SSE subscription');
  //     _hospitalService.subscribeToHospitalUpdates().listen(
  //       (hospital) {
  //         print('[MapScreen] 📥 Hospital update received: ${hospital.name} (ID: ${hospital.id})');
  //       },
  //       onError: (error) {
  //         print('[MapScreen] ❌ SSE subscription error: $error');
  //       },
  //       onDone: () {
  //         print('[MapScreen] ✅ SSE subscription completed');
  //         _sseSubscribed = false;
  //       },
  //     );
  //     _sseSubscribed = true;
  //     print('[MapScreen] ✅ SSE subscription setup completed');
  //   } catch (e) {
  //     print('[MapScreen] ❌ SSE subscription setup error: $e');
  //     _sseSubscribed = false;
  //   }
  // }

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

      // Update location provider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.updateLocation(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isMapLoading = false;
          
          // No longer adding markers (using fixed center pin)
          _markers.clear();
        });
      }

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            19.0,
          ),
        );
      }
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

  // Get current center coordinates when camera stops moving
  Future<void> _onCameraIdle() async {
    if (_mapController == null) return;
    
    setState(() {
      _isReverseGeocodingLoading = true;
    });
    
    try {
      // Get visible region of the map
      LatLngBounds bounds = await _mapController!.getVisibleRegion();
      
      // Calculate center coordinates
      double centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
      double centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
      
      print('[MapScreen] 📍 Map center: lat=$centerLat, lng=$centerLng');
      
      // Update location provider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.updateLocation(centerLat, centerLng);
      
      setState(() {
        _isReverseGeocodingLoading = false;
      });
    } catch (e) {
      print('[MapScreen] ❌ Error getting center coordinates: $e');
      setState(() {
        _isReverseGeocodingLoading = false;
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
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          currentAddress: locationProvider.address,
          latitude: locationProvider.latitude,
          longitude: locationProvider.longitude,
        ),
      ),
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
              19.0,
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
    // SSE 연결 종료
    if (_sseSubscribed) {
      print('[MapScreen] 🔌 SSE 연결 종료');
      _hospitalService.closeSSEConnection();
      _sseSubscribed = false;
    }
    super.dispose();
  }

  // Get address from coordinates using Google Maps Geocoding API
  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      setState(() {
        _isReverseGeocodingLoading = true;
      });
      
      // Update location in provider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.updateLocation(latitude, longitude);
      
      // Try to get address via geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude, localeIdentifier: 'en_US');
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String fullAddress = _formatAddress(place);
        
        // Update address in provider
        locationProvider.updateAddress(fullAddress);
        
        setState(() {
          _currentAddress = fullAddress;
          _isReverseGeocodingLoading = false;
        });
      } else {
        setState(() {
          _currentAddress = "Address not found";
          _isReverseGeocodingLoading = false;
        });
        locationProvider.updateAddress("Address not found");
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _currentAddress = "Failed to get address";
        _isReverseGeocodingLoading = false;
      });
      
      // Update provider with error message
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.updateAddress("Failed to get address");
    }
  }
  
  // Format address from Placemark
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];
    Set<String> addedParts = {}; // Prevent duplicate parts
    
    void addIfNotDuplicate(String? part) {
      if (part != null && part.isNotEmpty && !addedParts.contains(part)) {
        addressParts.add(part);
        addedParts.add(part);
      }
    }
    
    // Add address parts in order
    addIfNotDuplicate(place.street);
    addIfNotDuplicate(place.subLocality);
    addIfNotDuplicate(place.locality);
    addIfNotDuplicate(place.subAdministrativeArea);
    addIfNotDuplicate(place.administrativeArea);
    addIfNotDuplicate(place.postalCode);
    addIfNotDuplicate(place.country);
    
    // Join all parts with commas
    return addressParts.join(', ');
  }

  // Build function
  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppTheme.buildAppBar(
        title: 'Medicall',
        leading: IconButton(
          icon: Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
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
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Checking authorization...',
                    style: AppTheme.textTheme.bodyLarge,
                  ),
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
                                    19.0,
                                  ),
                                );
                              }
                            },
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            markers: _markers,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            compassEnabled: true,
                            buildingsEnabled: true,
                            padding: EdgeInsets.only(bottom: 50),
                            onCameraIdle: _onCameraIdle,
                          ),
                          
                          // Fixed pin image at the center
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isReverseGeocodingLoading)
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                      child: Image.asset(
                                        _pinAsset,
                                        width: 48,
                                        height: 48,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Helper text at the top
                          Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Move the map to select your location",
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                          
                          if (_isMapLoading)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: AppTheme.primaryColor),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading map...',
                                    style: AppTheme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          
                          // Current location button (위치 변경: bottom을 80에서 16으로 변경)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton(
                              heroTag: "currentLocationButton",
                              onPressed: _getCurrentLocation,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.my_location,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          
                          // Address and coordinate information display panel (위치 변경: bottom을 150으로 수정)
                          Positioned(
                            bottom: 150,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on, color: AppTheme.primaryColor),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: locationProvider.isLoading
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Address verification in progress...',
                                              style: AppTheme.textTheme.bodyMedium,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          locationProvider.address,
                                          style: AppTheme.textTheme.bodyLarge,
                                        ),
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
                                style: AppTheme.textTheme.bodyLarge,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Current location: ${locationProvider.address}',
                                style: AppTheme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          currentAddress: locationProvider.address,
                          latitude: locationProvider.latitude,
                          longitude: locationProvider.longitude,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: Text(
                      'Enter patient condition',
                      style: AppTheme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}