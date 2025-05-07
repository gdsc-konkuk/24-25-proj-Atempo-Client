import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'screens/emergency_room_list_screen.dart';
import 'providers/settings_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  final String currentAddress;

  const ChatPage({
    Key? key,
    required this.currentAddress,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _addressController;
  late TextEditingController _patientConditionController;
  bool _isAddressEditable = false;
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _patientConditionFocusNode = FocusNode();
  var uuid = Uuid();
  String _sessionToken = '1234567890';
  List<dynamic> _placeList = [];
  bool _isSearching = false;

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
    _addressFocusNode.dispose();
    _patientConditionFocusNode.dispose();
    super.dispose();
  }

  // down the keyboard
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // search address dialog
  void _showAddressSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController searchController = TextEditingController();
        _placeList = [];
        _sessionToken = uuid.v4();

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Address Search',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for an address',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (query) async {
                        if (query.length > 2) {
                          setState(() {
                            _isSearching = true;
                          });
                          await _getSuggestions(query, setState);
                        } else if (query.isEmpty) {
                          setState(() {
                            _placeList = [];
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    if (_isSearching)
                      CircularProgressIndicator(color: const Color(0xFFD94B4B))
                    else
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: _placeList.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Type to search for locations'),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _placeList.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(_placeList[index]["description"]),
                                    onTap: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _addressController.text = _placeList[index]["description"];
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: const Color(0xFFD94B4B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _getSuggestions(String input, StateSetter setState) async {
    const String apiKey = "AIzaSyAw92wiRgypo3fVZ4-R5CbpB4x_Pcj1gwk";
    
    try {
      String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request = '$baseURL?input=$input&key=$apiKey&sessiontoken=$_sessionToken';
      
      // 병원 검색을 위한 파라미터 설정
      // 'establishment'은 시설을 의미하며, 여기에 키워드로 hospital을 추가
      request += '&types=establishment';
      request += '&keyword=hospital,clinic,medical,emergency';
      
      // 현재 디바이스 언어로 결과 표시 (선택적)
      // request += '&language=ko'; // 한국어 결과 - 필요 시 활성화
      
      // 위치 바이어싱을 추가하면 현재 위치 주변의 병원을 우선적으로 보여줌
      // 실제 구현 시 현재 사용자 위치를 가져와서 사용
      // request += '&location=37.5665,126.9780&radius=50000';
      
      var response = await http.get(Uri.parse(request));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 디버깅용 로그
        print('Places API response status: ${data['status']}');
        if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
          print('Places API error: ${data['error_message']}');
        }
        
        setState(() {
          _placeList = data['predictions'] ?? [];
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
        print('HTTP error: ${response.statusCode}');
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error getting place suggestions: $e');
    }
  }

  // change search radius
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '${tempRadius.toInt()}km',
                      style: TextStyle(fontSize: 16),
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
                            style: TextStyle(
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
    final searchRadius = context.watch<SettingsProvider>().searchRadius;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      // if you tap outside of the text field, the keyboard will be dismissed
      onTap: _dismissKeyboard,
      child: Scaffold(
        resizeToAvoidBottomInset: true, // when keyboard is open, the screen will be resized
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 16.0 + keyboardPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  // press the text field to edit
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_pin, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: _isAddressEditable
                              ? TextField(
                                  controller: _addressController,
                                  focusNode: _addressFocusNode,
                                  textInputAction: TextInputAction.done, 
                                  decoration: InputDecoration(
                                    hintText: 'Enter address',
                                    border: InputBorder.none,
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.check),
                                      onPressed: () {
                                        setState(() {
                                          _isAddressEditable = false;
                                        });
                                        _dismissKeyboard();
                                      },
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    setState(() {
                                      _isAddressEditable = false;
                                    });
                                  },
                                )
                              : GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isAddressEditable = true;
                                    });
                                    // Focus on the text field after a short delay
                                    Future.delayed(Duration(milliseconds: 50), () {
                                      FocusScope.of(context).requestFocus(_addressFocusNode);
                                    });
                                  },
                                  child: Text(
                                    _addressController.text,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            _dismissKeyboard();
                            _showAddressSearchDialog();
                          },
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),

                  // Search radius
                  SizedBox(height: 16),
                  InkWell(
                    onTap: _showSearchRadiusModal,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.radar,
                            color: Colors.red,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search Radius: ${searchRadius.toInt()}km',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEEBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  Text(
                    'Patient Condition',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 200, // Fixed height instead of Expanded
                    child: TextField(
                      controller: _patientConditionController,
                      focusNode: _patientConditionFocusNode,
                      maxLines: null,
                      expands: true,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
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
                        _dismissKeyboard();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EmergencyRoomListScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
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
            ),
          ),
        ),
      ),
    );
  }
}
