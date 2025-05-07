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
    // 자동 로그인 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoLogin();
    });
  }
  
  Future<void> _attemptAutoLogin() async {
    try {
      // 저장된 토큰 확인
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      
      if (accessToken == null || refreshToken == null) {
        // 토큰이 없으면 로그인 화면으로 이동
        _navigateToLogin();
        return;
      }
      
      // 토큰이 있으면 HTTP 클라이언트 설정
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      httpClient.setAuthorizationHeader('Bearer $accessToken');
      httpClient.updateRefreshToken(refreshToken);
      
      // 사용자 정보 로드
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUser();
      
      // 사용자 권한 확인
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
        
        // role 확인 (certificationType 체크 제거)
        final String? role = userData['role'];
        
        if (role == null || role.isEmpty) {
          // 역할이 없으면 자격증 인증 화면으로
          _navigateToLicenseVerification();
        } else {
          // 로그인된 사용자는 지도 화면으로 이동 (certification 체크 제거)
          _navigateToMap();
        }
      } else {
        // API 오류 시 로그인 화면으로
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with phone icon replacing "i"
            RichText(
              text: TextSpan(
                style: GoogleFonts.notoSans(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: 'Medi'),
                  WidgetSpan(
                    child: Icon(Icons.phone, color: Colors.white, size: 40),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  TextSpan(text: 'call'),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'The Fastest Call for Care',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
