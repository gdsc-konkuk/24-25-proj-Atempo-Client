import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080';

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
        id: userData['id'].toString(),
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photoUrl'],
        accessToken: accessToken,
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
        id: userData['id'].toString(),
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photoUrl'],
        accessToken: accessToken,
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
        id: userData['id'].toString(),
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photoUrl'],
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint('OAuth redirect handling error: $e');
      rethrow;
    }
  }
  
  // Refresh access token
  Future<String> refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw Exception('Refresh token is missing');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/access-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Access token refresh failed: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'];
      
      // Save new access token
      await _storage.write(key: 'access_token', value: accessToken);
      return accessToken;
    } catch (e) {
      debugPrint('Access token refresh error: $e');
      rethrow;
    }
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      final refreshToken = await _storage.read(key: 'refresh_token');
      final userId = await _storage.read(key: 'user_id');
      
      if (accessToken == null || refreshToken == null || userId == null) {
        return null;
      }
      
      // Attempt to request user info with access token
      try {
        final userInfoResponse = await http.get(
          Uri.parse('$_baseUrl/api/v1/members/$userId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );
        
        if (userInfoResponse.statusCode == 200) {
          final Map<String, dynamic> userData = jsonDecode(userInfoResponse.body);
          return User(
            id: userId,
            email: userData['email'] ?? '',
            name: userData['name'] ?? '',
            photoUrl: userData['photoUrl'],
            accessToken: accessToken,
          );
        } else if (userInfoResponse.statusCode == 401) {
          // Attempt to refresh access token if expired
          final newAccessToken = await refreshAccessToken();
          await _storage.write(key: 'access_token', value: newAccessToken);
          
          // Retry with refreshed token
          final retryResponse = await http.get(
            Uri.parse('$_baseUrl/api/v1/members/$userId'),
            headers: {
              'Authorization': 'Bearer $newAccessToken',
            },
          );
          
          if (retryResponse.statusCode == 200) {
            final Map<String, dynamic> userData = jsonDecode(retryResponse.body);
            return User(
              id: userId,
              email: userData['email'] ?? '',
              name: userData['name'] ?? '',
              photoUrl: userData['photoUrl'],
              accessToken: newAccessToken,
            );
          }
        }
      } catch (e) {
        debugPrint('User info retrieval error: $e');
      }
      
      // Return null if all attempts fail
      return null;
    } catch (e) {
      debugPrint('Current user retrieval error: $e');
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
