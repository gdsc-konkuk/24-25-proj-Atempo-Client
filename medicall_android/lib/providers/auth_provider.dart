import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  User? get currentUser => _user;
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
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('AuthProvider: Loading user information');
      _user = await _authService.getCurrentUser();
      
      if (_user != null) {
        print('AuthProvider: User information loaded successfully - Name: ${_user!.name}, Email: ${_user!.email}, Role: ${_user!.role}, Certification: ${_user!.certificationType}');
      } else {
        print('AuthProvider: Could not retrieve user information');
      }
      
      _errorMessage = null;
    } catch (e) {
      print('AuthProvider: Failed to load user information - $e');
      _errorMessage = 'User: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getLoginUrl() async {
    // Fix URL construction to avoid double slashes
    final baseUrl = dotenv.env['API_BASE_URL']!;
    final path = '/oauth2/authorization/google';
    
    // Ensure there's exactly one slash between baseUrl and path
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final route = path.startsWith('/') ? path : '/$path';
    
    return '$base$route';
  }

  // OAuth
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
      _errorMessage = 'Login Failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // OAuth redirection
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
      _errorMessage = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Request token after login
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
      _errorMessage = 'Token Failed: ${e.toString()}';
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
      _errorMessage = 'Logout failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}