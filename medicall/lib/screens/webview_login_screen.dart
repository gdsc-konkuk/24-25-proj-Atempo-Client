import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'map_screen.dart';

class WebViewLoginScreen extends StatefulWidget {
  final String loginUrl;
  const WebViewLoginScreen({Key? key, required this.loginUrl}) : super(key: key);

  @override
  State<WebViewLoginScreen> createState() => _WebViewLoginScreenState();
}

class _WebViewLoginScreenState extends State<WebViewLoginScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String _statusMessage = "로그인 페이지 로딩 중...";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _statusMessage = "페이지 로딩 중...";
            });
          },
          onPageFinished: (url) async {
            setState(() {
              _isLoading = false;
              _statusMessage = "로그인을 완료해주세요";
            });
            // OAuth 콜백 URL 감지
            if (url.contains('/login/oauth2/code/')) {
              setState(() {
                _statusMessage = "로그인 성공! 토큰 처리 중...";
              });
              await _handleOAuthRedirect(url);
            }
          },
          onWebResourceError: (error) {
            debugPrint('웹뷰 오류: ${error.description}');
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  Future<void> _handleOAuthRedirect(String url) async {
    try {
      // 서버에 직접 GET 요청을 보내서 헤더에서 토큰 추출
      final response = await http.get(Uri.parse(url));
      final accessToken = response.headers['authorization'];
      final refreshToken = response.headers['x-refresh-token'];

      if (accessToken != null && refreshToken != null) {
        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'refresh_token', value: refreshToken);

        // 사용자 정보 요청 (예시)
        // final userInfo = await http.get(
        //   Uri.parse('http://avenir.my:8080/api/v1/members/me'),
        //   headers: {'Authorization': accessToken},
        // );

        // 로그인 성공 처리
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그인 성공!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MapScreen()),
          );
        }
      } else {
        setState(() {
          _statusMessage = "토큰 추출 실패";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('토큰 추출 실패'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('OAuth 리디렉션 처리 오류: $e');
      setState(() {
        _statusMessage = "로그인 처리 오류: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('구글 로그인'),
        backgroundColor: const Color(0xFFD94B4B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white70,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: const Color(0xFFD94B4B)),
                    SizedBox(height: 16),
                    Text(_statusMessage),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
