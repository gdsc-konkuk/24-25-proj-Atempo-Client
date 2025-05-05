import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

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
  
  // Mapbox 접근 토큰 (환경 변수에서 가져옴)
  String? _mapboxPublicToken;
  
  // 네비게이션 옵션
  late MapBoxOptions _options;
  
  // 출발지 및 목적지 좌표
  WayPoint? _origin;
  late WayPoint _destination;

  @override
  void initState() {
    super.initState();
    print("MapboxNavigationScreen 초기화 중...");
    _mapboxPublicToken = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    print("Mapbox 토큰: $_mapboxPublicToken");
    
    if (_mapboxPublicToken == null || _mapboxPublicToken!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Mapbox 토큰이 설정되지 않았습니다. .env 파일을 확인하세요.";
      });
      return;
    }
    
    // 목적지 설정
    double destinationLat = 0.0;
    double destinationLng = 0.0;
    
    try {
      // 병원 데이터에서 목적지 좌표 가져오기
      destinationLat = double.parse(widget.hospital['latitude'].toString());
      destinationLng = double.parse(widget.hospital['longitude'].toString());
      
      print("목적지 좌표: $destinationLat, $destinationLng");
      
      _destination = WayPoint(
        name: widget.hospital['name'] ?? "목적지",
        latitude: destinationLat,
        longitude: destinationLng,
      );
      
      _initNavigationOptions();
    } catch (e) {
      print("좌표 변환 오류: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "좌표 정보를 처리할 수 없습니다: $e";
      });
    }
  }
  
  void _initNavigationOptions() {
    // 네비게이션 옵션 설정
    _options = MapBoxOptions(
      // MapBoxNavigation.instance.initialize() 제거 - 컨트롤러를 통해 초기화할 예정
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
      simulateRoute: true,
      language: "ko",
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
      body: _isLoading
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
              child: Text('뒤로 가기'),
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
    return Stack(
      children: [
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '병원 위치로 네비게이션 시작 준비 완료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  '${widget.hospital['name']}',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '위치: ${_destination.latitude}, ${_destination.longitude}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _startEmbeddedNavigation,
                  child: Text('네비게이션 시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE93C4A),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_routeBuilt && _isNavigating)
          Container(
            color: Colors.white,
            child: MapBoxNavigationView(
              options: _options,
              onRouteEvent: _onRouteEvent,
              onCreated: _onNavigationViewCreated,
            ),
          ),
      ],
    );
  }
  
  Future<void> _startEmbeddedNavigation() async {
    try {
      print("네비게이션 시작 중...");
      setState(() {
        _routeBuilt = true;
        _isNavigating = true;
      });
    } catch (e) {
      print("네비게이션 시작 오류: $e");
      setState(() {
        _errorMessage = "네비게이션을 시작할 수 없습니다: $e";
      });
    }
  }
  
  void _onNavigationViewCreated(MapBoxNavigationViewController controller) async {
    print("네비게이션 컨트롤러 생성됨");
    _controller = controller;
    
    try {
      // 컨트롤러를 통한 초기화 - 새로운 방식
      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
      });
      
      print("Mapbox Navigation initialized successfully");
      _buildRoute();
    } catch (e) {
      print("Mapbox Navigation initialization error: $e");
      setState(() {
        _errorMessage = "Mapbox SDK 초기화 실패: $e";
      });
    }
  }
  
  Future<void> _buildRoute() async {
    try {
      // 현재 위치 설정 (실제 앱에서는 Geolocator로 현재 위치 가져오기)
      _origin = WayPoint(
        name: "현재 위치",
        latitude: 37.5642,  // 서울시청 좌표
        longitude: 126.9742,
      );
      
      // 경로 생성
      print("경로 생성 중: ${_origin?.latitude}, ${_origin?.longitude} -> ${_destination.latitude}, ${_destination.longitude}");
      
      List<WayPoint> wayPoints = [];
      wayPoints.add(_origin!);
      wayPoints.add(_destination);
      
      if (_controller != null) {
        await _controller?.buildRoute(wayPoints: wayPoints);
        print("경로 생성 완료");
        
        // 네비게이션 시작
        await _controller?.startNavigation();
        print("네비게이션 시작됨");
      } else {
        print("네비게이션 컨트롤러가 초기화되지 않았습니다");
        setState(() {
          _errorMessage = "네비게이션 컨트롤러 초기화 오류";
        });
      }
    } catch (e) {
      print("경로 생성 오류: $e");
      setState(() {
        _routeBuilt = false;
        _isNavigating = false;
        _errorMessage = "경로를 생성할 수 없습니다: $e";
      });
    }
  }
  
  Future<void> _onRouteEvent(e) async {
    print("라우트 이벤트 발생: ${e.eventType}");
    
    switch (e.eventType) {
      case MapBoxEvent.route_building:
        print("경로 생성 중...");
        break;
      case MapBoxEvent.route_built:
        print("경로 생성 완료");
        setState(() => _routeBuilt = true);
        break;
      case MapBoxEvent.route_build_failed:
        print("경로 생성 실패");
        setState(() {
          _routeBuilt = false;
          _errorMessage = "경로를 생성할 수 없습니다";
        });
        break;
      case MapBoxEvent.navigation_running:
        print("네비게이션 진행 중");
        setState(() => _isNavigating = true);
        break;
      case MapBoxEvent.on_arrival:
        print("목적지 도착");
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        print("네비게이션 종료");
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
