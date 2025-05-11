import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../services/http_client_service.dart';
import 'map_screen.dart';
import 'login_screen.dart';
import 'dart:convert';

class EmtLicenseVerificationScreen extends StatefulWidget {
  const EmtLicenseVerificationScreen({Key? key}) : super(key: key);

  @override
  _EmtLicenseVerificationScreenState createState() => _EmtLicenseVerificationScreenState();
}

class _EmtLicenseVerificationScreenState extends State<EmtLicenseVerificationScreen> {
  final storage = FlutterSecureStorage();
  String dropdownValue = 'NREMT';
  final TextEditingController _licenseController = TextEditingController();
  String? _errorText;
  bool _isVerifying = false;
  String? _verificationMessage;
  bool _isVerificationError = false;
  bool _isLicenseValid = false;
  
  // Define the license types and their formats
  final Map<String, String> licenseFormats = {
    'NREMT': 'Alphanumeric (e.g., GDG143, MED911)',
    'EMT(KOREA)': '6 digits (e.g 123456)',
    'EMS': '12 digits (e.g., 123456789012)',
  };
  
  @override
  void initState() {
    super.initState();
    print('EMT Screen: initState called - starting initialization');
    _licenseController.addListener(_validateInput);
    print('EMT Screen: Added license controller listener');
    _setupAuthToken();
    print('EMT Screen: Setup auth token process initiated');
    print('EMT Screen: initState called - rendering EMT License Verification Screen');
  }

