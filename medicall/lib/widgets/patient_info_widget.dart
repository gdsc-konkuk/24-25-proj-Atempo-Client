import 'package:flutter/material.dart';
import '../chat_page.dart';

class PatientInfoWidget extends StatelessWidget {
  final ScrollController scrollController;
  final String currentAddress;

  const PatientInfoWidget({
    Key? key,
    required this.scrollController,
    required this.currentAddress,
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
            child: ChatPage(currentAddress: currentAddress),
          ),
        ],
      ),
    );
  }
}
