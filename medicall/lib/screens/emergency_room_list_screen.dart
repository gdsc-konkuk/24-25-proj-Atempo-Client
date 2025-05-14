import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/hospital_service.dart';
import '../models/hospital_model.dart';
import 'mapbox_navigation_screen.dart';
import '../theme/app_theme.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

// ort option
enum SortOption {
  distance,
}

class EmergencyRoomListScreen extends StatefulWidget {
  // Hospital list data received from server
  final List<Hospital> hospitals;
  final String admissionId;
  final HospitalService hospitalService;
  final String status; // 추가된 status 파라미터

  const EmergencyRoomListScreen({
    Key? key,
    required this.hospitals,
    required this.admissionId,
    required this.hospitalService,
    this.status = 'SUCCESS', 
  }) : super(key: key);

  @override
  _EmergencyRoomListScreenState createState() => _EmergencyRoomListScreenState();
}

class _EmergencyRoomListScreenState extends State<EmergencyRoomListScreen> {
  int? selectedHospitalIndex;
  bool isLoading = false;
  String errorMessage = '';
  late List<Hospital> _hospitals;
  StreamSubscription? _hospitalSubscription;
  late String _admissionId;
  late String _status; // Add status parameter
  
  // sort option
  SortOption _currentSortOption = SortOption.distance; // default is distance
  
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _admissionId = widget.admissionId;
    _status = widget.status; // Initialize status
    print('[EmergencyRoomListScreen] 🏥 Initializing with ${widget.hospitals.length} hospitals');
    print('[EmergencyRoomListScreen] 🔑 Admission ID: $_admissionId');
    print('[EmergencyRoomListScreen] 🔑 Status: $_status');
    _hospitals = List.from(widget.hospitals);
    _sortHospitals(); // initial sort
    
    // If the status is SUCCESS, subscribe to hospital updates
    if (_status == 'SUCCESS') {
      if (_admissionId.isNotEmpty) {
        _subscribeToHospitalUpdates();
      } else {
        // If the admission ID is empty (initial loading) set up the broadcast listener
        print('[EmergencyRoomListScreen] 🔄 Setting up broadcast listener for admission results');
        
        // TODO: Set up the actual broadcast event and use it to receive admission results
        // Example implementation (for testing purposes): Set the status to SUCCESS or NO_HOSPITAL_FOUND after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              // 테스트 ID '123'을 사용하지 않고 실제 API 응답에서 받아올 ID를 사용하도록 수정
              // _admissionId = '123'; // 이전: 테스트용 임시 ID
              
              // 랜덤하게 SUCCESS 또는 NO_HOSPITAL_FOUND 상태 설정 (테스트용)
              _status = (DateTime.now().millisecondsSinceEpoch % 2 == 0) ? 'SUCCESS' : 'NO_HOSPITAL_FOUND';
              
              print('[EmergencyRoomListScreen] 🔄 Status updated to: $_status');
              
              if (_status == 'SUCCESS') {
                _subscribeToHospitalUpdates();
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    print('[EmergencyRoomListScreen] 🧹 Disposing screen resources');
    _hospitalSubscription?.cancel();
    super.dispose();
  }

  // sort hospitals
  void _sortHospitals() {
    // 병원 목록이 비어 있으면 정렬하지 않음
    if (_hospitals.isEmpty) return;
    
    setState(() {
      // sort by distance (null items are at the end)
      _hospitals.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });
    });
  }

