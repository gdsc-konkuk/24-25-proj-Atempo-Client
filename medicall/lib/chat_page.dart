import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';  // 현재 위치를 얻기 위해 추가
import 'package:provider/provider.dart';
import 'screens/emergency_room_list_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/location_provider.dart';  // 위치 프로바이더 추가
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/hospital_service.dart';
import 'dart:async';
import 'models/hospital_model.dart';
import 'dart:math' as math;
import 'screens/map_screen.dart';  // 지도 화면 불러오기

class ChatPage extends StatefulWidget {
  final String currentAddress;
  // 위도와 경도를 전달받도록 추가
  final double latitude;
  final double longitude;

  const ChatPage({
    Key? key,
    required this.currentAddress,
    this.latitude = 37.5662,  // 기본값: 서울 시청
    this.longitude = 126.9785, // 기본값: 서울 시청
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _addressController;
  late TextEditingController _patientConditionController;
  final FocusNode _patientConditionFocusNode = FocusNode();
  var uuid = Uuid();
  String _sessionToken = '1234567890';
  bool _isLoading = false;
  bool _isProcessing = false;
  final String _apiUrl = 'http://avenir.my:8080/api/v1/admissions';
  
  // 현재 위치 좌표 (map_screen에서 전달받음)
  late double _latitude;
  late double _longitude;
  
  // 병원 서비스
  final HospitalService _hospitalService = HospitalService();
  
  // 병원 응답 목록
  List<Hospital> _hospitals = [];
  
  // 입원 요청 ID
  String? _admissionId;
  
  // 처리 상태 메시지
  String _processingMessage = '';
  
  // 타이머
  Timer? _messageTimer;
  
  // 구독 취소 객체
  StreamSubscription? _hospitalSubscription;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.currentAddress);
    _patientConditionController = TextEditingController();
    
    // LocationProvider에 초기 값 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      // 위젯에서 전달받은 좌표와 주소로 위치 프로바이더 초기화
      locationProvider.updateLocation(widget.latitude, widget.longitude);
      if (widget.currentAddress != "Finding your location...") {
        locationProvider.updateAddress(widget.currentAddress);
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _patientConditionController.dispose();
    _patientConditionFocusNode.dispose();
    _messageTimer?.cancel();
    _hospitalSubscription?.cancel();
    _hospitalService.closeSSEConnection();
    super.dispose();
  }
  
  // 위치 선택 화면으로 이동
  Future<void> _navigateToMapScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );
    
