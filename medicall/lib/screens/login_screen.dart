import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../services/http_client_service.dart';
import 'signup_screen.dart';
import 'map_screen.dart';
import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  final String? code; // 딥링크로 전달받은 인증 코드

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
        _statusMessage = "로그인 처리 중...";
      });
      _handleOAuthCode(widget.code!);
    } else {
      // If no code was passed, check initial link (cold start deep link)
      _checkInitialLink();
    }
  }

  Future<void> _checkInitialLink() async {
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      final uri = Uri.parse(initialLink);
      // 먼저 atk, rtk 파라미터 체크
      final atk = uri.queryParameters['atk'];
      final rtk = uri.queryParameters['rtk'];
      if (atk != null && rtk != null) {
        setState(() {
          _isLoading = true;
          _statusMessage = "토큰 처리 중...";
        });
        await _handleOAuthTokens(atk, rtk);
      } else {
        final code = uri.queryParameters['code'];
        if (code != null) {
          setState(() {
            _isLoading = true;
            _statusMessage = "로그인 처리 중...";
          });
          await _handleOAuthCode(code);
        }
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
        // 먼저 atk, rtk 파라미터 체크
        final atk = uri.queryParameters['atk'];
        final rtk = uri.queryParameters['rtk'];
        if (atk != null && rtk != null && !_processingDeepLink) {
          _processingDeepLink = true;
          if (mounted) {
            setState(() {
              _isLoading = true;
              _statusMessage = "토큰 처리 중...";
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
              _statusMessage = "로그인 처리 중...";
            });
          }
          await _handleOAuthCode(code);
          _processingDeepLink = false;
        }
      }
    }, onError: (err) {
      if (mounted) {
        setState(() {
          _statusMessage = "딥링크 오류: $err";
        });
      }
    });
  }

  Future<void> _handleOAuthTokens(String atk, String rtk) async {
    try {
      // 토큰 저장
      await storage.write(key: 'access_token', value: atk);
      await storage.write(key: 'refresh_token', value: rtk);
      
      // 명시적으로 HttpClientService 인스턴스 초기화
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      httpClient.setAuthorizationHeader('Bearer $atk');
      httpClient.updateRefreshToken(rtk);
      
      // 로그로 헤더 확인
      print("Auth header set: ${httpClient.getHeaders()}");
      
      // Provider에 사용자 정보 갱신 요청 (토큰 기반 인가)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadCurrentUser();

      _sub?.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MapScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "토큰 처리 오류: $e";
        });
      }
    }
  }

  Future<void> _handleOAuthCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('http://avenir.my:8080/api/v1/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: '{"code":"$code"}',
      );
      
      print("Token response status: ${response.statusCode}");
      print("Token response body: ${response.body}");
      
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage =
                "토큰 요청 실패: ${response.statusCode} ${response.body}";
          });
        }
        return;
      }

      final Map<String, dynamic> tokenData = jsonDecode(response.body);
      final accessToken = tokenData['accessToken'];
      final refreshToken = tokenData['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        // 토큰 저장
        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'refresh_token', value: refreshToken);

        // JWT 토큰을 HTTP 클라이언트에 설정
        final httpClient = Provider.of<HttpClientService>(context, listen: false);
        httpClient.setAuthorizationHeader('Bearer $accessToken');
        httpClient.updateRefreshToken(refreshToken);
        
        // 로그로 헤더 확인
        print("Auth header set: ${httpClient.getHeaders()}");

        // Provider에 사용자 정보 갱신 요청 (토큰 기반 인가)
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.loadCurrentUser();

        _sub?.cancel();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // 화면이 이미 이동했는지 체크 후 이동
          if (ModalRoute.of(context)?.isCurrent ?? true) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MapScreen()),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = "토큰 추출 실패(응답 형식 확인 필요)";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "로그인 처리 오류: $e";
        });
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
          _statusMessage = "로그인 페이지를 열 수 없습니다.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "로그인 초기화 오류: $e";
      });
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
                Center(
                  child: Container(
                    height: 240,
                    child: Image.asset(
                      'assets/images/ambulance.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 60),
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
                if (_statusMessage.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Center(child: Text(_statusMessage, style: TextStyle(color: Colors.red))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                  0,
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
