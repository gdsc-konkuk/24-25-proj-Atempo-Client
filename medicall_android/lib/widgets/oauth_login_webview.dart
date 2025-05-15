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
    
    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            debugPrint('Page loading started: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            debugPrint('Page loading completed: $url');
          },
          onNavigationRequest: (NavigationRequest request) {
            // OAuth callback URL detection
            if (request.url.contains('/oauth2/redirect') || 
                request.url.contains('/login/oauth2/code/')) {
              debugPrint('OAuth redirection detected: ${request.url}');
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            widget.onLoginError('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginResult.loginUrl));
  }

  Future<void> _handleRedirect(String url) async {
    try {
      // Extract necessary information from the redirect URL query parameters or path
      // This part may vary depending on the backend implementation
      
      // Example: Query parameters in the form ?token=xxx&refreshToken=yyy
      final uri = Uri.parse(url);
      final Map<String, dynamic> authData = {};
      
      uri.queryParameters.forEach((key, value) {
        authData[key] = value;
      });
      
      // If tokens are not in the URL (backend may deliver them differently)
      if (!authData.containsKey('accessToken')) {
        // Here we can execute JavaScript to extract data from the page content
        final String? pageContent = await _controller.runJavaScriptReturningResult(
          'document.body.innerText'
        ) as String?;
        
        if (pageContent != null && pageContent.isNotEmpty) {
          try {
            // If the page provides data in JSON format
            final jsonData = json.decode(pageContent);
            authData.addAll(jsonData);
          } catch (e) {
            debugPrint('Failed to parse page content: $e');
          }
        }
      }
      
      // Check if the necessary data is available
      if (authData.containsKey('accessToken') && authData.containsKey('refreshToken')) {
        // Process successful login
        final user = await widget.loginResult.onLoginSuccess(authData);
        widget.onLoginSuccess(user);
        Navigator.of(context).pop(); // Close WebView
      } else {
        debugPrint('No authentication data: $authData');
        widget.onLoginError('Failed to extract authentication data');
      }
    } catch (e) {
      debugPrint('Redirect handling error: $e');
      widget.onLoginError('Redirect handling error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Login'),
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
