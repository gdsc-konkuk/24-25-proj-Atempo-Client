import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/user_model.dart';

class OAuthLoginWebview extends StatefulWidget {
  final OAuthLoginResult loginResult;
  final Function(User) onLoginSuccess;
  final Function(String) onLoginError;

  const OAuthLoginWebview({
    Key? key,
    required this.loginResult,
    required this.onLoginSuccess,
    required this.onLoginError,
  }) : super(key: key);

  @override
  _OAuthLoginWebviewState createState() => _OAuthLoginWebviewState();
}

class _OAuthLoginWebviewState extends State<OAuthLoginWebview> {
  late final WebViewController _controller;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    // 웹뷰 컨트롤러 초기화
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            debugPrint('페이지 로딩 시작: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            debugPrint('페이지 로딩 완료: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            // OAuth 콜백 URL 감지
            if (request.url.contains('/oauth2/redirect') || 
                request.url.contains('/login/oauth2/code/')) {
              debugPrint('OAuth 리디렉션 감지: ${request.url}');
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('웹뷰 오류: ${error.description}');
            widget.onLoginError('웹뷰 오류: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginResult.loginUrl));
  }

  Future<void> _handleRedirect(String url) async {
    try {
      // 여기서는 리디렉션 URL에서 쿼리 파라미터나 경로에서 필요한 정보를 추출합니다
      // 이 부분은 백엔드 구현에 따라 다를 수 있습니다
      
      // 예: ?token=xxx&refreshToken=yyy 형태의 쿼리 파라미터
      final uri = Uri.parse(url);
      final Map<String, dynamic> authData = {};
      
      uri.queryParameters.forEach((key, value) {
        authData[key] = value;
      });
      
      // 토큰이 없는 경우 (백엔드에서 다른 방식으로 전달할 수 있음)
      if (!authData.containsKey('accessToken')) {
        // 여기서는 페이지 내용에서 데이터를 추출하는 자바스크립트를 실행할 수 있습니다
        final String? pageContent = await _controller.runJavaScriptReturningResult(
          'document.body.innerText'
        ) as String?;
        
        if (pageContent != null && pageContent.isNotEmpty) {
          try {
            // 페이지가 JSON 형태로 데이터를 제공하는 경우
            final jsonData = json.decode(pageContent);
            authData.addAll(jsonData);
          } catch (e) {
            debugPrint('페이지 내용 파싱 실패: $e');
          }
        }
      }
      
      // 필요한 데이터가 있는지 확인
      if (authData.containsKey('accessToken') && authData.containsKey('refreshToken')) {
        // 로그인 성공 처리
        final user = await widget.loginResult.onLoginSuccess(authData);
        widget.onLoginSuccess(user);
        Navigator.of(context).pop(); // 웹뷰 닫기
      } else {
        debugPrint('인증 데이터가 없습니다: $authData');
        widget.onLoginError('인증 데이터 추출 실패');
      }
    } catch (e) {
      debugPrint('리디렉션 처리 오류: $e');
      widget.onLoginError('리디렉션 처리 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google 로그인'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
