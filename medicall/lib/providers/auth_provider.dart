import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getCurrentUser();
      _errorMessage = "Failed to load user data: ${e.toString()}";
    } catch (e) {
      _errorMessage = "Failed to load user data: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch current user info from the server
      _user = await _authService.getCurrentUser();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to load user data: ${e.toString()}";
      print('User data load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get login URL for webview
  Future<String> getLoginUrl() async {
    final baseUrl = 'http://avenir.my:8080';
    final path = '/oauth2/authorization/google';
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final route = path.startsWith('/') ? path : '/$path';
    return '$base$route';
  }

  // Complete login using OAuth authentication code
  Future<bool> completeOAuthLogin(String authCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.completeWebViewLogin(authCode);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to complete login process: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Process received authentication code from deep link
  Future<bool> handleOAuthRedirect(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.handleOAuthRedirect(code);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to process login: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Request token directly after webview login
  Future<bool> requestTokenAfterLogin(String redirectUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.requestTokenAfterLogin(redirectUrl);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to obtain token after login: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<bool> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Logout failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
