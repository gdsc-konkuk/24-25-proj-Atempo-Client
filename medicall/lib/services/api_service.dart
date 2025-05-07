import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ApiService {
  // 슬래시 정규화를 위해 baseUrl 재정의
  final String _baseUrl;
  final AuthService _authService = AuthService();
  
  ApiService() : 
    _baseUrl = (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080').endsWith('/') 
      ? (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080').substring(0, (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080').length - 1) 
      : (dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080');

  // URL 정규화 메서드
  String _buildUrl(String endpoint) {
    // endpoint에서 시작 슬래시 제거
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$_baseUrl/$path';
  }

  // 인증된 GET 요청
  Future<dynamic> get(String endpoint) async {
    try {
      print('ApiService: GET 요청 시작 - $endpoint');
      final token = await _authService.getToken();
      print('ApiService: 인증 토큰 - ${token != null ? "토큰 있음" : "토큰 없음"}');
      
      final url = _buildUrl(endpoint);
      print('ApiService: GET 요청 URL - $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('ApiService: GET 응답 상태 코드 - ${response.statusCode}');
      
      // 토큰 만료 시 처리 (401 Unauthorized)
      if (response.statusCode == 401) {
        print('ApiService: 401 Unauthorized - 토큰 갱신 시도');
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
      final url = _buildUrl(endpoint);
      print('ApiService: POST 요청 URL - $url');
      
      final response = await http.post(
        Uri.parse(url),
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
      final url = _buildUrl(endpoint);
      print('ApiService: PUT 요청 URL - $url');
      
      final response = await http.put(
        Uri.parse(url),
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
      final url = _buildUrl(endpoint);
      print('ApiService: DELETE 요청 URL - $url');
      
      final response = await http.delete(
        Uri.parse(url),
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

  // 인증된 PATCH 요청
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _authService.getToken();
      final url = _buildUrl(endpoint);
      print('ApiService: PATCH 요청 URL - $url');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      // 토큰 만료 시 처리
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => patch(endpoint, data));
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('PATCH 요청 오류: $e');
      rethrow;
    }
  }

  // 토큰 갱신 후 요청 재시도
  Future<dynamic> _retryWithNewToken(Future<dynamic> Function() request) async {
    print('ApiService: 토큰 갱신 시도');
    try {
      // 직접 토큰 갱신 시도
      final newToken = await _authService.refreshAccessToken();
      
      if (newToken.isNotEmpty) {
        print('ApiService: 토큰 갱신 성공, 요청 재시도');
        return await request();
      } else {
        print('ApiService: 토큰 갱신 실패');
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      }
    } catch (e) {
      print('ApiService: 토큰 갱신 중 오류 발생 - $e');
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
