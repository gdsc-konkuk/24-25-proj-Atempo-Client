import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'emergency_room_list_screen.dart';
import '../providers/settings_provider.dart';
import '../providers/location_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/hospital_service.dart';
import 'dart:async';
import '../models/hospital_model.dart';
import 'dart:math' as math;
import 'map_screen.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  final String currentAddress;
  final double latitude;
  final double longitude;

  const ChatPage({
    Key? key,
    required this.currentAddress,
    this.latitude = 37.5662,  // Default: Seoul City Hall
    this.longitude = 126.9785, // Default: Seoul City Hall
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
  bool _isProcessing = false;
  final String _apiUrl = '${dotenv.env['API_BASE_URL']!}/api/v1/admissions';
  
  // Current location coordinates (received from map_screen)
  late double _latitude;
  late double _longitude;
  
  // Hospital service
  final HospitalService _hospitalService = HospitalService();
  
  // Added ApiService for token handling and HTTP requests
  final ApiService _apiService = ApiService();
  
  // Hospital response list
  List<Hospital> _hospitals = [];
  
  // Admission request ID
  String? _admissionId;
  
  // Processing status message
  String _processingMessage = '';
  
  // Timer
  Timer? _messageTimer;
  
  // Subscription cancellation object
  StreamSubscription? _hospitalSubscription;

  // SSE 구독 상태 관리 변수
  bool _isSseInitialized = false;

  // Add hashtag list and selected tags set
  final List<String> _hashtags = [
    '#Unconscious',
    '#ChestPain',
    '#ShortnessOfBreath',
    '#Seizure',
    '#HeavyBleeding',
    '#StrokeSuspected',
    '#HeartAttack',
    '#Fracture',
    '#SevereAbdominalPain',
    '#HighFever',
  ];
  
  // Set to track selected hashtags
  final Set<String> _selectedTags = {};

  // Key for Emergency Room List Screen navigation
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Add or remove hashtag
  void _toggleHashtag(String tag) {
    final bool wasSelected = _selectedTags.contains(tag);
    final bool willSelect = !wasSelected;
    
    // If the hashtag is not selected, add it
    if (willSelect) {
      setState(() {
        _selectedTags.add(tag);
      });
    } else {
      setState(() {
        _selectedTags.remove(tag);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.currentAddress);
    _patientConditionController = TextEditingController();
    
    // Initialize location provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      // Initialize location provider with coordinates and address from widget
      locationProvider.updateLocation(widget.latitude, widget.longitude);
      if (widget.currentAddress != "Finding your location...") {
        locationProvider.updateAddress(widget.currentAddress);
      }
      
      // 초기화 시 SSE 구독 설정
      _initializeSSE();
    });
  }

  // SSE 초기화 메서드
  Future<void> _initializeSSE() async {
    try {
      print('[ChatPage] 🔄 Initializing SSE subscription before any API requests');
      
      // 이미 초기화되었는지 확인
      if (_isSseInitialized) {
        print('[ChatPage] ✅ SSE already initialized');
        return;
      }
      
      // SSE 구독 설정
      _hospitalSubscription = _hospitalService.subscribeToHospitalUpdates().listen(
        (hospital) {
          print('[ChatPage] 📥 Received hospital update: ${hospital.name} (ID: ${hospital.id})');
          
          setState(() {
            // Check if hospital with same ID exists
            final index = _hospitals.indexWhere((h) => h.id == hospital.id);
            
            if (index >= 0) {
              print('[ChatPage] 🔄 Updating existing hospital at index $index');
              _hospitals[index] = hospital;
            } else {
              print('[ChatPage] ➕ Adding new hospital to list (total: ${_hospitals.length + 1})');
              _hospitals.add(hospital);
            }
            
            // Navigate to hospital list when first hospital arrives
            if (_hospitals.length == 1 && _isProcessing) {
              print('[ChatPage] 🚀 First hospital received, navigating to hospital list');
              _navigateToHospitalList();
            }
          });
        },
        onError: (error) {
          print('[ChatPage] ❌ Hospital subscription error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating hospital information: $error'))
          );
        },
        onDone: () {
          print('[ChatPage] ✅ Hospital subscription completed');
        }
      );
      
      // SSE 초기화 완료
      _isSseInitialized = true;
      print('[ChatPage] ✅ SSE initialization completed successfully');
    } catch (e) {
      print('[ChatPage] ❌ Error initializing SSE: $e');
      _isSseInitialized = false;
    }
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

  // Navigate to map screen
  Future<void> _navigateToMapScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
            );
    
    // Update location information when returning from MapScreen
    if (mounted) {
      setState(() {
        // Location information is not directly updated here,
        // but can use location information returned from MapScreen if needed
      });
    }
  }

  // Dismiss keyboard
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // Search radius change modal
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
  
  // Create admission request
  Future<void> _fetchHospitals() async {
    try {
      print('[ChatPage] 🏥 Starting hospital search process');
      
      // 먼저 SSE 구독이 초기화되었는지 확인하고, 안되어 있으면 초기화
      if (!_isSseInitialized) {
        print('[ChatPage] 🔄 SSE not initialized, initializing now before API request');
        await _initializeSSE();
      } else {
        print('[ChatPage] ✅ SSE already initialized, continuing with API request');
      }
      
      // Get coordinates from location provider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final latitude = locationProvider.latitude;
      final longitude = locationProvider.longitude;
      
      print('[ChatPage] 📍 Using coordinates: latitude=${latitude}, longitude=${longitude}');
      
      final searchRadius = context.read<SettingsProvider>().searchRadius.toInt();
      
      // Combine text field content and selected tags (without # symbol)
      final patientConditionText = _patientConditionController.text.trim();
      final selectedTagsText = _selectedTags
          .map((tag) => tag.substring(1)) // Remove # symbol
          .join(', ');
      
      // Combine both inputs
      final String patientCondition = patientConditionText.isNotEmpty && selectedTagsText.isNotEmpty
          ? '$patientConditionText. $selectedTagsText'
          : patientConditionText.isNotEmpty
              ? patientConditionText
              : selectedTagsText;
      
      print('[ChatPage] 🔍 Search parameters: radius=${searchRadius}km, patient condition=${patientCondition}');

      // 처리 중 상태로 설정
      setState(() {
        _isProcessing = true;
        _processingMessage = "Searching for available emergency rooms...";
      });
      
      // 즉시 EmergencyRoomListScreen으로 이동하여 로딩 화면 표시
      print('[ChatPage] 🚀 Immediately navigating to hospital list screen with loading view');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmergencyRoomListScreen(
            hospitals: [],
            admissionId: '', // 아직 ID 없음
            hospitalService: _hospitalService,
            status: 'SUCCESS', // 초기 상태는 SUCCESS로 설정하여 로딩 화면 표시
          ),
        ),
      );
      
      // API 요청 실행 (화면 이동 후 병렬로 처리)
      print('[ChatPage] 🏥 Creating admission request in background');
      final response = await _hospitalService.createAdmission(
        latitude, 
        longitude, 
        searchRadius, 
        patientCondition
      );
      
      // API 응답 확인 (화면 이동 후에도 로그 출력)
      if (response != null && response.containsKey('admissionId')) {
        _admissionId = response['admissionId'];
        final String admissionStatus = response['admissionStatus'] ?? 'ERROR';
        print('[ChatPage] ✅ Admission created with ID: $_admissionId, Status: $admissionStatus');
      } else {
        print('[ChatPage] ⚠️ No admission ID or status received from server');
      }
    } catch (e) {
      print('[ChatPage] ❌ ERROR: Exception while requesting hospital information: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred while getting hospital information: $e'))
      );
      
      // 에러 발생 시 처리 중 상태 해제
        setState(() {
        _isProcessing = false;
        });
    }
  }
  
  // Retry admission request with admissionId
  Future<void> _retryAdmission() async {
    if (_admissionId == null) {
      print('[ChatPage] ❌ No previous admission ID found for retry');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No previous admission request information.'))
      );
      return;
    }
    
    // SSE 구독이 초기화되어 있는지 확인
    if (!_isSseInitialized) {
      print('[ChatPage] 🔄 SSE not initialized, initializing now before retry API request');
      await _initializeSSE();
    }
    
    print('[ChatPage] 🔄 Retrying admission with ID: $_admissionId');
    setState(() {
      _isProcessing = true;
      _processingMessage = "Retrying previous admission request...";
    });
    print('[ChatPage] 📢 Processing message updated: $_processingMessage');
    
    try {
      // Use HospitalService retryAdmission method 
      final response = await _hospitalService.retryAdmission(_admissionId!);
      
      if (response != null && response.containsKey('admissionStatus')) {
        final String admissionStatus = response['admissionStatus'] ?? 'ERROR';
        print('[ChatPage] ✅ Admission retry status: $admissionStatus');
        
        // 모든 경우 EmergencyRoomListScreen으로 이동
        print('[ChatPage] 🚀 Navigating to hospital list screen after retry');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyRoomListScreen(
              hospitals: [], // Start with empty list
              admissionId: _admissionId ?? '',
              hospitalService: _hospitalService,
              status: admissionStatus, // 상태 전달
            ),
          ),
        );
      } else {
        print('[ChatPage] ⚠️ No admission status received from server after retry');
        setState(() {
          _isProcessing = false;
        });
        
        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No admission status received from server after retry'))
        );
      }
    } catch (e) {
      print('[ChatPage] ❌ Error retrying admission: $e');
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrying admission request: $e'))
      );
    }
  }
  
  // Navigate to hospital list screen
  void _navigateToHospitalList() {
    print('[ChatPage] 🚀 Navigating to hospital list with ${_hospitals.length} hospitals');
    setState(() {
      _isProcessing = false;
    });
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyRoomListScreen(
          hospitals: _hospitals,
          admissionId: _admissionId ?? '',
          hospitalService: _hospitalService,
          status: 'SUCCESS', // hospitals가 있으므로 상태는 SUCCESS로 설정
        ),
      ),
    );
    print('[ChatPage] ✅ Navigation to hospital list initiated');
  }

  @override
  Widget build(BuildContext context) {
    final searchRadius = context.watch<SettingsProvider>().searchRadius;
    final locationProvider = context.watch<LocationProvider>();

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppTheme.buildAppBar(
          title: 'Find Emergency Room',
          leading: AppTheme.buildBackButton(context),
        ),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Location',
                      style: AppTheme.textTheme.displaySmall,
                    ),
                    SizedBox(height: 8),
                    
                    // Location card
                    RepaintBoundary(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => MapScreen())
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: AppTheme.primaryColor),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      locationProvider.address,
                                      style: AppTheme.textTheme.bodyLarge,
                                    ),
                                  ),
                                  Icon(Icons.map, color: Colors.blue),
                                ],
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'If the displayed location is incorrect, please click "Select location on map" on the map to change it',
                                  style: AppTheme.textTheme.bodyMedium,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Select location on map',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                    RepaintBoundary(
                      child: InkWell(
                        onTap: _showSearchRadiusModal,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.radar,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search Radius: ${searchRadius.toInt()}km',
                                  style: AppTheme.textTheme.bodyLarge,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Edit',
                                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Text(
                      'Patient Condition',
                      style: AppTheme.textTheme.displaySmall,
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 100,
                      child: TextField(
                        controller: _patientConditionController,
                        focusNode: _patientConditionFocusNode,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        style: AppTheme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Describe the patient\'s condition...',
                          hintStyle: AppTheme.textTheme.bodyMedium,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.all(16),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    Text(
                      'Quick Symptoms',
                      style: AppTheme.textTheme.displaySmall,
                    ),
                    SizedBox(height: 8),
                    RepaintBoundary(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _hashtags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return InkWell(
                            onTap: () => _toggleHashtag(tag),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    if (_isProcessing)
                      Column(
                        children: [
                          SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
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
                                    style: AppTheme.textTheme.bodyMedium?.copyWith(
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
                              label: Text('View Responding Hospitals (${_hospitals.length})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    
                    SizedBox(height: 20),
                    Row(
                      children: [
                        if (_admissionId != null && !_isProcessing)
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: _retryAdmission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        
                        if (_admissionId != null && !_isProcessing)
                          SizedBox(width: 10),
                        
                        Expanded(
                          flex: _admissionId != null && !_isProcessing ? 2 : 3,
                          child: ElevatedButton(
                            onPressed: _fetchHospitals,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Find Emergency Room',
                              style: AppTheme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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
      ),
    );
  }
} 