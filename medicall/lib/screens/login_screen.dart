import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 추가: dotenv 패키지 import
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../services/http_client_service.dart';
import 'signup_screen.dart';
import 'map_screen.dart';
import 'webview_login_screen.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  final String? code; // 딥링크로 전달받은 인증 코드
  
  const LoginScreen({Key? key, this.code}) : super(key: key);
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final storage = FlutterSecureStorage();
  String? _refreshToken;
  bool _processingDeepLink = false;
  
  @override
  void initState() {
    super.initState();
    
    // 딥링크로 전달받은 인증 코드가 있는 경우 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processDeepLinkIfPresent();
    });
  }
  
  // 딥링크 처리
  Future<void> _processDeepLinkIfPresent() async {
    if (widget.code != null && !_processingDeepLink) {
      setState(() {
        _processingDeepLink = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        final success = await authProvider.handleOAuthRedirect(widget.code!);
        
        if (success) {
          // 로그인 성공 메시지
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('로그인이 완료되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
            
            // 메인 화면으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? '로그인 처리 중 오류가 발생했습니다'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 처리 중 오류: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _processingDeepLink = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // AuthProvider 인스턴스 가져오기
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // Logo
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.notoSans(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'Medi'),
                        WidgetSpan(
                          child: Transform.translate(
                            offset: Offset(0, -2),
                            child: Icon(Icons.call, color: const Color(0xFFD94B4B), size: 32),
                          ),
                          alignment: PlaceholderAlignment.middle,
                        ),
                        TextSpan(text: 'all'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    "Find the right ER, right now.",
                    style: GoogleFonts.notoSans(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                // Ambulance image 
                Center(
                  child: Container(
                    height: 240,
                    child: Image.asset(
                      'assets/images/ambulance.png', // Updated to use the new ambulance image
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                // Login Section
                Text(
                  "Login",
                  style: GoogleFonts.notoSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // Navigate to signup with custom animation
                    Navigator.of(context).push(_createRoute());
                  },
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: const Color(0xFF323232),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Google Login Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          try {
                            final loginUrl = await authProvider.getLoginUrl();
                            
                            if (context.mounted) {
                              // WebView 로그인 화면으로 이동
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => WebViewLoginScreen(
                                    loginUrl: loginUrl,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("로그인 초기화 오류: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: authProvider.isLoading
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
                            SizedBox(width: 10),
                            Text(
                              "Continue with Google",
                              style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom route for animated transition
  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SignUpScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Animation<double> sizeAnimation = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
            
        return Stack(
          children: [
            PositionedTransition(
              rect: RelativeRectTween(
                begin: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width, 
                  MediaQuery.of(context).size.height, 
                  0, 
                  0
                ),
                end: RelativeRect.fill,
              ).animate(animation),
              child: Container(color: const Color(0xFFD94B4B)),
            ),
            ScaleTransition(
              scale: sizeAnimation,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ],
        );
      },
    );
  }
}
