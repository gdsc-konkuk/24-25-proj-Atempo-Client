import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class HttpClientService {
  final storage = FlutterSecureStorage();
  final String baseUrl = 'http://avenir.my:8080/api/v1';
  Map<String, String> _headers = {'Content-Type': 'application/json'};
  String? _refreshToken;

  // 액세스 토큰으로 인증 헤더 설정
  void setAuthorizationHeader(String bearerToken) {
    _headers['Authorization'] = bearerToken;
  }

  // 리프레시 토큰 저장
  void updateRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
  }

  // 초기화 메서드 - 앱 시작 시 호출해야 함
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

  // 토큰 갱신 메서드
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
      
      // 토큰 갱신 실패 시 로그인 필요
      return false;
    } catch (e) {
      print('토큰 갱신 중 오류: $e');
      return false;
    }
  }

  // 디버깅용 - 헤더 확인
  Map<String, String> getHeaders() {
    return Map.from(_headers);
  }
  
  // URL 조합 헬퍼 (슬래시 중복 방지)
  String buildUrl(String endpoint) {
    // baseUrl에서 끝 슬래시 제거
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    // endpoint에서 시작 슬래시 제거
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    
    // 슬래시로 올바르게 연결
    return '$base/$path';
  }

  // HTTP GET 요청 메서드
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(buildUrl(endpoint))
        .replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri, headers: _headers);
      
      // 401 Unauthorized - 토큰 갱신 시도
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // 토큰 갱신 성공 시 요청 재시도
          return http.get(uri, headers: _headers);
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('GET 요청 오류: $e');
    }
  }

  // HTTP POST 요청 메서드
  Future<http.Response> post(String endpoint, dynamic body) async {
    final uri = Uri.parse(buildUrl(endpoint));
    
    try {
      final response = await http.post(
        uri, 
        headers: _headers,
        body: body is String ? body : jsonEncode(body),
      );
      
      // 401 Unauthorized - 토큰 갱신 시도
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // 토큰 갱신 성공 시 요청 재시도
          return http.post(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('POST 요청 오류: $e');
    }
  }

  // HTTP PATCH 요청 메서드
  Future<http.Response> patch(String endpoint, dynamic body) async {
    final uri = Uri.parse(buildUrl(endpoint));
    
    try {
      final response = await http.patch(
        uri, 
        headers: _headers,
        body: body is String ? body : jsonEncode(body),
      );
      
      // 401 Unauthorized - 토큰 갱신 시도
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // 토큰 갱신 성공 시 요청 재시도
          return http.patch(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('PATCH 요청 오류: $e');
    }
  }

  // 기타 필요한 HTTP 메서드 (PUT, DELETE 등) 구현 가능
}
