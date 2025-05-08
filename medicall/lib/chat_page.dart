import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'screens/emergency_room_list_screen.dart';
import 'providers/settings_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  bool _isLoading = false;
  final String _apiUrl = 'http://avenir.my:8080/api/v1/admissions';

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

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

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
      
      request += '&types=establishment';
      request += '&keyword=hospital,clinic,medical,emergency';
      
      var response = await http.get(Uri.parse(request));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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

  Future<List<dynamic>> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting hospital search...');
      
      print('1. Converting address to coordinates: ${_addressController.text}');
      List<Location> locations = await locationFromAddress(_addressController.text);
      if (locations.isEmpty) {
        print('ERROR: Unable to retrieve location information.');
        throw Exception('위치 정보를 가져올 수 없습니다.');
      }

      Location location = locations.first;
      print('Success: Coordinates conversion complete: latitude=${location.latitude}, longitude=${location.longitude}');
      
      final searchRadius = context.read<SettingsProvider>().searchRadius.toInt();
      final patientCondition = _patientConditionController.text;
      print('Search parameters: radius=${searchRadius}km, patient condition=${patientCondition}');

      // 토큰을 직접 가져오도록 수정
      print('2. Retrieving authentication token...');
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        print('ERROR: No authentication token found.');
        throw Exception('로그인이 필요합니다.');
      }
      print('Success: Authentication token verified');

      final requestBody = jsonEncode({
        "location": {
          "latitude": location.latitude,
          "longitude": location.longitude
        },
        "search_radius": searchRadius,
        "patient_condition": patientCondition
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };

      print('3. API request preparation');
      print('API URL: $_apiUrl');
      print('Request headers: ${headers.toString()}');
      print('Request body: $requestBody');

      print('4. Sending request to server...');
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: requestBody,
      );

      print('5. Server response received');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hospitals = data['hospitals'] ?? [];
        print('Success: Retrieved ${hospitals.length} hospitals');
        return hospitals;
      } else {
        print('ERROR: Server error: ${response.statusCode}');
        print('ERROR: Response content: ${response.body}');
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Exception while requesting hospital information: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('병원 정보를 가져오는 중 오류가 발생했습니다: $e'))
      );
      return [];
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('Hospital search process completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchRadius = context.watch<SettingsProvider>().searchRadius;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                    height: 200,
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
                    child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.red))
                      : ElevatedButton(
                          onPressed: () async {
                            _dismissKeyboard();
                            final hospitals = await _fetchHospitals();
                            if (hospitals.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmergencyRoomListScreen(
                                    hospitals: hospitals,
                                  ),
                                ),
                              );
                            }
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