  // subscribe to real-time hospital list updates
  void _subscribeToHospitalUpdates() {
    print('[EmergencyRoomListScreen] 📡 Setting up hospital updates subscription');
    
    // 이미 구독 중인 경우 중복 구독 방지
    if (_hospitalSubscription != null) {
      print('[EmergencyRoomListScreen] ℹ️ Already subscribed to hospital updates, reusing existing subscription');
      return;
    }
    
    _hospitalSubscription = widget.hospitalService.subscribeToHospitalUpdates().listen(
      (hospital) {
        print('[EmergencyRoomListScreen] 📥 Received hospital update: ${hospital.name} (ID: ${hospital.id})');
        
        // Call useState to update the hospital list
        if (mounted) {
          setState(() {
            // Check if there's a hospital with the same ID
            final index = _hospitals.indexWhere((h) => h.id == hospital.id);
            
            if (index >= 0) {
              print('[EmergencyRoomListScreen] 🔄 Updating existing hospital at index $index');
              _hospitals[index] = hospital;
            } else {
              print('[EmergencyRoomListScreen] ➕ Adding new hospital to list (total: ${_hospitals.length + 1})');
              _hospitals.add(hospital);
              // Alert when new hospital is added
              if (_listKey.currentState != null) {
                _listKey.currentState!.insertItem(_hospitals.length - 1);
              }
              
              // 새로운 병원이 추가되면 NO_HOSPITAL_FOUND 상태에서 SUCCESS 상태로 변경
              if (_status != 'SUCCESS') {
                print('[EmergencyRoomListScreen] 🔄 Status changed from $_status to SUCCESS');
                setState(() {
                  _status = 'SUCCESS';
                });
              }
            }
            
            // when new hospital is added or updated, sort the list
            _sortHospitals();
          });
        }
      },
      onError: (error) {
        print('[EmergencyRoomListScreen] ❌ Hospital subscription error: $error');
        if (mounted) {
          setState(() {
            errorMessage = 'Error updating hospital information: $error';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating hospital information: $error'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  // Try to resubscribe
                  _hospitalSubscription?.cancel();
                  _hospitalSubscription = null;
                  _subscribeToHospitalUpdates();
                },
              ),
            )
          );
        }
      },
      onDone: () {
        print('[EmergencyRoomListScreen] ✅ Hospital subscription completed');
        
        // If hospital data reception is stopped, try to resubscribe
        if (mounted && _hospitals.isEmpty) {
          print('[EmergencyRoomListScreen] ⚠️ Hospital subscription ended with no hospitals - attempting to resubscribe');
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              _hospitalSubscription?.cancel();
              _hospitalSubscription = null;
              _subscribeToHospitalUpdates();
            }
          });
        }
      },
    );
    print('[EmergencyRoomListScreen] ✅ Hospital updates subscription setup completed');
  }

  // Function to start the new admission ID
  void updateAdmissionId(String newAdmissionId) {
    if (mounted) {
      setState(() {
        _admissionId = newAdmissionId;
      });
      print('[EmergencyRoomListScreen] 🔄 Admission ID updated to: $_admissionId');
    }
  }

  void selectHospital(int index) {
    print('[EmergencyRoomListScreen] 👆 Hospital selected at index $index: ${_hospitals[index].name}');
    setState(() {
      selectedHospitalIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppTheme.buildAppBar(
        title: 'Medicall',
        leading: AppTheme.buildBackButton(context),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        'assets/images/spinner_call.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'AI is calling the hospital to confirm the hospital\'s ability to accept patients',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search, size: 18, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Search radius: ${settingsProvider.searchRadius.toInt()} km',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                        SizedBox(height: 16),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: AppTheme.textTheme.bodyLarge,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                          child: Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : _status != 'SUCCESS'
                    ? _buildNoHospitalFoundView(context) // NO_HOSPITAL_FOUND, ERROR
                    : Column( // If the status is SUCCESS, show the hospital list
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header section with fixed height
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nearby Emergency Rooms',
                                  style: AppTheme.textTheme.displayMedium,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select the hospital you want to visit',
                                  style: AppTheme.textTheme.bodyMedium,
                                ),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                          // Real-time status information
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700]),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'We are continuously searching for hospitals. New hospitals will be added to the list automatically when they respond.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Hospital count (only when we have hospitals)
                          if (_hospitals.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available hospitals: ${_hospitals.length}',
                                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Consumer<SettingsProvider>(
                                    builder: (context, settingsProvider, child) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.search, size: 16, color: Colors.grey[700]),
                                            SizedBox(width: 4),
                                            Text(
                                              'Radius: ${settingsProvider.searchRadius.toInt()} km',
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                          if (_hospitals.isNotEmpty)
                            SizedBox(height: 8),
                          
                          // Scrollable list that takes remaining space
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _hospitals.isEmpty
                                // Loading screen (no hospitals yet in SUCCESS state)
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: Lottie.asset(
                                            'assets/images/spinner_call.json',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'AI is calling the hospital to confirm the hospital\'s ability to accept patients',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Consumer<SettingsProvider>(
                                          builder: (context, settingsProvider, child) {
                                            return Container(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.search, size: 18, color: Colors.grey[600]),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Search radius: ${settingsProvider.searchRadius.toInt()} km',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.only(bottom: 16),
                                    itemCount: _hospitals.length,
                                    itemBuilder: (context, index) {
                                      final isSelected = selectedHospitalIndex == index;
                                      final hospital = _hospitals[index];
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16.0),
                                        child: HospitalCard(
                                          hospital: hospital,
                                          isSelected: isSelected,
                                          onSelect: () => selectHospital(index),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ),
                        ],
                      ),
      ),
      floatingActionButton: selectedHospitalIndex != null
          ? FloatingActionButton.extended(
              onPressed: () {
                
                final selectedHospital = _hospitals[selectedHospitalIndex!];
                print('[EmergencyRoomListScreen] Selected hospital: ${selectedHospital.name}');
                print('[EmergencyRoomListScreen] Hospital coordinates: latitude=${selectedHospital.latitude}, longitude=${selectedHospital.longitude}');
                
                // 선택한 병원을 Map으로 변환하여 MapboxNavigationScreen으로 직접 전달
                Map<String, dynamic> hospitalData = {
                  'id': selectedHospital.id,
                  'name': selectedHospital.name,
                  'address': selectedHospital.address,
                  'latitude': selectedHospital.latitude,
                  'longitude': selectedHospital.longitude,
                  'phoneNumber': selectedHospital.phoneNumber,
                };
                
                // MapboxNavigationScreen으로 직접 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapboxNavigationScreen(
                      hospital: hospitalData,
                    ),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: Icon(Icons.directions, color: Colors.white),
              label: Text('Navigate', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  // When no hospitals are found, show this view
  Widget _buildNoHospitalFoundView(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    double searchRadius = settingsProvider.searchRadius;
    
    return StatefulBuilder(
      builder: (context, setState) => Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Search icon (includes X icon)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search,
                      size: 45,
                      color: Colors.grey[600],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              // Message
              Text(
                'No available hospitals matched',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Try adjusting the search radius below',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              
              // Display current radius
              Text(
                '${searchRadius.toInt()}km',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 10),
              
              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.red,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Colors.red,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 10.0,
                  ),
                  overlayColor: Colors.red.withAlpha(50),
                ),
                child: Slider(
                  min: 1,
                  max: 50,
                  divisions: 49,
                  value: searchRadius,
                  onChanged: (value) {
                    setState(() {
                      searchRadius = value;
                    });
                  },
                  onChangeEnd: (value) {
                    settingsProvider.setSearchRadius(value);
                  },
                ),
              ),
              SizedBox(height: 40),
              
              // Retry button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 메인 상태 업데이트를 위해 StatefulBuilder의 setState가 아닌 this.setState 사용
                    this.setState(() {
                      isLoading = true;
                    });
                    
                    // 병원 상태를 리셋
                    this.setState(() {
                      _hospitals = [];
                      _status = 'SUCCESS'; // 로딩 화면을 표시하기 위해 SUCCESS로 변경
                    });
                    
                    // retry logic
                    if (_admissionId.isNotEmpty) {
                      widget.hospitalService.retryAdmission(_admissionId).then((response) {
                        if (response['admissionStatus'] == 'SUCCESS') {
                          // 로딩 화면이 이미 보이는 상태이므로 추가 작업 필요 없음
                          print('[EmergencyRoomListScreen] ✅ Retry successful, showing loading screen');
                          
                          // 기존 구독 취소 후 새로 구독
                          _hospitalSubscription?.cancel();
                          _hospitalSubscription = null;
                          _subscribeToHospitalUpdates();
                          
                          // 로딩 완료 상태로 변경
                          this.setState(() {
                            isLoading = false;
                          });
                          
                          // 성공 메시지 표시
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully found hospitals. Waiting for responses...'),
                              backgroundColor: Colors.green,
                            )
                          );
                        } else {
                          // 실패 시 다시 NO_HOSPITAL_FOUND 상태로 되돌림
                          this.setState(() {
                            _status = 'NO_HOSPITAL_FOUND';
                            isLoading = false;
                          });
                          
                          // 실패 메시지 표시
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No hospitals found. Try again with a larger radius.'),
                              backgroundColor: Colors.orange,
                            )
                          );
                        }
                      }).catchError((error) {
                        // 오류 발생 시 원래 상태로 복귀
                        this.setState(() {
                          _status = 'NO_HOSPITAL_FOUND';
                          isLoading = false;
                        });
                        
                        // 오류 메시지 표시
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error retrying: $error'),
                            backgroundColor: Colors.red,
                          )
                        );
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Add Go Back button
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HospitalCard extends StatelessWidget {
  final Hospital hospital;
  final bool isSelected;
  final VoidCallback onSelect;

  const HospitalCard({
    required this.hospital,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppTheme.primaryColor : Colors.grey.shade200;
    
    return Container(
      clipBehavior: Clip.antiAlias, // child widgets do not exceed the container boundaries
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
        // 선택된 경우 빨간색 테두리 표시
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // 카드 콘텐츠
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 병원 이름
                Text(
                  hospital.name,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                
                // 주소
                Text(
                  hospital.address,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 12),
                
                // 거리 및 소요 시간
                Row(
                  children: [
                    // 거리
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        SizedBox(width: 4),
                        Text(
                          hospital.distance != null 
                              ? '${hospital.distance?.toStringAsFixed(1)}km' 
                              : '-',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(width: 16),
                    
                    // 소요 시간
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        SizedBox(width: 4),
                        Text(
                          hospital.travelTime != null 
                              ? '${hospital.travelTime} min' 
                              : '-',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 버튼 영역
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Detail 버튼
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // 상세 정보 모달 표시
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 헤더 섹션 (병원 이름과 가용 여부)
                                  Row(
                                    children: [
                                      // 상태 인디케이터
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: hospital.isAvailable ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      // 병원 이름
                                      Expanded(
                                        child: Text(
                                          hospital.name,
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      // 닫기 버튼
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: Icon(Icons.close, color: Colors.grey[600]),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  
                                  // 상태 텍스트
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: Text(
                                      hospital.isAvailable ? "Available" : "Not Available",
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        color: hospital.isAvailable ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // 구분선
                                  Divider(color: Colors.grey[200], thickness: 1),
                                  SizedBox(height: 16),
                                  
                                  // 정보 섹션
                                  // 주소
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Address",
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              hospital.address,
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // 전화번호
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 20, color: Colors.grey[600]),
                                      SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Phone",
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            hospital.phoneNumber,
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // 병상 수
                                  Row(
                                    children: [
                                      Icon(Icons.local_hospital, size: 20, color: Colors.grey[600]),
                                      SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Available Beds",
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            hospital.availableBeds.toString(),
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16),
                                  
                                  // 거리 및 이동 시간
                                  Row(
                                    children: [
                                      // 거리
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.directions_car, size: 20, color: Colors.grey[600]),
                                            SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Distance",
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  hospital.distance != null ? '${hospital.distance?.toStringAsFixed(1)}km' : 'N/A',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // 이동 시간
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                                            SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Travel Time",
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  hospital.travelTime != null ? '${hospital.travelTime} min' : 'N/A',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // 전문 분야 (있는 경우에만 표시)
                                  if (hospital.specialties != null && hospital.specialties!.isNotEmpty) ...[
                                    SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.medical_services_outlined, size: 20, color: Colors.grey[600]),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Specialties",
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                hospital.specialties!,
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  SizedBox(height: 24),
                                  
                                  // 버튼 섹션
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.grey[400]!),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: Text(
                                            'Close',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      SizedBox(width: 12),
                                      
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: hospital.isAvailable 
                                            ? () {
                                                Navigator.pop(context);
                                                // 선택 기능 수행
                                                onSelect();
                                              } 
                                            : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryColor,
                                            disabledBackgroundColor: Colors.grey[300],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: Text(
                                            'Select',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
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
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Text(
                          'Detail',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Select 버튼
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hospital.isAvailable ? onSelect : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            isSelected 
                              ? 'Selected' 
                              : (hospital.isAvailable ? 'Select' : 'Not Available'),
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: isSelected 
                                ? AppTheme.primaryColor 
                                : (hospital.isAvailable ? AppTheme.primaryColor : Colors.grey[500]),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
