import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class HttpClientService {
  final storage = FlutterSecureStorage();
  final String baseUrl = 'http://avenir.my:8080/api/v1';
  Map<String, String> _headers = {'Content-Type': 'application/json'};
  String? _refreshToken;

  // Set authorization header with access token
  void setAuthorizationHeader(String bearerToken) {
    _headers['Authorization'] = bearerToken;
    print('HttpClient: Authorization header set - $bearerToken');
  }

  // Store refresh token
  void updateRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
    print('HttpClient: Refresh token updated');
  }

  // Initialization method - must be called at app start
  Future<void> initialize() async {
    print('HttpClient: Initialization started');
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    
    if (accessToken != null) {
      setAuthorizationHeader('Bearer $accessToken');
      print('HttpClient: Initialized with stored access token');
    }
    
    if (refreshToken != null) {
      updateRefreshToken(refreshToken);
      print('HttpClient: Initialized with stored refresh token');
    }
    
    print('HttpClient: Initialization complete, current headers: $_headers');
  }

  // Token refresh method
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      print('HttpClient: No refresh token available');
      return false;
    }
    
    print('HttpClient: Attempting token refresh');
    
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_refreshToken'
      };
      
      // Base URL normalization
      final baseWithoutSlash = baseUrl.endsWith('/') ? 
          baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      
      // Access token refresh URL
      final url = '$baseWithoutSlash/auth/access-token';
      print('HttpClient: Token refresh request URL - $url');
      
      // Include refresh token in Authorization header
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );
      
      print('HttpClient: Token refresh response status code - ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Extract new access token from header
        final newAccessToken = response.headers['authorization'];
        
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Remove Bearer prefix if present
          final token = newAccessToken.startsWith('Bearer ') 
              ? newAccessToken.substring(7) 
              : newAccessToken;
          
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: Successfully refreshed access token from header');
          return true;
        } else {
          print('HttpClient: No access token in response header');
          
          // Check response body if no token in header
          if (response.body.contains('AccessToken Reissued')) {
            // Try to get token with a separate call
            final tokenCheckResponse = await http.get(
              Uri.parse('$baseWithoutSlash/auth/token'),
              headers: headers,
            );
            
            if (tokenCheckResponse.statusCode == 200) {
              final newToken = tokenCheckResponse.headers['authorization'];
              if (newToken != null && newToken.isNotEmpty) {
                final token = newToken.startsWith('Bearer ') 
                    ? newToken.substring(7) 
                    : newToken;
                
                setAuthorizationHeader('Bearer $token');
                await storage.write(key: 'access_token', value: token);
                print('HttpClient: Successfully refreshed access token after verification call');
                return true;
              }
            }
          }
          
          print('HttpClient: Unable to extract access token');
          return false;
        }
      } else {
        print('HttpClient: Token refresh failed - ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('HttpClient: Error during token refresh - $e');
      return false;
    }
  }

  // For debugging - check headers
  Map<String, String> getHeaders() {
    return Map.from(_headers);
  }
  
  // URL helper (prevent duplicate slashes)
  String buildUrl(String endpoint) {
    // Remove trailing slash from baseUrl
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    // Remove leading slash from endpoint
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    
    // Correctly connect with slash
    return '$base/$path';
  }

  // HTTP GET request method
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(buildUrl(endpoint))
        .replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri, headers: _headers);
      
      // 401 Unauthorized - try to refresh token
      if (response.statusCode == 401) {
        // Check response header for token
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.isNotEmpty) {
          // Apply token directly if present in header
          final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: Token refreshed from response header');
          
          // Retry request with new token
          return http.get(uri, headers: _headers);
        } else {
          // Request token refresh if not in header
          final refreshed = await refreshAccessToken();
          if (refreshed) {
            // Retry request after token refresh
            return http.get(uri, headers: _headers);
          }
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('GET request error: $e');
    }
  }

  // HTTP POST request method
  Future<http.Response> post(String endpoint, dynamic body) async {
    final uri = Uri.parse(buildUrl(endpoint));
    
    try {
      final response = await http.post(
        uri, 
        headers: _headers,
        body: body is String ? body : jsonEncode(body),
      );
      
      // 401 Unauthorized - try to refresh token
      if (response.statusCode == 401) {
        // Check response header for token
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.isNotEmpty) {
          // Apply token directly if present in header
          final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: Token refreshed from response header');
          
          // Retry request with new token
          return http.post(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        } else {
          // Request token refresh if not in header
          final refreshed = await refreshAccessToken();
          if (refreshed) {
            // Retry request after token refresh
            return http.post(
              uri, 
              headers: _headers,
              body: body is String ? body : jsonEncode(body),
            );
          }
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('POST request error: $e');
    }
  }

  // HTTP PATCH request method
  Future<http.Response> patch(String endpoint, dynamic body) async {
    final uri = Uri.parse(buildUrl(endpoint));
    
    try {
      final response = await http.patch(
        uri, 
        headers: _headers,
        body: body is String ? body : jsonEncode(body),
      );
      
      // 401 Unauthorized - try to refresh token
      if (response.statusCode == 401) {
        // Check response header for token
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.isNotEmpty) {
          // Apply token directly if present in header
          final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: Token refreshed from response header');
          
          // Retry request with new token
          return http.patch(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        } else {
          // Request token refresh if not in header
          final refreshed = await refreshAccessToken();
          if (refreshed) {
            // Retry request after token refresh
            return http.patch(
              uri, 
              headers: _headers,
              body: body is String ? body : jsonEncode(body),
            );
          }
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('PATCH request error: $e');
    }
  }

  // HTTP PUT request method
  Future<http.Response> put(String endpoint, dynamic body) async {
    final uri = Uri.parse(buildUrl(endpoint));
    
    try {
      final response = await http.put(
        uri, 
        headers: _headers,
        body: body is String ? body : jsonEncode(body),
      );
      
      // 401 Unauthorized - try to refresh token
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry request after token refresh
          return http.put(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('PUT request error: $e');
    }
  }

  // Other necessary HTTP methods (DELETE, etc.) can be implemented here
}
