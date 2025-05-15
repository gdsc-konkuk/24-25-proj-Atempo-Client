import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../services/http_client_service.dart';
import 'map_screen.dart';
import 'emt_license_verification_screen.dart'; // Import EMT license screen
import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  final String? code; // Authentication code received via deep link

  const LoginScreen({Key? key, this.code}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final storage = FlutterSecureStorage();
  bool _processingDeepLink = false;
  StreamSubscription? _sub;
  bool _isLoading = false;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _listenDeepLink();
    // Process code if provided via constructor
    if (widget.code != null) {
      setState(() {
        _isLoading = true;
        _statusMessage = "Processing login...";
      });
      _handleOAuthCode(widget.code!);
    } else {
      // If no code was passed, check for initial deep link
      _checkInitialLink();
    }
  }

  Future<void> _checkInitialLink() async {
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      print('Initial deep link detected: $initialLink');
      try {
        final uri = Uri.parse(initialLink);
        print('Parsed URI: $uri');
        print('URI query parameters: ${uri.queryParameters}');
        
        // First check for atk, rtk parameters
        final atk = uri.queryParameters['atk'];
        final rtk = uri.queryParameters['rtk'];
        print('Parameter check: atk=${atk != null}, rtk=${rtk != null}');
        
        if (atk != null && rtk != null) {
          setState(() {
            _isLoading = true;
            _statusMessage = "Processing tokens...";
          });
          await _handleOAuthTokens(atk, rtk);
        } else {
          final code = uri.queryParameters['code'];
          print('Authentication code: $code');
          if (code != null) {
            setState(() {
              _isLoading = true;
              _statusMessage = "Processing login...";
            });
            await _handleOAuthCode(code);
          } else {
            print('No recognizable authentication parameters: $initialLink');
          }
        }
      } catch (e) {
        print('Deep link parsing error: $e');
        setState(() {
          _statusMessage = "Deep link processing error: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenDeepLink() {
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        // First check for atk, rtk parameters
        final atk = uri.queryParameters['atk'];
        final rtk = uri.queryParameters['rtk'];
        if (atk != null && rtk != null && !_processingDeepLink) {
          _processingDeepLink = true;
          if (mounted) {
            setState(() {
              _isLoading = true;
              _statusMessage = "Processing tokens...";
            });
          }
          await _handleOAuthTokens(atk, rtk);
          _processingDeepLink = false;
        } else if (uri.queryParameters['code'] != null && !_processingDeepLink) {
          _processingDeepLink = true;
          final code = uri.queryParameters['code']!;
          if (mounted) {
            setState(() {
              _isLoading = true;
              _statusMessage = "Processing login...";
            });
          }
          await _handleOAuthCode(code);
          _processingDeepLink = false;
        }
      }
    }, onError: (err) {
      if (mounted) {
        setState(() {
          _statusMessage = "Deep link error: $err";
        });
      }
    });
  }

  Future<void> _handleOAuthTokens(String atk, String rtk) async {
    try {
      // Save tokens
      await storage.write(key: 'access_token', value: atk);
      await storage.write(key: 'refresh_token', value: rtk);

      // Set tokens to HTTP client service
      try {
        final httpClient = Provider.of<HttpClientService>(context, listen: false);
        httpClient.setAuthorizationHeader('Bearer $atk');
        httpClient.updateRefreshToken(rtk);
        print("Auth header set: ${httpClient.getHeaders()}");
      } catch (providerError) {
        print("Provider error: $providerError");
      }

      // Update user data via AuthProvider
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUser();
        
        // Check user's certification status
        final user = authProvider.currentUser;
        if (user != null && user.certificationType != null && user.certificationType!.isNotEmpty) {
          // Already certified user - Navigate to MapScreen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          }
        } else {
          // Uncertified user - Navigate to EmtLicenseVerificationScreen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => EmtLicenseVerificationScreen()),
            );
          }
        }
      } catch (authProviderError) {
        print("AuthProvider error: $authProviderError");
      }

      _sub?.cancel();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Token processing error: $e";
        });
      }
    }
  }

  Future<void> _handleOAuthCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']!}/api/v1/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        // Save tokens
        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'refresh_token', value: refreshToken);

        // Load user information
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUser();
        
        // Check user's certification status
        final user = authProvider.currentUser;
        if (user != null && user.certificationType != null && user.certificationType!.isNotEmpty) {
          // Already certified user - Navigate to MapScreen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          }
        } else {
          // Uncertified user - Navigate to EmtLicenseVerificationScreen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => EmtLicenseVerificationScreen()),
            );
          }
        }
      } else {
        throw Exception('Failed to get token');
      }
    } catch (e) {
      print('Error during OAuth code handling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  // Method to fetch user info and navigate accordingly
  Future<void> _fetchUserInfoAndNavigate() async {
    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      final response = await httpClient.get('api/v1/members');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print("User data: $userData");
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Check if role exists
          final String? role = userData['role'];
          
          if (role == null || role.isEmpty) {
            // Navigate to EMT license verification if no role
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => EmtLicenseVerificationScreen()),
              (route) => false,
            );
          } else {
            // Navigate to main map screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MapScreen()),
              (route) => false,
            );
          }
        }
      } else {
        print("Failed to fetch user info: ${response.statusCode} ${response.body}");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = "Failed to fetch user info";
          });
          
          // Default to EMT license verification screen on error
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => EmtLicenseVerificationScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("Error fetching user info: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Error fetching user info: $e";
        });
        
        // Default to EMT license verification screen on error
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => EmtLicenseVerificationScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _launchOAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final loginUrl = await authProvider.getLoginUrl();
      final url = Uri.parse(loginUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _statusMessage = "Unable to open login page.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Login initialization error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions to position elements correctly
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Top logo and tagline - fixed at top
            Padding(
              padding: EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo_color.png',
                    width: 150,
                    fit: BoxFit.contain,
                    color: Colors.black,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Find the right ER, right now.",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            
            // Ambulance image in the center
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/ambulance.png',
                  width: 250, // Make the image larger
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            // Login section at bottom
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 40), // Bottom padding to keep it off the very bottom
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Welcome to MediCall",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Pretendard',
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "We only use your account for identity verification. Your data is safe.",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 1,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      minimumSize: Size(double.infinity, 56),
                    ),
                    onPressed: _isLoading ? null : _launchOAuth,
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: const Color(0xFFD94B4B)),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                height: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (_statusMessage.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Center(child: Text(_statusMessage, style: TextStyle(color: Colors.red))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
