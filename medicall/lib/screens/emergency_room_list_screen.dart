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

  @override
  void initState() {
    super.initState();
    print('[EmergencyRoomListScreen] 🏥 Initializing with ${widget.hospitals.length} hospitals');
    print('[EmergencyRoomListScreen] 🔑 Admission ID: ${widget.admissionId}');
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
                      // Scrollable list that takes remaining space
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _hospitals.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Color(0xFFE93C4A)),
                                    SizedBox(height: 16),
                                    Text(
                                      'Waiting for hospital responses...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
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
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
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
                            SizedBox(width: 16),
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
