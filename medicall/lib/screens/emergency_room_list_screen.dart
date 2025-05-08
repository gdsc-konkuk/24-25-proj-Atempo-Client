import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'navigation_screen.dart';

class EmergencyRoomListScreen extends StatefulWidget {
  // 서버에서 받아온 병원 목록 데이터
  final List<dynamic> hospitals;

  const EmergencyRoomListScreen({
    Key? key,
    required this.hospitals,
  }) : super(key: key);

  @override
  _EmergencyRoomListScreenState createState() => _EmergencyRoomListScreenState();
}

class _EmergencyRoomListScreenState extends State<EmergencyRoomListScreen> {
  int? selectedHospitalIndex;
  bool isLoading = false;
  String errorMessage = '';

  // 더 이상 샘플 데이터를 사용하지 않음
  // final List<Map<String, dynamic>> hospitals = [ ... ];

  void selectHospital(int index) {
    setState(() {
      selectedHospitalIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // API 호출이 이미 ChatPage에서 완료되었으므로 여기서는 필요 없음
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
                      // Scrollable list that takes remaining space
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: widget.hospitals.length,
                            itemBuilder: (context, index) {
                              final isSelected = selectedHospitalIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: HospitalCard(
                                  hospital: widget.hospitals[index],
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
                      hospital: widget.hospitals[selectedHospitalIndex!],
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
  final Map<String, dynamic> hospital;
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
                        hospital['name'],
                        style: GoogleFonts.notoSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        hospital['address'],
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
                              Icons.directions_car,
                              size: 16,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 6),
                            Text(
                              hospital['distance'],
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 6),
                            Text(
                              hospital['time'],
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
                        content: Text('Detailed information about ${hospital['name']} will be shown here.'),
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
                  onTap: onSelect,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFE93C4A) : null,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      isSelected ? 'Selected' : 'Select',
                      style: GoogleFonts.notoSans(
                        color: isSelected ? Colors.white : Color(0xFFE93C4A),
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
