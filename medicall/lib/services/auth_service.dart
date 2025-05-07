import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080';
  
  // API 엔드포인트 상수
  static const String _AUTH_TOKEN_PATH = '/api/v1/auth/token';
  static const String _AUTH_ACCESS_TOKEN_PATH = '/api/v1/auth/access-token';
  static const String _USER_INFO_PATH = '/api/v1/members';
  
  // URL 정규화 헬퍼 메서드
  String _normalizeUrl(String baseUrl, String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final endpoint = path.startsWith('/') ? path : '/$path';
    return '$base$endpoint';
  }

  // OAuth login URL for WebView
  Future<String> getLoginUrl() async {
    // Return direct OAuth URL to prevent redirect loop
    final loginUrl = '$_baseUrl/oauth2/authorization/google';
    debugPrint('Login URL: $loginUrl');
    return loginUrl;
  }

  // Handle WebView login with auth code
  Future<User> completeWebViewLogin(String authCode) async {
    try {
      // Request token using auth code
      final tokenResponse = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': authCode}),
      );
      
      if (tokenResponse.statusCode != 200) {
        throw Exception('Token request failed: ${tokenResponse.statusCode}, ${tokenResponse.body}');
      }
      
      // Parse token info
      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['accessToken'];
      final refreshToken = tokenData['refreshToken'];
      
      // Save tokens
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      // Request user info with access token
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/api/v1/members/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      if (userResponse.statusCode != 200) {
        throw Exception('User info request failed: ${userResponse.statusCode}, ${userResponse.body}');
      }
      
      // Parse user info
      final userData = jsonDecode(userResponse.body);
      
      // Save user ID
      await _storage.write(key: 'user_id', value: userData['id'].toString());
      
      return User(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['profile_url'],
        accessToken: accessToken,
        role: userData['role'],
        nickName: userData['nick_name'],
        certificationType: userData['certification_type'],
        certificationNumber: userData['certification_number'],
      );
    } catch (e) {
      debugPrint('Login completion error: $e');
      rethrow;
    }
  }
  
  // Request token directly after successful login
  Future<User> requestTokenAfterLogin(String redirectUrl) async {
    try {
      // Send success page URL to server for token request
      final tokenResponse = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/token-after-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'redirectUrl': redirectUrl}),
      );
      
      if (tokenResponse.statusCode != 200) {
        throw Exception('Token request failed: ${tokenResponse.statusCode}');
      }
      
      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['accessToken'];
      final refreshToken = tokenData['refreshToken'];
      
      // Save tokens
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      // Request user info
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/api/v1/members/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      if (userResponse.statusCode != 200) {
        throw Exception('User info request failed: ${userResponse.statusCode}');
      }
      
      final userData = jsonDecode(userResponse.body);
      await _storage.write(key: 'user_id', value: userData['id'].toString());
      
      return User(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['profile_url'],
        accessToken: accessToken,
        role: userData['role'],
        nickName: userData['nick_name'],
        certificationType: userData['certification_type'],
        certificationNumber: userData['certification_number'],
      );
    } catch (e) {
      debugPrint('Token request after login error: $e');
      rethrow;
    }
  }
  
  // Deep link login handling (code transfer)
  Future<User> handleOAuthRedirect(String code) async {
    try {
      // Request token using auth code
      final tokenResponse = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );
      
      if (tokenResponse.statusCode != 200) {
        throw Exception('Token request failed: ${tokenResponse.statusCode}, ${tokenResponse.body}');
      }
      
      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['accessToken'];
      final refreshToken = tokenData['refreshToken'];
      
      // Save tokens
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      
      // Request user info
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/api/v1/members/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      if (userResponse.statusCode != 200) {
        throw Exception('User info request failed: ${userResponse.statusCode}');
      }
      
      final userData = jsonDecode(userResponse.body);
      await _storage.write(key: 'user_id', value: userData['id'].toString());
      
      return User(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['profile_url'],
        accessToken: accessToken,
        role: userData['role'],
        nickName: userData['nick_name'],
        certificationType: userData['certification_type'],
        certificationNumber: userData['certification_number'],
      );
    } catch (e) {
      debugPrint('OAuth redirect handling error: $e');
      rethrow;
    }
  }
  
  // Refresh access token
  Future<String> refreshAccessToken() async {
    try {
      print('AuthService: 액세스 토큰 갱신 시작');
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('AuthService: 리프레시 토큰 없음');
        throw Exception('Refresh token is missing');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      };
      
      // URL 정규화 및 엔드포인트 상수 사용
      final url = _normalizeUrl(_baseUrl, _AUTH_ACCESS_TOKEN_PATH);
      print('AuthService: 토큰 갱신 요청 URL - $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );
      
      print('AuthService: 토큰 갱신 응답 상태 코드 - ${response.statusCode}');
      print('AuthService: 토큰 갱신 응답 헤더 - ${response.headers}');
      
      if (response.statusCode == 200) {
        // 헤더에서 액세스 토큰 추출
        final newAccessToken = response.headers['authorization'];
        
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          final token = newAccessToken.startsWith('Bearer ') 
              ? newAccessToken.substring(7) 
              : newAccessToken;
          
          await _storage.write(key: 'access_token', value: token);
          return token;
        }
        
        // 헤더에 토큰이 없는 경우
        final currentToken = await _storage.read(key: 'access_token') ?? '';
        return currentToken;
      } else {
        throw Exception('Access token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Access token refresh error: $e');
      // 오류 발생 시 현재 토큰 반환
      final currentToken = await _storage.read(key: 'access_token') ?? '';
      return currentToken;
    }
  }
  
  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    print('AuthService: getCurrentUser 호출됨');
    final accessToken = await _storage.read(key: 'access_token');
    
    if (accessToken == null) {
      print('AuthService: 액세스 토큰 없음');
      return null;
    }
    
    print('AuthService: 액세스 토큰으로 사용자 정보 요청');
    try {
      final url = _normalizeUrl(_baseUrl, _USER_INFO_PATH);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      print('AuthService: 사용자 정보 응답 상태 코드 - ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('AuthService: 사용자 정보 로드 성공');
        
        return User(
          id: userData['id']?.toString() ?? '',
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          photoUrl: userData['profile_url'],
          accessToken: accessToken,
          role: userData['role'],
          nickName: userData['nick_name'],
          certificationType: userData['certification_type'],
          certificationNumber: userData['certification_number'],
        );
      } else if (response.statusCode == 401) {
        print('AuthService: 토큰 만료, 갱신 시도');
        // 토큰 갱신 시도
        try {
          final newToken = await refreshAccessToken();
          if (newToken.isNotEmpty) {
            // 새 토큰으로 다시 시도
            print('AuthService: 토큰 갱신 성공, 다시 시도');
            final retryUrl = _normalizeUrl(_baseUrl, _USER_INFO_PATH);
            final retryResponse = await http.get(
              Uri.parse(retryUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newToken',
              },
            );
            
            if (retryResponse.statusCode == 200) {
              final userData = jsonDecode(retryResponse.body);
              print('AuthService: 재시도 성공');
              return User(
                id: userData['id']?.toString() ?? '',
                email: userData['email'] ?? '',
                name: userData['name'] ?? '',
                photoUrl: userData['profile_url'],
                accessToken: newToken,
                role: userData['role'],
                nickName: userData['nick_name'],
                certificationType: userData['certification_type'],
                certificationNumber: userData['certification_number'],
              );
            } else {
              print('AuthService: 재시도 실패 - ${retryResponse.statusCode}, ${retryResponse.body}');
            }
          }
        } catch (refreshError) {
          print('AuthService: 토큰 갱신 오류 - $refreshError');
        }
        
        return null;
      } else {
        debugPrint('Failed to fetch user info: ${response.statusCode}, ${response.body}');
        print('AuthService: 사용자 정보 요청 실패');
        return null;
      }
    } catch (e) {
      print('AuthService: 사용자 정보 요청 중 예외 발생 - $e');
      return null;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken != null) {
        // Send logout request to server
        try {
          await http.post(
            Uri.parse('$_baseUrl/api/v1/auth/logout'),
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          );
        } catch (e) {
          debugPrint('Server logout request error (can be ignored): $e');
        }
      }
      
      // Delete local tokens
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }
}