    // MapScreen에서 돌아왔을 때, 위치 정보 업데이트
    if (mounted) {
      setState(() {
        // 현재는 위치 정보를 직접 업데이트하지 않지만,
        // 필요하다면 여기서 MapScreen에서 반환한 위치 정보를 사용할 수 있음
      });
    }
  }

  // 키보드 내리기
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // 검색 반경 변경 모달
  void _showSearchRadiusModal() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    double tempRadius = settingsProvider.searchRadius;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  color: Color(0xFFFEEBEB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Search Radius Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '${tempRadius.toInt()}km',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFD94B4B),
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: const Color(0xFFD94B4B),
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                        overlayColor: const Color(0xFFD94B4B).withAlpha(50),
                      ),
                      child: Slider(
                        min: 1,
                        max: 50,
                        divisions: 49,
                        value: tempRadius,
                        onChanged: (value) {
                          setModalState(() {
                            tempRadius = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await settingsProvider.setSearchRadius(tempRadius);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              color: const Color(0xFFD94B4B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // 입원 요청 생성
  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
      _hospitals = [];
    });

    try {
      print('[ChatPage] 🏥 Starting hospital search process');
      
      // 위치 프로바이더에서 좌표 가져오기
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final latitude = locationProvider.latitude;
      final longitude = locationProvider.longitude;
      
      print('[ChatPage] 📍 Using coordinates: latitude=${latitude}, longitude=${longitude}');
      
      final searchRadius = context.read<SettingsProvider>().searchRadius.toInt();
      final patientCondition = _patientConditionController.text;
      print('[ChatPage] 🔍 Search parameters: radius=${searchRadius}km, patient condition=${patientCondition}');

      // 입원 요청 생성 시작
      setState(() {
        _isProcessing = true;
        _processingMessage = "AI가 반경 ${searchRadius}km 안에 있는 병원 중 적합한 병원을 검색했습니다. 전화를 걸어 환자를 수용할 수 있는지 확인 중입니다. 잠시만 기다려주세요.";
      });
      print('[ChatPage] 📢 Processing message updated: $_processingMessage');
      
      // 처리 메시지 타이머 설정 (5초)
      print('[ChatPage] ⏱️ Starting 5-second timer for message update');
      _messageTimer = Timer(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _processingMessage = "병원 연락 중...";
          });
          print('[ChatPage] 📢 Processing message updated after timer: $_processingMessage');
        }
      });

      // 토큰 유효성 확인 및 필요시 갱신
      print('[ChatPage] 🔑 Checking token validity');
      final storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'access_token');
      
      if (token == null || token.isEmpty) {
        print('[ChatPage] ⚠️ No token found, attempting to load from AuthProvider');
        // AuthProvider에서 토큰 가져오기 시도
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUser();
        token = await storage.read(key: 'access_token');
        
        if (token == null || token.isEmpty) {
          print('[ChatPage] ❌ Still no token available after refresh attempt');
          throw Exception('로그인이 필요합니다. 토큰을 찾을 수 없습니다.');
        }
      }
      
      print('[ChatPage] ✅ Token available, length: ${token.length}');
      
      // 먼저 SSE 구독을 설정 
      print('[ChatPage] 📡 Setting up SSE subscription BEFORE admission request');
      _subscribeToHospitalUpdates();
      
      // SSE 구독 후 입원 요청 생성
      print('[ChatPage] 🏥 Now calling hospital service to create admission');
      _admissionId = await _hospitalService.createAdmission(
        latitude,
        longitude,
        searchRadius,
        patientCondition
      );
      
      print('[ChatPage] ✅ Admission created with ID: $_admissionId');
            
    } catch (e) {
      print('[ChatPage] ❌ ERROR: Exception while requesting hospital information: $e');
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('병원 정보를 가져오는 중 오류가 발생했습니다: $e'))
      );
    }
  }
  
  // 병원 업데이트 구독
  void _subscribeToHospitalUpdates() {
    print('[ChatPage] 📡 Setting up hospital updates subscription');
    
    // 기존 구독 취소
    if (_hospitalSubscription != null) {
      print('[ChatPage] 🔄 Cancelling existing subscription');
      _hospitalSubscription?.cancel();
    }
    
    // 새로운 구독 시작
    print('[ChatPage] 🔄 Starting new hospital updates subscription');
    _hospitalSubscription = _hospitalService.subscribeToHospitalUpdates().listen(
      (hospital) {
        print('[ChatPage] 📥 Received hospital update: ${hospital.name} (ID: ${hospital.id})');
        
        setState(() {
          // 동일한 ID의 병원이 있는지 확인
          final index = _hospitals.indexWhere((h) => h.id == hospital.id);
          
          if (index >= 0) {
            print('[ChatPage] 🔄 Updating existing hospital at index $index');
            _hospitals[index] = hospital;
          } else {
            print('[ChatPage] ➕ Adding new hospital to list (total: ${_hospitals.length + 1})');
            _hospitals.add(hospital);
          }
          
          // 첫 번째 병원이 들어왔을 때 화면 전환
          if (_hospitals.length == 1 && _isProcessing) {
            print('[ChatPage] 🚀 First hospital received, navigating to hospital list');
            _navigateToHospitalList();
          }
        });
      },
      onError: (error) {
        print('[ChatPage] ❌ Hospital subscription error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('병원 정보 업데이트 중 오류가 발생했습니다: $error'))
        );
      },
      onDone: () {
        print('[ChatPage] ✅ Hospital subscription completed');
      }
    );
    
    print('[ChatPage] ✅ Hospital updates subscription setup completed');
  }
  
  // 입원 요청 재시도
  Future<void> _retryAdmission() async {
    if (_admissionId == null) {
      print('[ChatPage] ❌ No previous admission ID found for retry');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이전 입원 요청 정보가 없습니다.'))
      );
      return;
    }
    
    print('[ChatPage] 🔄 Retrying admission with ID: $_admissionId');
    setState(() {
      _isLoading = true;
      _isProcessing = true;
      _processingMessage = "이전 입원 요청을 다시 시도합니다...";
    });
    print('[ChatPage] 📢 Processing message updated: $_processingMessage');
    
    try {
      // 위치 프로바이더에서 좌표 가져오기
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final latitude = locationProvider.latitude;
      final longitude = locationProvider.longitude;
      
      // 토큰 유효성 확인
      print('[ChatPage] 🔑 Checking token validity for retry');
      final storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'access_token');
      
      // searchRadius를 Provider에서 가져오기
      final searchRadius = context.read<SettingsProvider>().searchRadius.toInt();
      
      if (token == null || token.isEmpty) {
        print('[ChatPage] ⚠️ No token found for retry, attempting to load from AuthProvider');
        // AuthProvider에서 토큰 가져오기 시도
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUser();
        token = await storage.read(key: 'access_token');
        
        if (token == null || token.isEmpty) {
          print('[ChatPage] ❌ Still no token available for retry after refresh attempt');
          throw Exception('로그인이 필요합니다. 토큰을 찾을 수 없습니다.');
        }
      }
      
      print('[ChatPage] ✅ Token available for retry, length: ${token.length}');
      
      // 먼저 SSE 구독을 설정 
      print('[ChatPage] 📡 Setting up SSE subscription for retry BEFORE admission retry request');
      _subscribeToHospitalUpdates();
      
      // SSE 구독 후 입원 요청 재시도
      print('[ChatPage] 🔄 Now calling hospital service to retry admission');
      final retryHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      print('[HospitalService] 🔍 재시도 요청 헤더: $retryHeaders');
      print('[HospitalService] 🔑 갱신된 토큰 길이: ${token.length}, 토큰 시작: ${token.substring(0, math.min(15, token.length))}');

      final retryResponse = await http.post(
        Uri.parse(_apiUrl),
        headers: retryHeaders,
        body: json.encode({
          'admissionId': _admissionId,
          'latitude': latitude,
          'longitude': longitude,
          'searchRadius': searchRadius,
          'patientCondition': _patientConditionController.text
        }),
      );
      
      if (retryResponse.statusCode == 200) {
        print('[ChatPage] ✅ Admission retry successful');
        setState(() {
          _processingMessage = "병원 연락 중...";
        });
        print('[ChatPage] 📢 Processing message updated: $_processingMessage');
      } else {
        print('[ChatPage] 📄 Admission retry response status: ${retryResponse.statusCode}');
        print('[ChatPage] 📄 Admission retry response body: ${retryResponse.body}');
        setState(() {
          _processingMessage = "입원 요청 재시도 중 오류가 발생했습니다. 다시 시도해주세요.";
        });
        print('[ChatPage] 📢 Processing message updated: $_processingMessage');
      }
      
    } catch (e) {
      print('[ChatPage] ❌ Error retrying admission: $e');
      setState(() {
        _isLoading = false;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입원 요청 재시도 중 오류가 발생했습니다: $e'))
      );
    }
  }
  
  // 병원 목록 화면으로 이동
  void _navigateToHospitalList() {
    if (_hospitals.isEmpty) {
      print('[ChatPage] ⚠️ Cannot navigate - no hospitals in list');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아직 응답한 병원이 없습니다.'))
      );
      return;
    }
    
    print('[ChatPage] 🚀 Navigating to hospital list with ${_hospitals.length} hospitals');
    setState(() {
      _isProcessing = false;
      _isLoading = false;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyRoomListScreen(
          hospitals: _hospitals,
          admissionId: _admissionId ?? '',
          hospitalService: _hospitalService,
        ),
      ),
    );
    print('[ChatPage] ✅ Navigation to hospital list initiated');
  }

  @override
  Widget build(BuildContext context) {
    final searchRadius = context.watch<SettingsProvider>().searchRadius;
    final locationProvider = context.watch<LocationProvider>();  // 위치 프로바이더 추가
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 16.0 + keyboardPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '위치 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  
                  // 지도 대신 현재 위치 정보를 보여주는 카드
                  InkWell(
                    onTap: () {
                      // 지도 화면으로 이동
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => MapScreen())
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  locationProvider.address,  // 위치 프로바이더에서 주소 가져오기
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Icon(Icons.map, color: Colors.blue),
                            ],
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '위도: ${locationProvider.latitude.toStringAsFixed(6)}, 경도: ${locationProvider.longitude.toStringAsFixed(6)}',  // 위치 프로바이더에서 좌표 가져오기
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '지도에서 위치 선택하기',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  InkWell(
                    onTap: _showSearchRadiusModal,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.radar,
                            color: Colors.red,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search Radius: ${searchRadius.toInt()}km',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEEBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  Text(
                    'Patient Condition',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200,
                    child: TextField(
                      controller: _patientConditionController,
                      focusNode: _patientConditionFocusNode,
                      maxLines: null,
                      expands: true,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Describe the patient\'s condition...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  // 처리 중 상태 표시
                  if (_isProcessing)
                    Column(
                      children: [
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _processingMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_hospitals.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: _navigateToHospitalList,
                            icon: Icon(Icons.local_hospital),
                            label: Text('응답한 병원 보기 (${_hospitals.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                      ],
                    ),
                  
                  SizedBox(height: 20),
                  Row(
                    children: [
                      // 이전 요청이 있으면 재시도 버튼 표시
                      if (_admissionId != null && !_isProcessing)
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: _retryAdmission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      
                      if (_admissionId != null && !_isProcessing)
                        SizedBox(width: 10),
                      
                      Expanded(
                        flex: _admissionId != null && !_isProcessing ? 2 : 3,
                        child: _isLoading && !_isProcessing
                          ? Center(child: CircularProgressIndicator(color: Colors.red))
                          : ElevatedButton(
                              onPressed: _isProcessing ? null : _fetchHospitals,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: Text(
                                'Find Emergency Room',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
