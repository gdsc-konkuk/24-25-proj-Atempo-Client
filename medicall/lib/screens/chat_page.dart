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
  bool _isLoading = false;
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
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
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
    setState(() {
      _isLoading = true;
      _hospitals = [];
    });

    try {
      print('[ChatPage] 🏥 Starting hospital search process');
      
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

      // Initialize loading state
      setState(() {
        _isLoading = false;
      });
      
      // Cancel existing subscription
      if (_hospitalSubscription != null) {
        print('[ChatPage] 🔄 Cancelling existing subscription before navigation');
        _hospitalSubscription?.cancel();
        _hospitalSubscription = null;
      }
      
      // Immediately navigate to hospital list screen before API response
      print('[ChatPage] 🚀 Immediately navigating to hospital list screen before API response');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmergencyRoomListScreen(
            hospitals: [], // Start with empty list
            admissionId: '', // No ID yet
            hospitalService: _hospitalService,
          ),
        ),
      );
      
      // Process API request in parallel with UI navigation
      print('[ChatPage] 🏥 Now creating admission request using ApiService');
      
      final requestData = {
        'location': {
          'latitude': latitude,
          'longitude': longitude
        },
        'search_radius': searchRadius,
        'patient_condition': patientCondition
      };
      
      final response = await _apiService.post('api/v1/admissions', requestData);
      
      if (response != null && response.containsKey('admissionId')) {
        _admissionId = response['admissionId']?.toString() ?? '';
        print('[ChatPage] ✅ Admission created with ID: $_admissionId');
        // Hospitals will be updated automatically through SSE in EmergencyRoomListScreen
      } else {
        print('[ChatPage] ⚠️ No admission ID received from server');
        throw Exception('No admission ID received from server');
      }
            
    } catch (e) {
      print('[ChatPage] ❌ ERROR: Exception while requesting hospital information: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred while getting hospital information: $e'))
      );
    }
  }
  
  // Subscribe to hospital updates
  void _subscribeToHospitalUpdates() {
    print('[ChatPage] 📡 Setting up hospital updates subscription');
    
    // Cancel existing subscription
    if (_hospitalSubscription != null) {
      print('[ChatPage] 🔄 Cancelling existing subscription');
      _hospitalSubscription?.cancel();
    }
    
    // Start new subscription
    print('[ChatPage] 🔄 Starting new hospital updates subscription');
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
    
    print('[ChatPage] ✅ Hospital updates subscription setup completed');
  }
  
  // Retry admission request
  Future<void> _retryAdmission() async {
    if (_admissionId == null) {
      print('[ChatPage] ❌ No previous admission ID found for retry');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No previous admission request information.'))
      );
      return;
    }
    
    print('[ChatPage] 🔄 Retrying admission with ID: $_admissionId');
    setState(() {
      _isLoading = true;
      _isProcessing = true;
      _processingMessage = "Retrying previous admission request...";
    });
    print('[ChatPage] 📢 Processing message updated: $_processingMessage');
    
    try {
      // Get coordinates from location provider
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final latitude = locationProvider.latitude;
      final longitude = locationProvider.longitude;
      
      // Get searchRadius from Provider
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
      
      // Set up SSE subscription first
      print('[ChatPage] 📡 Setting up SSE subscription for retry BEFORE admission retry request');
      _subscribeToHospitalUpdates();
      
      // Retry admission request after SSE subscription using ApiService
      print('[ChatPage] 🔄 Now retrying admission using ApiService');
      
      final requestData = {
        'admissionId': _admissionId,
        'location': {
          'latitude': latitude,
          'longitude': longitude
        },
        'search_radius': searchRadius,
        'patient_condition': patientCondition
      };
      
      await _apiService.post('api/v1/admissions', requestData);
      
      setState(() {
        _processingMessage = "Contacting hospitals...";
      });
      print('[ChatPage] 📢 Processing message updated: $_processingMessage');
      
    } catch (e) {
      print('[ChatPage] ❌ Error retrying admission: $e');
      setState(() {
        _isLoading = false;
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
    final locationProvider = context.watch<LocationProvider>();
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppTheme.buildAppBar(
          title: 'Find Emergency Room',
          leading: AppTheme.buildBackButton(context),
        ),
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
                    'Select Location',
                    style: AppTheme.textTheme.displaySmall,
                  ),
                  SizedBox(height: 8),
                  
                  // Location card
                  InkWell(
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

                  SizedBox(height: 16),
                  InkWell(
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
                      maxLines: null,
                      expands: true,
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
                  Wrap(
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
                        child: _isLoading && !_isProcessing
                          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                          : ElevatedButton(
                              onPressed: _isProcessing ? null : _fetchHospitals,
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
    );
  }
} 