  Future<void> _setupAuthToken() async {
    try {
      print('EMT Screen: Starting auth token setup');
      final keys = await storage.readAll();
      print('EMT Screen: All storage keys - ${keys.keys.join(', ')}');
      
      final accessToken = await storage.read(key: 'access_token');
      print('EMT Screen: Current access token - ${accessToken != null ? "token present" : "no token"}');
      
      if (accessToken != null) {
        // Set token for both HttpClientService and AuthProvider
        final httpClient = Provider.of<HttpClientService>(context, listen: false);
        httpClient.setAuthorizationHeader('Bearer $accessToken');
        print("EMT Screen: Auth header set on HttpClient - ${httpClient.getHeaders()}");
        
        // Update AuthProvider to check authentication status
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.loadCurrentUser();
          print('EMT Screen: AuthProvider user info loaded');
        } catch (e) {
          print('EMT Screen: Failed to load user info, continuing: $e');
        }
      } else {
        print('EMT Screen: No access token available to set auth header');
      }
    } catch (e) {
      print("EMT Screen: Error setting up auth token - $e");
    }
  }

  @override
  void dispose() {
    _licenseController.removeListener(_validateInput);
    _licenseController.dispose();
    super.dispose();
  }
  
  void _validateInput() {
    setState(() {
      _errorText = null;
      _isLicenseValid = false;
      
      if (_licenseController.text.isEmpty) {
        return;
      }
      
      // Apply different regex validation based on license type
      final String text = _licenseController.text.trim();
      RegExp regExp;
      String errorMessage = '';
      
      switch (dropdownValue) {
        case 'NREMT':
          // Allow only alphanumeric characters
          regExp = RegExp(r'^[a-zA-Z0-9]+$');
          errorMessage = 'Only letters and numbers are allowed';
          break;
        case 'EMT(KOREA)':
          // Allow only 6 digits
          regExp = RegExp(r'^\d{6}$');
          errorMessage = 'Must be exactly 6 digits';
          break;
        case 'EMS':
          // Allow only 12 digits
          regExp = RegExp(r'^\d{12}$');
          errorMessage = 'Must be exactly 12 digits';
          break;
        default:
          return; // No validation for unknown types
      }
      
      if (!regExp.hasMatch(text)) {
        _errorText = errorMessage;
      } else {
        // 추가: 특정 자격번호만 허용
        bool isValidLicense = false;
        switch (dropdownValue) {
          case 'NREMT':
            isValidLicense = text == 'GDG143' || text == 'MED911';
            break;
          case 'EMT(KOREA)':
            isValidLicense = text == '123456';
            break;
          case 'EMS':
            isValidLicense = text == '123456789012';
            break;
          default:
            isValidLicense = false;
        }
        
        if (isValidLicense) {
          _isLicenseValid = true;
        } else {
          _errorText = 'Invalid license number';
        }
      }
    });
  }
  
  String getHintText() {
    switch (dropdownValue) {
      case 'NREMT':
        return 'Enter your NREMT license number';
      case 'EMT(KOREA)':
        return 'Enter your Korean EMT license number';
      case 'EMS':
        return 'Enter your EMS license number';
      default:
        return '';
    }
  }
  
  void _onDropdownChanged(String? newValue) {
    if (newValue != null && newValue != dropdownValue) {
      setState(() {
        dropdownValue = newValue;
        _licenseController.clear();
        _errorText = null;
        _isLicenseValid = false;
      });
    }
  }
  
  // Format license number for submission
  String _formatLicenseForSubmission() {
    return _licenseController.text.trim();
  }
  
  Future<void> _verifyLicense() async {
    final formattedLicense = _formatLicenseForSubmission();
    
    print('EMT Screen: Starting license verification for $dropdownValue: $formattedLicense');
    
    if (_errorText != null || formattedLicense.isEmpty) {
      print('EMT Screen: License validation failed, not sending request');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid license number'),
          backgroundColor: Colors.red,
        )
      );
      return;
    }
    
    // Verify license number 
    bool isValidLicense = false;
    switch (dropdownValue) {
      case 'NREMT':
        isValidLicense = formattedLicense == 'GDG143' || formattedLicense == 'MED911';
        break;
      case 'EMT(KOREA)':
        isValidLicense = formattedLicense == '123456';
        break;
      case 'EMS':
        isValidLicense = formattedLicense == '123456789012';
        break;
      default:
        isValidLicense = false;
    }
    
    if (!isValidLicense) {
      print('EMT Screen: Invalid license number for $dropdownValue: $formattedLicense');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid license number. Please check and try again.'),
          backgroundColor: Colors.red,
        )
      );
      setState(() {
        _errorText = 'Invalid license number';
        _isLicenseValid = false;
      });
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _verificationMessage = null;
      _isVerificationError = false;
    });
    
    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      
      print('EMT Screen: Tokens before authentication - Access token: ${accessToken != null ? "exists" : "missing"}, Refresh token: ${refreshToken != null ? "exists" : "missing"}');
      
      if (accessToken != null) {
        httpClient.setAuthorizationHeader('Bearer $accessToken');
      }
      
      final requestBody = {
        'certification_type': dropdownValue,
        'certification_number': formattedLicense,
      };
      
      // Convert EMT(KOREA) to KOREA for server compatibility
      if (requestBody['certification_type'] == 'EMT(KOREA)') {
        requestBody['certification_type'] = 'KOREA';
      }
      
      final endpoint = 'members/certification';
      final url = httpClient.buildUrl(endpoint);
      
      print('EMT Screen: Request headers - ${httpClient.getHeaders()}');
      print('EMT Screen: Request body - $requestBody');
      print('EMT Screen: Request URL - $url');
      
      // Send license verification request to server
      final response = await httpClient.patch(
        endpoint,
        jsonEncode(requestBody),
      );
      
      print('EMT Screen: Response status code - ${response.statusCode}');
      print('EMT Screen: Response body - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update user info via AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Verify current tokens again
        final updatedAccessToken = await storage.read(key: 'access_token');
        final updatedRefreshToken = await storage.read(key: 'refresh_token');
        print('EMT Screen: Tokens after successful verification - Access token: ${updatedAccessToken != null ? "present" : "missing"}, Refresh token: ${updatedRefreshToken != null ? "present" : "missing"}');
        
        // Check for missing or expired tokens
        if (updatedAccessToken == null || updatedAccessToken.isEmpty) {
          print('EMT Screen: No access token, redirecting to login screen');
          setState(() {
            _isVerifying = false;
            _verificationMessage = 'Authentication session expired. Please login again.';
            _isVerificationError = true;
          });
          
          // Navigate to login screen after a short delay
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              print('EMT Screen: Session expired, navigating to LoginScreen');
              // Remove all screens and navigate to login
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            } else {
              print('EMT Screen: Widget not mounted, cannot navigate to LoginScreen');
            }
          });
          return;
        }
        
        // Update HttpClient
        httpClient.setAuthorizationHeader('Bearer $updatedAccessToken');
        if (updatedRefreshToken != null) {
          httpClient.updateRefreshToken(updatedRefreshToken);
        }
        
        // Reload user information
        await authProvider.loadCurrentUser();
        print('EMT Screen: User information updated successfully');
        
        setState(() {
          _isVerifying = false;
          _verificationMessage = 'License verification completed successfully.';
        });
        
        // Navigate to map screen after a short delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            print('EMT Screen: License verification successful, navigating to MapScreen');
            // Clear back stack and navigate to new MapScreen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MapScreen()),
              (route) => false,
            );
          } else {
            print('EMT Screen: Widget not mounted, cannot navigate to MapScreen');
          }
        });
      } else {
        final errorData = jsonDecode(response.body);
        print('EMT Screen: Error data - $errorData');
        setState(() {
          _isVerifying = false;
          _verificationMessage = errorData['message'] ?? 'License verification failed. Please try again.';
          _isVerificationError = true;
        });
      }
    } catch (e, stackTrace) {
      print('EMT Screen: Error during authentication - $e');
      print('EMT Screen: Stack trace - $stackTrace');
      setState(() {
        _isVerifying = false;
        _verificationMessage = 'License verification failed: $e';
        _isVerificationError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('EMT Screen: Building UI');
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Title
                Text(
                  'Enter Your',
                  style: GoogleFonts.notoSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'EMT License Number',
                  style: GoogleFonts.notoSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Subtitle
                Text(
                  'This service is only available for certified EMTs.',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                // License type dropdown and text field
                Row(
                  children: [
                    // Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DropdownButton<String>(
                          value: dropdownValue,
                          underline: Container(),
                          icon: const Icon(Icons.arrow_drop_down),
                          onChanged: _onDropdownChanged,
                          items: <String>['NREMT', 'EMT(KOREA)', 'EMS']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // License number text field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _errorText != null ? Colors.red : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _licenseController,
                          decoration: InputDecoration(
                            hintText: getHintText(),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            errorText: _errorText,
                            errorStyle: const TextStyle(
                              fontSize: 0,
                              height: 0,
                            ),
                          ),
                          // Apply appropriate input formatter based on license type
                          inputFormatters: [
                            if (dropdownValue == 'NREMT')
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            if (dropdownValue == 'EMT(KOREA)')
                              FilteringTextInputFormatter.digitsOnly,
                            if (dropdownValue == 'EMS')
                              FilteringTextInputFormatter.digitsOnly,
                          ],
                          // Add maxLength constraint for KOREA and EMS
                          maxLength: dropdownValue == 'EMT(KOREA)' 
                              ? 6 
                              : dropdownValue == 'EMS' 
                                ? 12 
                                : null,
                          // Hide counter text for a cleaner UI
                          buildCounter: (
                            BuildContext context, {
                            required int currentLength,
                            required bool isFocused,
                            required int? maxLength,
                          }) => null,
                          onChanged: (text) => _validateInput(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                    child: Text(
                      _errorText!,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // License format hint
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Format: ${licenseFormats[dropdownValue]}',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (_verificationMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                    child: Text(
                      _verificationMessage!,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: _isVerificationError ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 120),
                // "Don't know your license number?" link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // No functionality as requested
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't know your license number? ",
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          TextSpan(
                            text: 'Learn more',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isVerifying || !_isLicenseValid || _licenseController.text.isEmpty) 
                      ? null 
                      : _verifyLicense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD94B4B),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isVerifying
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                        'Verify License',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom formatter to convert all text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}