import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ApiService {
  // Redefine baseUrl for slash normalization
  final String _baseUrl;
  final AuthService _authService = AuthService();
  
  ApiService() : 
    _baseUrl = (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080').endsWith('/') 
      ? (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080').substring(0, (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080').length - 1) 
      : (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080');

  // URL normalization method
  String _buildUrl(String endpoint) {
    // Remove starting slash from endpoint
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$_baseUrl/$path';
  }

  // Authenticated GET request
  Future<dynamic> get(String endpoint) async {
    try {
      print('ApiService: GET request started - $endpoint');
      final token = await _authService.getToken();
      print('ApiService: Auth token - ${token != null ? "token exists" : "no token"}');
      
      final url = _buildUrl(endpoint);
      print('ApiService: GET request URL - $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('ApiService: GET response status code - ${response.statusCode}');
      
      // Handle token expiration (401 Unauthorized)
      if (response.statusCode == 401) {
        print('ApiService: 401 Unauthorized - attempting token refresh');
        // Retry after token refresh
        return await _retryWithNewToken(() => get(endpoint));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET request error: $e');
      rethrow;
    }
  }

  // Authenticated POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final url = _buildUrl(endpoint);
      print('ApiService: POST request URL - $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // Handle token expiration (401 Unauthorized)
      if (response.statusCode == 401) {
        // Retry after token refresh
        return await _retryWithNewToken(() => post(endpoint, data));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST request error: $e');
      rethrow;
    }
  }

  // Authenticated PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final url = _buildUrl(endpoint);
      print('ApiService: PUT request URL - $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => put(endpoint, data));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT request error: $e');
      rethrow;
    }
  }

  // Authenticated DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await _authService.getToken();
      final url = _buildUrl(endpoint);
      print('ApiService: DELETE request URL - $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => delete(endpoint));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE request error: $e');
      rethrow;
    }
  }

  // Authenticated PATCH request
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final url = _buildUrl(endpoint);
      print('ApiService: PATCH request URL - $url');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // Handle token expiration
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => patch(endpoint, data));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PATCH request error: $e');
      rethrow;
    }
  }

  // Retry request after token refresh
  Future<dynamic> _retryWithNewToken(Future<dynamic> Function() request) async {
    print('ApiService: Attempting token refresh');
    try {
      // Direct token refresh attempt
      final newToken = await _authService.refreshAccessToken();
      
      if (newToken.isNotEmpty) {
        print('ApiService: Token refresh successful, retrying request');
        return await request();
      } else {
        print('ApiService: Token refresh failed');
        throw Exception('Authentication expired. Please login again.');
      }
    } catch (e) {
      print('ApiService: Error during token refresh - $e');
      throw Exception('Authentication expired. Please login again.');
    }
  }

  // Common response handling method
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('Server error: ${response.statusCode} - ${response.body}');
    }
  }
  
  // 토큰 갱신 메소드 - HospitalService에서 사용
  Future<String> refreshToken() async {
    try {
      print('ApiService: Attempting direct token refresh');
      return await _authService.refreshAccessToken();
    } catch (e) {
      print('ApiService: Error during direct token refresh: $e');
      return '';
    }
  }
}
