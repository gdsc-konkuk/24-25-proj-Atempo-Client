import 'package:flutter/material.dart';
import '../screens/chat_page.dart';

class PatientInfoWidget extends StatelessWidget {
  final ScrollController scrollController;
  final String currentAddress;
  final double latitude;
  final double longitude;

  const PatientInfoWidget({
    Key? key,
    required this.scrollController,
    required this.currentAddress,
    this.latitude = 37.5662,
    this.longitude = 126.9785,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Content
          Expanded(
            child: ChatPage(
              currentAddress: currentAddress,
              latitude: latitude,
              longitude: longitude,
            ),
          ),
        ],
      ),
    );
  }
}
