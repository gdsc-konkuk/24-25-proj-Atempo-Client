import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/hospital_service.dart';
import '../models/hospital_model.dart';
import 'navigation_screen.dart';
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
\            setState(() {
              _admissionId = '123'; // Temporary test ID
              
              // Randomly set the status to SUCCESS or NO_HOSPITAL_FOUND (for testing purposes)
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
              _subscribeToHospitalUpdates();
            }
          });
        }
      },
    );
    print('[EmergencyRoomListScreen] ✅ Hospital updates subscription setup completed');
    
    // If the admissionId is empty, set it to the initial value
    // do nothing
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
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Available hospitals: ${_hospitals.length}',
                                    style: AppTheme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _sortHospitals,
                                      style: TextButton.styleFrom(
                                        minimumSize: Size(0, 0),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        backgroundColor: Colors.grey[200],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: Text(
                                        'Distance',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
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
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
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
                // Navigate to the navigation screen with the selected hospital
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NavigationScreen(
                      hospital: _hospitals[selectedHospitalIndex!].toJson(),
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
                    // retry logic execution, show loading
                    setState(() {
                      isLoading = true;
                    });
                    
                    // retry logic
                    if (_admissionId.isNotEmpty) {
                      widget.hospitalService.retryAdmission(_admissionId).then((response) {
                        setState(() {
                          isLoading = false;
                        });
                        
                        if (response['admissionStatus'] == 'SUCCESS') {
                          // If the retry request is processed successfully
                          setState(() {
                            _status = 'SUCCESS'; // Update status
                          });
                          
                          // Restart the subscription
                          _hospitalSubscription?.cancel();
                          _subscribeToHospitalUpdates();
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Successfully found hospitals. Waiting for responses...'),
                              backgroundColor: Colors.green,
                            )
                          );
                        } else {
                          // Still no hospitals found, keep the status
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No hospitals found. Try again with a larger radius.'),
                              backgroundColor: Colors.orange,
                            )
                          );
                        }
                      }).catchError((error) {
                        setState(() {
                          isLoading = false;
                        });
                        
                        // If an error occurs, show a message
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
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        // If the hospital is not selected, add a border
        border: isSelected ? null : Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          // card content
          Container(
            // If the hospital is selected, add a border
            decoration: isSelected 
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppTheme.primaryColor, width: 2),
                      top: BorderSide(color: AppTheme.primaryColor, width: 2),
                      right: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ) 
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital name
                  Text(
                    hospital.name,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  
                  // Address
                  Text(
                    hospital.address,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Distance and Travel Time
                  Row(
                    children: [
                      // Car icon with distance
                      Icon(
                        Icons.directions_car,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      SizedBox(width: 6),
                      
                      // Distance
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
                      
                      SizedBox(width: 16),
                      
                      // Clock icon with travel time
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      SizedBox(width: 6),
                      
                      // Travel time
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
            ),
          ),
          
          // Action buttons
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Detail button
                Expanded(
                  child: Container(
                    // If the hospital is selected, add a left border
                    decoration: isSelected 
                        ? BoxDecoration(
                            border: Border(
                              left: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ) 
                        : null,
                    child: InkWell(
                      onTap: () {
                        // Navigate to detail screen or show detail modal
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Hospital Details'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hospital Name: ${hospital.name}'),
                                  SizedBox(height: 8),
                                  Text('Address: ${hospital.address}'),
                                  SizedBox(height: 8),
                                  Text('Phone Number: ${hospital.phoneNumber}'),
                                  SizedBox(height: 8),
                                  Text('Available Beds: ${hospital.availableBeds}'),
                                  SizedBox(height: 8),
                                  Text('Distance: ${hospital.distance != null ? '${hospital.distance?.toStringAsFixed(1)}km' : 'N/A'}'),
                                  SizedBox(height: 8),
                                  Text('Travel Time: ${hospital.travelTime != null ? '${hospital.travelTime} min' : 'N/A'}'),
                                  if (hospital.specialties != null) ...[
                                    SizedBox(height: 8),
                                    Text('Specialties: ${hospital.specialties}'),
                                  ],
                                  SizedBox(height: 8),
                                  Text('Status: ${hospital.isAvailable ? "Can accept patients" : "Cannot accept patients"}'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              )
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
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
                
                // Select button
                Expanded(
                  child: isSelected
                      // If the hospital is selected, add a border
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                            // Add a right and bottom border
                            border: Border(
                              right: BorderSide(color: AppTheme.primaryColor, width: 2),
                              bottom: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          child: InkWell(
                            onTap: hospital.isAvailable ? onSelect : null,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  'Selected',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      // If the hospital is not selected, add a border
                      : InkWell(
                          onTap: hospital.isAvailable ? onSelect : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: hospital.isAvailable ? null : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(11),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                hospital.isAvailable ? 'Select' : 'Not Available',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  color: hospital.isAvailable 
                                      ? AppTheme.primaryColor 
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
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
