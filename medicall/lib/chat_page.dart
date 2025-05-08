import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';  // 현재 위치를 얻기 위해 추가
import 'package:provider/provider.dart';
import 'screens/emergency_room_list_screen.dart';
import 'providers/settings_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/hospital_service.dart';
import 'dart:async';
import 'models/hospital_model.dart';

class ChatPage extends StatefulWidget {
  final String currentAddress;

  const ChatPage({
    Key? key,
    required this.currentAddress,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _addressController;
  late TextEditingController _patientConditionController;
  bool _isAddressEditable = false;
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _patientConditionFocusNode = FocusNode();
  var uuid = Uuid();
  String _sessionToken = '1234567890';
  List<dynamic> _placeList = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  final String _apiUrl = 'http://avenir.my:8080/api/v1/admissions';
  
  // 현재 위치 좌표
  double _latitude = 37.5662;  // 기본값: 서울 시청
  double _longitude = 126.9785;  // 기본값: 서울 시청
  
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
    _getCurrentLocation();  // 초기화 시 현재 위치 가져오기
  }

  @override
  void dispose() {
    _addressController.dispose();
    _patientConditionController.dispose();
    _addressFocusNode.dispose();
    _patientConditionFocusNode.dispose();
    _messageTimer?.cancel();
    _hospitalSubscription?.cancel();
    _hospitalService.closeSSEConnection();
    super.dispose();
  }
  
  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      print('[ChatPage] 🌎 Getting current device location...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('[ChatPage] ⚠️ Location permission denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('[ChatPage] ⚠️ Location permission permanently denied');
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      print('[ChatPage] 📍 Current location: lat=${_latitude}, lng=${_longitude}');
    } catch (e) {
      print('[ChatPage] ⚠️ Error getting location: $e');
      // 오류 발생 시 기본값(서울 시청) 유지
    }
  }

  // 키보드 내리기
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // 주소 검색 다이얼로그
  void _showAddressSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController searchController = TextEditingController();
        _placeList = [];
        _sessionToken = uuid.v4();

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Address Search',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for an address',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (query) async {
                        if (query.length > 2) {
                          setState(() {
                            _isSearching = true;
                          });
                          await _getSuggestions(query, setState);
                        } else if (query.isEmpty) {
                          setState(() {
                            _placeList = [];
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    if (_isSearching)
                      CircularProgressIndicator(color: const Color(0xFFD94B4B))
                    else
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: _placeList.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Type to search for locations'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _placeList.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(_placeList[index]["description"]),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _addressController.text = _placeList[index]["description"];
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: const Color(0xFFD94B4B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _getSuggestions(String input, StateSetter setState) async {
    const String apiKey = "AIzaSyAw92wiRgypo3fVZ4-R5CbpB4x_Pcj1gwk";
    
    try {
      String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request = '$baseURL?input=$input&key=$apiKey&sessiontoken=$_sessionToken';
      
      request += '&types=establishment';
      request += '&keyword=hospital,clinic,medical,emergency';
      
      var response = await http.get(Uri.parse(request));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('Places API response status: ${data['status']}');
        if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
          print('Places API error: ${data['error_message']}');
        }
        
        setState(() {
          _placeList = data['predictions'] ?? [];
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
        print('HTTP error: ${response.statusCode}');
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error getting place suggestions: $e');
    }
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
      
      // 주소 변환 과정을 생략하고 직접 좌표를 사용합니다
      print('[ChatPage] 📍 Using coordinates: latitude=${_latitude}, longitude=${_longitude}');
      
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
        _latitude,  // 현재 위치의 위도 사용
        _longitude,  // 현재 위치의 경도 사용
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
      // 토큰 유효성 확인
      print('[ChatPage] 🔑 Checking token validity for retry');
      final storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'access_token');
      
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
      await _hospitalService.retryAdmission(_admissionId!);
      
      // 메시지 업데이트
      setState(() {
        _processingMessage = "병원 연락 중...";
      });
      print('[ChatPage] 📢 Processing message updated: $_processingMessage');
      
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
                    'Current Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_pin, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: _isAddressEditable
                              ? TextField(
                                  controller: _addressController,
                                  focusNode: _addressFocusNode,
                                  textInputAction: TextInputAction.done, 
                                  decoration: InputDecoration(
                                    hintText: 'Enter address',
                                    border: InputBorder.none,
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.check),
                                      onPressed: () {
                                        setState(() {
                                          _isAddressEditable = false;
                                        });
                                        _dismissKeyboard();
                                      },
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      _isAddressEditable = false;
                                    });
                                  },
                                )
                              : GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isAddressEditable = true;
                                    });
                                    Future.delayed(Duration(milliseconds: 50), () {
                                      FocusScope.of(context).requestFocus(_addressFocusNode);
                                    });
                                  },
                                  child: Text(
                                    _addressController.text,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            _dismissKeyboard();
                            _showAddressSearchDialog();
                          },
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),

                  // 현재 좌표 표시 추가
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '위도: ${_latitude.toStringAsFixed(6)}, 경도: ${_longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
