import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Display search radius settings modal
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

                decoration: BoxDecora
ion(
color: Color(0xFF,
FEEBEB),
borderRadius: BorderRadius.circular(20),
),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(

                      'Search
Radius Settings',
,
                      style: GoogleFonts.notoSans(
fontSize: 18,
fontWeight: FontWeight.bold,
),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '${tempRadius.toInt()}km',
                      style: GoogleFonts.notoSans(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFD94B4B),
                        inact
iveTrackColor: Colors.g,
rey[300],
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

                            Navigator.of(context)
pop();
,
                          },
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.notoSans(
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

  @override
  Widget build(BuildContext context) {
    // Get search radius from SettingsProvider
    final searchRadius = context.watch<SettingsProvider>().searchRadius;
    
    return Scaffold(
      appBar: AppBar(
        title: 
Text('Chat'),

        backgroundColo
r: const Color(0xFFD94B4B),
      ),
      body: Column(
        children: [
          // Current location display section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
color: Colors.white,
border: Border(
bottom: BorderSide(color: Colors.grey.shade200),
              ),
),
            child: Row(
              children: [
                Icon(
Icons.location_on,
color: const Color(0xFFD94B4B),
size: 24,
),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Location',
                    style: TextStyle(
fontWeight: FontWeight.w600,
fontSize: 14,
),
                  ),
                ),
              ],
            ),
          ),
          // Search radius setting section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
color: Colors.white,
border: Border(
bottom: BorderSide(color: Colors.grey.shade200),
              ),
),
            child: InkWell(
              onTap: _showSearchRadiusModal,
              child: Row(
                children: [
                  Icon(
Icons.radar,
color: const Color(0xFFD94B4B),
size: 24,
),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Radius',
                          style: TextStyle(
fontWeight: FontWeight.w600,
fontSize: 14,
),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hospital search range',
                          style: TextStyle(
color: Colors.grey[600],
fontSize: 12,
),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
color: const Color(0xFFFEEBEB),
borderRadius: BorderRadius.circular(12),
),
                    child: Text(
                      '${searchRadius.toInt()}km',
                      style: TextStyle(
color: const Color(0xFFD94B4B),
fontWeight: FontWeight.w600,
),
                    ),
                  ),
                  Icon(
Icons.chevron_right,
color: Colors.grey[400],
),
                ],
              ),
            ),
          ),
          // Chat message list
          Expanded(
            child: ListView.builder(
              itemCount: 10, // 예시 데이터 개수
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Message $index'),
                  subtitle: Text('Details about message $index'),
                );
              },
            ),
          ),
          // Message input field
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
color: Colors.white,
border: Border(
top: BorderSide(color: Colors.grey.shade200),
              ),
),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
hintText: 'Type your message...',
border: InputBorder.none,
),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: const Color(0xFFD94B4B)),
                  onPressed: () {
                    // Message send logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}