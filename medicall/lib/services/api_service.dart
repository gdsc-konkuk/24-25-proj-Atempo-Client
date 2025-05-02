import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ApiService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080/';
  final AuthService _authService = AuthService();

  // 인증된 GET 요청
  Future<dynamic> get(String endpoint) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // 토큰 만료 시 처리 (401 Unauthorized)
      if (response.statusCode == 401) {
        // 토큰 갱신 후 재시도
        return await _retryWithNewToken(() => get(endpoint));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET 요청 오류: $e');
      rethrow;
    }
  }

  // 인증된 POST 요청
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // 토큰 만료 시 처리 (401 Unauthorized)
      if (response.statusCode == 401) {
        // 토큰 갱신 후 재시도
        return await _retryWithNewToken(() => post(endpoint, data));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST 요청 오류: $e');
      rethrow;
    }
  }

  // 인증된 PUT 요청
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // 토큰 만료 시 처리
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => put(endpoint, data));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT 요청 오류: $e');
      rethrow;
    }
  }

  // 인증된 DELETE 요청
  Future<dynamic> delete(String endpoint) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // 토큰 만료 시 처리
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => delete(endpoint));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE 요청 오류: $e');
      rethrow;
    }
  }

  // 토큰 갱신 후 요청 재시도
  Future<dynamic> _retryWithNewToken(Future<dynamic> Function() request) async {
    // 여기서는 getCurrentUser가 내부적으로 토큰 갱신 로직을 포함
    final user = await _authService.getCurrentUser();
    
    if (user != null) {
      // 토큰이 갱신되었으므로 요청 재시도
      return await request();
    } else {
      // 토큰 갱신 실패
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    }
  }

  // 응답 처리 공통 메서드
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('서버 오류: ${response.statusCode} - ${response.body}');
    }
  }
}
