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
  // 검색 반경 설정 모달 표시
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
    // SettingsProvider로부터 검색 반경 값 가져오기
    final searchRadius = context.watch<SettingsProvider>().searchRadius;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: const Color(0xFFD94B4B),
      ),
      body: Column(
        children: [
          // 현재 위치 표시 부분
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
          
          // 현재 위치 아래에 검색 반경 설정 추가
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
          
          // 채팅 메시지 목록
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
          
          // 메시지 입력 필드
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
                    // 메시지 전송 로직
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