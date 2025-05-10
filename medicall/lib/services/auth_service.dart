import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _baseUrl = dotenv.env['API_BASE_URL'];
  
  // API endpoint constants
  final String _AUTH_TOKEN_PATH = '/api/v1/auth/token';
  final String _AUTH_ACCESS_TOKEN_PATH = '/api/v1/auth/access-token';
  final String _USER_INFO_PATH = '/api/v1/members';
  final String _USER_ME_PATH = '/api/v1/members/me';
  final String _OAUTH_AUTH_PATH = '/oauth2/authorization/google';
  final String _AUTH_LOGOUT_PATH = '/api/v1/auth/logout';
  final String _AUTH_TOKEN_AFTER_LOGIN_PATH = '/api/v1/auth/token-after-login';
  
  // URL normalization helper method
  String _normalizeUrl(String baseUrl, String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final endpoint = path.startsWith('/') ? path : '/$path';
    return '$base$endpoint';
  }

  // OAuth login URL for WebView
  Future<String> getLoginUrl() async {
    // Return direct OAuth URL to prevent redirect loop
    final loginUrl = _normalizeUrl(_baseUrl, _OAUTH_AUTH_PATH);
    debugPrint('Login URL: $loginUrl');
    return loginUrl;
  }

  // Handle WebView login with auth code
  Future<User> completeWebViewLogin(String authCode) async {
    try {
      // Request token using auth code
      final tokenUrl = _normalizeUrl(_baseUrl, _AUTH_TOKEN_PATH);
      final tokenResponse = await http.post(
        Uri.parse(tokenUrl),
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
      final userUrl = _normalizeUrl(_baseUrl, _USER_ME_PATH);
      final userResponse = await http.get(
        Uri.parse(userUrl),
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
      final tokenUrl = _normalizeUrl(_baseUrl, _AUTH_TOKEN_AFTER_LOGIN_PATH);
      final tokenResponse = await http.post(
        Uri.parse(tokenUrl),
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
      final userUrl = _normalizeUrl(_baseUrl, _USER_ME_PATH);
      final userResponse = await http.get(
        Uri.parse(userUrl),
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
      final tokenUrl = _normalizeUrl(_baseUrl, _AUTH_TOKEN_PATH);
      final tokenResponse = await http.post(
        Uri.parse(tokenUrl),
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
      final userUrl = _normalizeUrl(_baseUrl, _USER_ME_PATH);
      final userResponse = await http.get(
        Uri.parse(userUrl),
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
      print('AuthService: Starting access token refresh');
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        print('AuthService: No refresh token available');
        throw Exception('Refresh token is missing');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      };
      
      // URL normalization
      final url = _normalizeUrl(_baseUrl, _AUTH_ACCESS_TOKEN_PATH);
      print('AuthService: Token refresh request URL - $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );
      
      print('AuthService: Token refresh response status code - ${response.statusCode}');
      print('AuthService: Token refresh response headers - ${response.headers}');
      
      if (response.statusCode == 200) {
        // Extract access token from header
        final newAccessToken = response.headers['authorization'];
        
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          final token = newAccessToken.startsWith('Bearer ') 
              ? newAccessToken.substring(7) 
              : newAccessToken;
          
          await _storage.write(key: 'access_token', value: token);
          return token;
        }
        
        // If no token in header
        final currentToken = await _storage.read(key: 'access_token') ?? '';
        return currentToken;
      } else {
        throw Exception('Access token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Access token refresh error: $e');
      // Return current token on error
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
    print('AuthService: getCurrentUser called');
    final accessToken = await _storage.read(key: 'access_token');
    
    if (accessToken == null) {
      print('AuthService: No access token available');
      return null;
    }
    
    print('AuthService: Requesting user information with access token');
    try {
      final url = _normalizeUrl(_baseUrl, _USER_INFO_PATH);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      print('AuthService: User information response status code - ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('AuthService: User information loaded successfully');
        
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
        print('AuthService: Token expired, attempting to refresh');
        // Try to refresh token
        try {
          final newToken = await refreshAccessToken();
          if (newToken.isNotEmpty) {
            // Retry with new token
            print('AuthService: Token refresh successful, retrying');
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
              print('AuthService: Retry successful');
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
              print('AuthService: Retry failed - ${retryResponse.statusCode}, ${retryResponse.body}');
            }
          }
        } catch (refreshError) {
          print('AuthService: Token refresh error - $refreshError');
        }
        
        return null;
      } else {
        debugPrint('Failed to fetch user info: ${response.statusCode}, ${response.body}');
        print('AuthService: User information request failed');
        return null;
      }
    } catch (e) {
      print('AuthService: Exception during user information request - $e');
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
          final logoutUrl = _normalizeUrl(_baseUrl, _AUTH_LOGOUT_PATH);
          await http.post(
            Uri.parse(logoutUrl),
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
