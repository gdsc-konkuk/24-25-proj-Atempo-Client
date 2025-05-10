import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/hospital_service.dart';
import '../models/hospital_model.dart';
import 'navigation_screen.dart';

class EmergencyRoomListScreen extends StatefulWidget {
  // Hospital list data received from server
  final List<Hospital> hospitals;
  final String admissionId;
  final HospitalService hospitalService;

  const EmergencyRoomListScreen({
    Key? key,
    required this.hospitals,
    required this.admissionId,
    required this.hospitalService,
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
  
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _admissionId = widget.admissionId;
    print('[EmergencyRoomListScreen] 🏥 Initializing with ${widget.hospitals.length} hospitals');
    print('[EmergencyRoomListScreen] 🔑 Admission ID: $_admissionId');
    _hospitals = List.from(widget.hospitals);
    _subscribeToHospitalUpdates();
  }

  @override
  void dispose() {
    print('[EmergencyRoomListScreen] 🧹 Disposing screen resources');
    _hospitalSubscription?.cancel();
    super.dispose();
  }

  // Subscribe to real-time hospital list updates
  void _subscribeToHospitalUpdates() {
    print('[EmergencyRoomListScreen] 📡 Setting up hospital updates subscription');
    _hospitalSubscription = widget.hospitalService.subscribeToHospitalUpdates().listen(
      (hospital) {
        print('[EmergencyRoomListScreen] 📥 Received hospital update: ${hospital.name} (ID: ${hospital.id})');
        
        setState(() {
          // Check if there's a hospital with the same ID
          final index = _hospitals.indexWhere((h) => h.id == hospital.id);
          
          if (index >= 0) {
            print('[EmergencyRoomListScreen] 🔄 Updating existing hospital at index $index');
            // Update existing hospital information
            _hospitals[index] = hospital;
          } else {
            print('[EmergencyRoomListScreen] ➕ Adding new hospital to list (total: ${_hospitals.length + 1})');
            // Add new hospital
            _hospitals.add(hospital);
            // AnimatedList에 새 아이템이 추가되었음을 알림
            if (_listKey.currentState != null) {
              _listKey.currentState!.insertItem(_hospitals.length - 1);
            }
          }
        });
      },
      onError: (error) {
        print('[EmergencyRoomListScreen] ❌ Hospital subscription error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating hospital information: $error'))
        );
      },
      onDone: () {
        print('[EmergencyRoomListScreen] ✅ Hospital subscription completed');
      },
    );
    print('[EmergencyRoomListScreen] ✅ Hospital updates subscription setup completed');
    
    // admissionId가 비어있는 경우 (첫 화면 진입 시)
    // 별도의 코드를 추가하지 않음 - 자동으로 SSE를 통해 병원 정보가 업데이트됨
  }

  // 새로운 admission ID를 설정하는 함수 추가
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFE93C4A),
        title: Center(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.notoSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: 'Medi'),
                WidgetSpan(
                  child: Transform.translate(
                    offset: Offset(0, -2),
                    child: Icon(Icons.call, color: Colors.white, size: 22),
                  ),
                  alignment: PlaceholderAlignment.middle,
                ),
                TextSpan(text: 'all'),
              ],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(color: Color(0xFFE93C4A)),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Color(0xFFE93C4A), size: 48),
                        SizedBox(height: 16),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE93C4A)),
                          child: Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : Column(
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
                              style: GoogleFonts.notoSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select the hospital you want to visit',
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
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
                      // Available hospitals count
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available hospitals: ${_hospitals.length}',
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_hospitals.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(
                                  'Hospitals Available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      // Scrollable list that takes remaining space
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _hospitals.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE93C4A)),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'We are continuously searching for hospitals. New hospitals will be added to the list automatically when they respond.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Please wait a moment. We are contacting the emergency hospital.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    // 로딩 애니메이션 개선
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Real-time searching...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.orange[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : AnimatedList(
                                key: _listKey,
                                initialItemCount: _hospitals.length,
                                itemBuilder: (context, index, animation) {
                                  final isSelected = selectedHospitalIndex == index;
                                  final hospital = _hospitals[index];
                                  
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutQuad,
                                    )),
                                    child: FadeTransition(
                                      opacity: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOut,
                                      )),
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 16.0),
                                        child: HospitalCard(
                                          hospital: hospital,
                                          isSelected: isSelected,
                                          onSelect: () => selectHospital(index),
                                        ),
                                      ),
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
              backgroundColor: Color(0xFFE93C4A),
              icon: Icon(Icons.directions),
              label: Text('Navigate'),
            )
          : null,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Color(0xFFE93C4A), width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Color(0xFFE93C4A),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        hospital.address,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      // Distance and travel time information
                      if (hospital.distance != null || hospital.travelTime != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 14,
                                color: Colors.blue[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                hospital.distance != null 
                                    ? '${hospital.distance?.toStringAsFixed(1)}km' 
                                    : '',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hospital.distance != null && hospital.travelTime != null)
                                Text(' • ', style: TextStyle(color: Colors.blue[700])),
                              if (hospital.travelTime != null)
                                Text(
                                  '${hospital.travelTime}분',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hotel,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Available beds: ${hospital.availableBeds}',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  hospital.phoneNumber,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Specialties information
                      if (hospital.specialties != null && hospital.specialties!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: hospital.specialties!.split(',').map((specialty) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  specialty.trim(),
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Navigate to detail screen or show detail modal
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Hospital Details'),
                        content: Column(
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
                            if (hospital.specialties != null) ...[
                              SizedBox(height: 8),
                              Text('Specialties: ${hospital.specialties}'),
                            ],
                            SizedBox(height: 8),
                            Text('Status: ${hospital.isAvailable ? "Can accept patients" : "Cannot accept patients"}'),
                          ],
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
                        top: BorderSide(color: Colors.grey.shade200),
                        right: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      'Detail',
                      style: GoogleFonts.notoSans(
                        color: Color(0xFFE93C4A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: hospital.isAvailable ? onSelect : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(0xFFE93C4A) 
                          : (hospital.isAvailable ? null : Colors.grey[200]),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      isSelected 
                          ? 'Selected' 
                          : (hospital.isAvailable ? 'Select' : 'Not Available'),
                      style: GoogleFonts.notoSans(
                        color: isSelected 
                            ? Colors.white 
                            : (hospital.isAvailable ? Color(0xFFE93C4A) : Colors.grey[600]),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
