import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpClientService {
  final storage = FlutterSecureStorage();
  final String baseUrl = '${dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080'}/api/v1';
  Map<String, String> _headers = {'Content-Type': 'application/json'};
  String? _refreshToken;

  // Set authorization header with access token
  void setAuthorizationHeader(String bearerToken) {
    _headers['Authorization'] = bearerToken;
  }

  // Update refresh token
  void updateRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
  }

  // Initialize method - must be called at app start
  Future<void> initialize() async {
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    
    if (accessToken != null) {
      setAuthorizationHeader('Bearer $accessToken');
    }
    
    if (refreshToken != null) {
      updateRefreshToken(refreshToken);
    }
  }

  // Refresh access token method
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/access-token'),
        headers: {'Authorization': _refreshToken!},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        
        if (newAccessToken != null) {
          setAuthorizationHeader('Bearer $newAccessToken');
          await storage.write(key: 'access_token', value: newAccessToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error during token refresh: $e");
      return false;
    }
  }

  // Debugging - check headers
  Map<String, String> getHeaders() {
    return Map.from(_headers);
  }
  
  // URL helper (prevent duplicate slashes)
  String buildUrl(String endpoint) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$base/$path';
  }

  // HTTP GET request method
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(buildUrl(endpoint))
        .replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) return http.get(uri, headers: _headers);
      }
      return response;
    } catch (e) {
      throw Exception("GET request error: $e");
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
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return http.post(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        }
      }
      return response;
    } catch (e) {
      throw Exception("POST request error: $e");
    }
  }

  // Additional HTTP methods (PUT, DELETE, etc.) can be implemented as needed
}