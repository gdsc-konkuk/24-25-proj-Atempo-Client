import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:medicall/screens/mapbox_navigation_screen.dart';

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
  
  void _startMapboxNavigation() {
    try {
      print("Starting Mapbox Navigation...");
      
      // 테스트를 위한 임시 병원 데이터 생성
      Map<String, dynamic> hospitalData = Map.from(widget.hospital);
      
      // 병원 데이터에 위도/경도가 없는 경우 임의의 값 추가 (서울대학교병원 위치)
      if (!hospitalData.containsKey('latitude') || !hospitalData.containsKey('longitude') || 
          hospitalData['latitude'] == null || hospitalData['longitude'] == null) {
        print("병원 위치 정보가 없어 임의의 값을 설정합니다.");
        hospitalData['latitude'] = 37.579617;  // 서울대학교병원 위도
        hospitalData['longitude'] = 126.998898;  // 서울대학교병원 경도
        
        // 필수 정보 추가
        if (hospitalData['name'] == null) {
          hospitalData['name'] = '서울대학교병원';
        }
        if (hospitalData['distance'] == null) {
          hospitalData['distance'] = '5.2 km';
        }
      }
      
      print("병원 데이터: $hospitalData");
      
      // 명시적으로 데이터 타입 변환 (문자열로 된 값도 숫자로 변환)
      try {
        if (hospitalData['latitude'] is String) {
          hospitalData['latitude'] = double.parse(hospitalData['latitude']);
        }
        if (hospitalData['longitude'] is String) {
          hospitalData['longitude'] = double.parse(hospitalData['longitude']);
        }
      } catch (e) {
        print("좌표 변환 오류: $e");
        hospitalData['latitude'] = 37.579617;
        hospitalData['longitude'] = 126.998898;
      }
      
      print("병원 위치: ${hospitalData['latitude']}, ${hospitalData['longitude']}");
      
      // 화면 전환 전 확인 대화상자 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('네비게이션 시작'),
          content: Text('${hospitalData['name']}(으)로 네비게이션을 시작하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(); // rootNavigator 사용
                // 확인 후 네비게이션 화면으로 전환 - pushReplacement로 변경
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapboxNavigationScreen(hospital: hospitalData),
                  ),
                ).then((value) {
                  print("Navigation screen returned with: $value");
                }).catchError((error) {
                  print("Navigation screen error: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("네비게이션을 시작할 수 없습니다: $error"))
                  );
                });
              },
              child: Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Navigation 시작 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("네비게이션을 시작할 수 없습니다: $e"))
      );
    }
  }
  
  Future<LatLng> _getCurrentUserLocation() async {
    // 위치 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다');
      }
    }
    
    // 현재 위치 가져오기
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    // 좌표로 반환
    return LatLng(position.latitude, position.longitude);
  }
  
  bool _isSupportedPlatform() {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  LatLngBounds _getBounds() {
    // 초기 값 설정
    double minLat = 90.0;  // 위도 범위는 -90 ~ 90
    double maxLat = -90.0;
    double minLng = 180.0; // 경도 범위는 -180 ~ 180
    double maxLng = -180.0;
    
    bool hasPoints = false;
    
    // Include all markers
    for (final marker in _markers) {
      hasPoints = true;
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }
    
    // Include all polyline points
    for (final polyline in _polylines) {
      for (final point in polyline.points) {
        hasPoints = true;
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }
    }
    
    // 포인트가 없거나 계산된 범위가 유효하지 않은 경우 기본값 사용
    if (!hasPoints || minLat > maxLat || minLng > maxLng) {
      // 서울 중심의 작은 범위를 기본값으로 사용
      return LatLngBounds(
        southwest: LatLng(37.5642 - 0.01, 126.9742 - 0.01),
        northeast: LatLng(37.5642 + 0.01, 126.9742 + 0.01),
      );
    }
    
    // 위도/경도의 차이가 너무 작은 경우 약간의 여유 공간을 추가
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
                      onPressed: _startMapboxNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE93C4A),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
}
