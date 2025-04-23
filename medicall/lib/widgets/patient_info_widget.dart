import 'package:flutter/material.dart';

class PatientInfoWidget extends StatefulWidget {
  final ScrollController scrollController;
  final String currentAddress;

  const PatientInfoWidget({
    Key? key,
    required this.scrollController,
    required this.currentAddress,
  }) : super(key: key);

  @override
  _PatientInfoWidgetState createState() => _PatientInfoWidgetState();
}

class _PatientInfoWidgetState extends State<PatientInfoWidget> {
  late TextEditingController _addressController;
  late TextEditingController _patientConditionController;
  bool _isEditingAddress = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.currentAddress);
    _patientConditionController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _patientConditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 20),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(_isEditingAddress ? Icons.check : Icons.edit, 
                     color: const Color(0xFFD94B4B)),
                onPressed: () {
                  setState(() {
                    _isEditingAddress = !_isEditingAddress;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          _isEditingAddress
              ? TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_pin, color: const Color(0xFFD94B4B)),
                    hintText: 'Enter your location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_pin, color: const Color(0xFFD94B4B)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _addressController.text,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
          SizedBox(height: 20),
          Text(
            'Patient Condition',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _patientConditionController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Describe the patient\'s condition...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Searching emergency rooms near: ${_addressController.text}'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD94B4B),
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
    );
  }
}
