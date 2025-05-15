import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../services/http_client_service.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'emt_license_verification_screen.dart';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final storage = FlutterSecureStorage();
  
  @override
  void initState() {
    super.initState();
    // Attempt auto-login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoLogin();
    });
  }
  
  Future<void> _attemptAutoLogin() async {
    try {
      // Check for saved tokens
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      
      if (accessToken == null || refreshToken == null) {
        // Navigate to login screen if no tokens
        _navigateToLogin();
        return;
      }
      
      // Configure HTTP client if tokens exist
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      httpClient.setAuthorizationHeader('Bearer $accessToken');
      httpClient.updateRefreshToken(refreshToken);
      
      // Load user information
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUser();
      
      // Verify user authorization
      await _checkUserAuthorization();
    } catch (e) {
      print("Auto login error: $e");
      _navigateToLogin();
    }
  }
  
  Future<void> _checkUserAuthorization() async {
    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      final response = await httpClient.get('api/v1/members');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Check role
        final String? role = userData['role'];
        
        if (role == null || role.isEmpty) {
          // Navigate to license verification if no role
          _navigateToLicenseVerification();
        } else {
          // Navigate to map screen for authenticated users
          _navigateToMap();
        }
      } else {
        // Navigate to login screen if API error
        _navigateToLogin();
      }
    } catch (e) {
      print("Authorization check error: $e");
      _navigateToLogin();
    }
  }
  
  void _navigateToLogin() {
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }
  
  void _navigateToLicenseVerification() {
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmtLicenseVerificationScreen()),
        );
      }
    });
  }
  
  void _navigateToMap() {
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD94B4B),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_white.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20),
                Text(
                  'The Fastest Call for Care',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  '© 2025 Atempo, GDG on Campus Konkuk University',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
