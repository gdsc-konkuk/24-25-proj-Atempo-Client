import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/patient_info_widget.dart';
import 'emergency_room_list_screen.dart'; // Keep this import for the navigation function

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

  String get _googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // 글로벌 좌표계에서 중립적인 초기 위치 (대서양 중간 지점)
  // 실제로는 사용자의 위치를 얻자마자 이 위치로 카메라가 이동하지 않음
  static final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 2.0, // 글로벌 뷰로 시작
  );

  @override
  void initState() {
    super.initState();
    // 비동기 초기화를 안전하게 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeInitialize();
    });
  }

  // 안전한 초기화 메소드
  Future<void> _safeInitialize() async {
    try {
      if (kIsWeb) {
        _checkMapsApiLoaded();
      }

      // 위치 서비스 초기화를 시도하되 오류가 발생해도 앱이 계속 실행되도록 함
      try {
        await _getCurrentLocation();
      } catch (e) {
        debugPrint('위치 서비스 초기화 오류: $e');
        // 오류가 발생해도 앱이 계속 실행될 수 있게 함
        if (mounted) {
          setState(() {
            _isMapLoading = false;
            _currentAddress = "위치를 가져올 수 없습니다.";
          });
        }
      }
    } catch (e) {
      debugPrint('초기화 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _mapLoadError = "초기화 중 오류가 발생했습니다: $e";
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
              content: Text('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.')));
        }
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.')));
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('위치 권한 확인 중 오류: $e');
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();

      if (!hasPermission) {
        setState(() {
          _isMapLoading = false;
          _currentAddress = "위치 권한이 없습니다. 설정에서 위치 권한을 허용해주세요.";
        });
        return;
      }

      debugPrint('위치 권한 획득 완료, 현재 위치 가져오는 중...');
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      debugPrint('위치 수신 성공: $position');
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isMapLoading = false;

          _markers.clear(); // 기존 마커 제거
          _markers.add(
            Marker(
              markerId: MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: InfoWindow(title: '현재 위치'),
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
      debugPrint('위치 가져오기 오류: $e');
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _currentAddress = "위치를 가져오는 데 실패했습니다. 네트워크 연결을 확인하세요.";
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      // 디버깅을 위한 로그 추가
      debugPrint('위치 정보: 위도 ${position.latitude}, 경도 ${position.longitude}');
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
          localeIdentifier: 'ko_KR'); // 한국어 로케일 명시적 지정

      Placemark place = placemarks[0];
      debugPrint('받아온 위치 정보: $place');

      // 한국 주소 형식에 맞게 처리
      String address = "";
      if (place.country == 'South Korea' || place.country == '대한민국') {
        // 한국식 주소 형식
        address = "${place.administrativeArea ?? ''} ${place.locality ?? ''} ${place.subLocality ?? ''} ${place.thoroughfare ?? ''} ${place.subThoroughfare ?? ''}";
      } else {
        // 기본 주소 형식
        address = "${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.administrativeArea}";
      }
      
      // 공백 정리
      address = address.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      setState(() {
        _currentAddress = address;
      });
    } catch (e) {
      debugPrint('주소 변환 오류: $e');
      // 오류 발생시 위도/경도만 표시
      setState(() {
        _currentAddress = "위도: ${position.latitude}, 경도: ${position.longitude}";
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
          initialChildSize: 0.6, // Changed from 0.9 to 0.6 (60% of screen height)
          minChildSize: 0.4, // Changed from 0.5 to 0.4 (40% of screen height minimum)
          maxChildSize: 0.95, // Keep this the same (95% maximum)
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
      debugPrint('지도 컨트롤러 초기화 오류: $e');
    }
  }

  bool _isSupportedPlatform() {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  void navigateToEmergencyRoomList() async {
    // In the future, you might fetch data from server here
    // For example:
    // final emergencyRooms = await apiService.fetchNearbyEmergencyRooms(_currentPosition);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EmergencyRoomListScreen()),
      );
    }
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 해제
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _isSupportedPlatform()
                ? Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _initialCameraPosition,
                        onMapCreated: (GoogleMapController controller) {
                          // 로그 추가
                          print("지도가 생성되었습니다!");
                          setState(() {
                            _mapController = controller;
                            _isMapLoading = false;
                          });
                          
                          // 지도가 생성되자마자 현재 위치가 있으면 그 위치로 이동
                          // 이를 통해 초기 위치(0,0)에서 사용자 위치로 바로 이동함
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
                        myLocationButtonEnabled: false, // 내장 버튼 비활성화
                        markers: _markers,
                        zoomControlsEnabled: false,
                        compassEnabled: true,
                        buildingsEnabled: true, // 건물 표시 활성화
                        padding: EdgeInsets.only(bottom: 50), // 하단 패딩 추가
                        onTap: (_) {}, // 빈 탭 핸들러 추가 (일부 디바이스에서 맵 활성화에 도움)
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
