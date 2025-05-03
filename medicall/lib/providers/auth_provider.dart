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
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    // 토큰이 있으면 서버에서 유저 정보 조회 후 상태 갱신
    // 예시: await AuthService().getCurrentUser();
    // notifyListeners();
  }

  // 웹뷰에서 사용할 로그인 URL 가져오기
  Future<String> getLoginUrl() async {
    // Fix URL construction to avoid double slashes
    final baseUrl = 'http://avenir.my:8080';
    final path = '/oauth2/authorization/google';
    
    // Ensure there's exactly one slash between baseUrl and path
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final route = path.startsWith('/') ? path : '/$path';
    
    return '$base$route';
  }

  // OAuth 인증 코드로 로그인 완료하기
  Future<bool> completeOAuthLogin(String authCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 인증 코드로 로그인 완료하기
      _user = await _authService.completeWebViewLogin(authCode);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '로그인 완료 처리 실패: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 딥링크로 받은 인증 코드 처리
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
      _errorMessage = '로그인 처리 실패: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 웹뷰 로그인 성공 후 토큰 직접 요청
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
      _errorMessage = '로그인 후 토큰 획득 실패: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 로그아웃
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
      _errorMessage = '로그아웃 실패: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
