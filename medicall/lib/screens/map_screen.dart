import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/patient_info_widget.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _currentAddress = "Finding your location...";
  Position? _currentPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isMapLoading = true;
  String _mapLoadError = "";

  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _checkMapsApiLoaded();
    _getCurrentLocation();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;

        _markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(title: 'Your Location'),
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

      await _getAddressFromLatLng(position);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress = "${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.administrativeArea}";
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _checkMapsApiLoaded() {
    if (kIsWeb) {
      Future.delayed(Duration(seconds: 3), () {
        try {
          final bool? mapsLoaded = true;

          if (mapsLoaded != true) {
            setState(() {
              _mapLoadError = "Google Maps API 로드에 실패했습니다. 새로고침해 보세요.";
            });
          }
        } catch (e) {
          setState(() {
            _mapLoadError = "Maps API 초기화 오류: $e";
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
          initialChildSize: 0.9,
          minChildSize: 0.5,
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
    setState(() {
      _isMapLoading = false;
    });

    _mapController = controller;

    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        ),
      );
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
        title: Text('Medicall'),
        backgroundColor: const Color(0xFFD94B4B),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSupportedPlatform()
                ? Stack(
                    children: [
                      Material(
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          child: GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: _initialCameraPosition,
                            onMapCreated: _onMapCreated,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            markers: _markers,
                            zoomControlsEnabled: false,
                          ),
                        ),
                      ),
                      if (_isMapLoading)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: const Color(0xFFD94B4B)),
                              SizedBox(height: 16),
                              Text('지도를 불러오는 중...'),
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
                                  child: Text('다시 시도'),
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
                          SizedBox(height: 20),
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
                '채팅창',
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
