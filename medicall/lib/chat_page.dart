import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'screens/emergency_room_list_screen.dart';
import 'providers/settings_provider.dart';

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
        List<String> searchResults = [];
        bool isSearching = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '주소 검색',
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
                      onSubmitted: (query) async {
                        setState(() {
                          isSearching = true;
                        });

                        try {
                          // 주소 검색 - Geocoding API 사용
                          List<Location> locations = await locationFromAddress(query);
                          List<String> addresses = [];

                          for (var location in locations) {
                            List<Placemark> placemarks = await placemarkFromCoordinates(
                              location.latitude,
                              location.longitude,
                            );

                            if (placemarks.isNotEmpty) {
                              Placemark place = placemarks.first;
                              String address =
                                  "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
                              addresses.add(address);
                            }
                          }

                          setState(() {
                            searchResults = addresses;
                            isSearching = false;
                          });
                        } catch (e) {
                          setState(() {
                            searchResults = ["The address could not be found."];
                            isSearching = false;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    if (isSearching)
                      CircularProgressIndicator(color: const Color(0xFFD94B4B))
                    else
                      Container(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(searchResults[index]),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _addressController.text = searchResults[index];
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
                        '취소',
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
        body: SingleChildScrollView(
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
    );
  }
}
