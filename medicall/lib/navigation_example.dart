import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

class NavigationExample extends StatefulWidget {
  @override
  _NavigationExampleState createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  // Mapbox Navigation Controller
  MapBoxNavigationViewController? _controller;
  
  // 네비게이션 상태
  bool _isNavigating = false;
  bool _routeBuilt = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  
  // 네비게이션 정보
  double _distanceRemaining = 0.0;
  double _durationRemaining = 0.0;
  
  // 네비게이션 옵션
  late MapBoxOptions _options;
  
  @override
  void initState() {
    super.initState();
    _initializeNavigationOptions();
  }
  
  void _initializeNavigationOptions() {
    // 옵션 설정 
    _options = MapBoxOptions(
      // 초기화 부분에서는 accessToken을 설정하지 않음
      mapStyleUrlDay: "mapbox://styles/mapbox/navigation-day-v1",
      mapStyleUrlNight: "mapbox://styles/mapbox/navigation-night-v1",
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      mode: MapBoxNavigationMode.drivingWithTraffic,
      units: VoiceUnits.metric,
      simulateRoute: true,
      language: "ko",
    );
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _onRouteEvent(e) async {
    if (e.eventType == MapBoxEvent.progress_change) {
      var progressEvent = e.data as RouteProgressEvent;
      // 이제 컨트롤러를 통해 정보를 얻습니다
      if (_controller != null) {
        _distanceRemaining = await _controller!.getDistanceRemaining() ?? 0.0;
        _durationRemaining = await _controller!.getDurationRemaining() ?? 0.0;
      }
      
      setState(() {});
    } else if (e.eventType == MapBoxEvent.route_built) {
      setState(() {
        _routeBuilt = true;
      });
    } else if (e.eventType == MapBoxEvent.route_build_failed) {
      setState(() {
        _routeBuilt = false;
      });
    } else if (e.eventType == MapBoxEvent.navigation_running) {
      setState(() {
        _isNavigating = true;
      });
    } else if (e.eventType == MapBoxEvent.navigation_finished ||
               e.eventType == MapBoxEvent.navigation_cancelled) {
      setState(() {
        _routeBuilt = false;
        _isNavigating = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapbox Navigation Example'),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startNavigation,
                child: Text('Start Full-screen Navigation'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showEmbeddedNavigation,
                child: Text('Show Embedded Navigation'),
              ),
              if (_isNavigating)
                Column(
                  children: [
                    SizedBox(height: 20),
                    Text('Distance Remaining: ${(_distanceRemaining / 1000).toStringAsFixed(2)} km'),
                    Text('Duration Remaining: ${(_durationRemaining / 60).toStringAsFixed(2)} min'),
                  ],
                ),
            ],
          ),
        ),
    );
  }
  
  Future<void> _startNavigation() async {
    // 임시 창을 통해 컨트롤러 초기화 후 전체 화면 네비게이션 시작
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 100,
            height: 100,
            child: MapBoxNavigationView(
              options: _options,
              onCreated: (controller) async {
                _controller = controller;
                try {
                  await _controller!.initialize();
                  
                  // 초기화 성공 후 전체 화면 네비게이션 준비
                  WayPoint origin = WayPoint(
                    name: "출발지",
                    latitude: 37.5642, // 서울시청
                    longitude: 126.9742,
                  );
                  
                  WayPoint destination = WayPoint(
                    name: "목적지",
                    latitude: 37.5665, // 광화문
                    longitude: 126.9780,
                  );
                  
                  Navigator.pop(context); // 임시 다이얼로그 닫기
                  
                  // 전체 화면 네비게이션
                  if (_controller != null) {
                    // 경로 구축 및 네비게이션 시작
                    await _controller!.startNavigation(
                      wayPoints: [origin, destination],
                      options: _options
                    );
                  }
                } catch (e) {
                  print("네비게이션 초기화 오류: $e");
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      },
    );
  }
  
  void _showEmbeddedNavigation() {
    setState(() {
      _routeBuilt = true;
      _isNavigating = true;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          child: MapBoxNavigationView(
            options: _options,
            onRouteEvent: _onRouteEvent,
            onCreated: (controller) async {
              _controller = controller;
              
              try {
                // 새로운 초기화 방식
                await _controller!.initialize();
                setState(() {
                  _isInitialized = true;
                });
              
                WayPoint origin = WayPoint(
                  name: "출발지",
                  latitude: 37.5642, // 서울시청
                  longitude: 126.9742,
                );
                
                WayPoint destination = WayPoint(
                  name: "목적지",
                  latitude: 37.5665, // 광화문
                  longitude: 126.9780,
                );
                
                await controller.buildRoute(
                  wayPoints: [origin, destination]
                );
                
                await controller.startNavigation();
              } catch (e) {
                print("네비게이션 초기화 오류: $e");
              }
            },
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _routeBuilt = false;
        _isNavigating = false;
      });
    });
  }
}
