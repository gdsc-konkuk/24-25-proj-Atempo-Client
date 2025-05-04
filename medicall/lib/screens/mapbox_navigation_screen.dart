import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/library.dart';
import 'package:medicall/utils/mapbox_token_helper.dart';

class MapboxNavigationScreen extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final double? userLatitude;
  final double? userLongitude;

  const MapboxNavigationScreen({
    Key? key,
    required this.hospital,
    required this.userLatitude,
    required this.userLongitude,
  }) : super(key: key);

  @override
  _MapboxNavigationScreenState createState() => _MapboxNavigationScreenState();
}

class _MapboxNavigationScreenState extends State<MapboxNavigationScreen> {
  late MapBoxNavigation _directions;
  late MapBoxOptions _options;
  bool _isNavigating = false;
  String _navigationStatus = '';
  String _routeProgressRemaining = '';
  double _distanceRemaining = 0;
  double _durationRemaining = 0;
  bool _setupDialogShown = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize MapBox Navigation
    _directions = MapBoxNavigation(onRouteEvent: _onRouteEvent);
    
    _options = MapBoxOptions(
      initialLatitude: widget.userLatitude ?? 37.5642,
      initialLongitude: widget.userLongitude ?? 126.9742,
      zoom: 15.0,
      tilt: 0.0,
      bearing: 0.0,
      enableRefresh: false,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: false, // 테스트 시에만 true로 설정
      language: "ko",
    );
    
    // 화면이 준비되면 네비게이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNavigation();
    });
  }

  Future<void> _startNavigation() async {
    try {
      setState(() {
        _isNavigating = true;
        _navigationStatus = "경로 계산 중...";
      });
      
      // 경로 시작점 (사용자 위치)
      final startPoint = WayPoint(
        name: "현재 위치",
        latitude: widget.userLatitude ?? 37.5642,
        longitude: widget.userLongitude ?? 126.9742,
      );
      
      // 경로 도착점 (병원 위치)
      final double hospitalLat = widget.hospital['latitude'] != null 
          ? double.tryParse(widget.hospital['latitude'].toString()) ?? 37.5665
          : 37.5665;
      
      final double hospitalLng = widget.hospital['longitude'] != null 
          ? double.tryParse(widget.hospital['longitude'].toString()) ?? 126.9780
          : 126.9780;
          
      final destinationPoint = WayPoint(
        name: widget.hospital['name'] ?? "병원",
        latitude: hospitalLat,
        longitude: hospitalLng,
      );

      // 네비게이션 시작
      await _directions.startNavigation(
        wayPoints: [startPoint, destinationPoint],
        options: _options,
      );
      
    } catch (e) {
      print("Navigation error: $e");
      setState(() {
        _isNavigating = false;
        _isError = true;
        
        if (e.toString().contains("401") || e.toString().contains("Unauthorized")) {
          _navigationStatus = "인증 오류: 개발 환경 설정이 필요합니다";
          if (!_setupDialogShown) {
            _setupDialogShown = true;
            // 0.5초 후 설정 다이얼로그 표시
            Future.delayed(Duration(milliseconds: 500), () {
              MapboxTokenHelper.showNetrcSetupDialog(context);
            });
          }
        } else {
          _navigationStatus = "네비게이션 오류: $e";
        }
      });
    }
  }

  void _onRouteEvent(e) {
    if (!mounted) return;
    
    setState(() {
      _navigationStatus = "${e.eventType}";
      
      switch (e.eventType) {
        case MapBoxEvent.progress_change:
          var progressEvent = e.data as RouteProgressEvent;
          _distanceRemaining = progressEvent.distanceRemaining;
          _durationRemaining = progressEvent.durationRemaining;
          _routeProgressRemaining = "${(_distanceRemaining / 1000).toStringAsFixed(1)} km · ${(_durationRemaining / 60).toStringAsFixed(0)} 분";
          break;
          
        case MapBoxEvent.route_building:
        case MapBoxEvent.route_built:
          _navigationStatus = "경로 생성 중...";
          break;
          
        case MapBoxEvent.route_build_failed:
          _navigationStatus = "경로 생성 실패";
          _isError = true;
          break;
          
        case MapBoxEvent.navigation_running:
          _navigationStatus = "내비게이션 진행 중";
          break;
          
        case MapBoxEvent.on_arrival:
          _navigationStatus = "목적지 도착";
          _isNavigating = false;
          break;
          
        case MapBoxEvent.navigation_cancelled:
        case MapBoxEvent.navigation_finished:
          _navigationStatus = "내비게이션 종료";
          _isNavigating = false;
          break;
          
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '병원으로 이동 중...',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFE93C4A),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 컨텐츠
            _buildMainContent(),
            
            // 오버레이 상태 표시 (경로 계산 중, 오류 등)
            if (_isNavigating && _routeProgressRemaining.isEmpty)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        _navigationStatus,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _navigationStatus,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isError = false;
                  _setupDialogShown = false;
                });
                _startNavigation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE93C4A),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('다시 시도'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                if (!_setupDialogShown) {
                  _setupDialogShown = true;
                  MapboxTokenHelper.showNetrcSetupDialog(context);
                }
              },
              child: Text('설정 방법 보기'),
            ),
            SizedBox(height: 40),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('이전 화면으로 돌아가기'),
            ),
          ],
        ),
      );
    }
    
    // 네비게이션 중이 아닐 때는 로딩/안내 화면
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.hospital['name'] ?? "병원으로 안내 중",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          if (_routeProgressRemaining.isNotEmpty)
            Text(
              _routeProgressRemaining,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
          SizedBox(height: 32),
          Text(
            _navigationStatus,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 48),
          if (_isNavigating)
            CircularProgressIndicator(color: Color(0xFFE93C4A)),
          SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE93C4A),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              '내비게이션 종료',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
