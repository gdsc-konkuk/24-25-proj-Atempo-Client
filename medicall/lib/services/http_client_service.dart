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
    print('HttpClient: Authorization 헤더 설정됨 - $bearerToken');
  }

  // 리프레시 토큰 저장
  void updateRefreshToken(String refreshToken) {
    _refreshToken = refreshToken;
    print('HttpClient: Refresh 토큰 업데이트됨');
  }

  // 초기화 메서드 - 앱 시작 시 호출해야 함
  Future<void> initialize() async {
    print('HttpClient: 초기화 시작');
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    
    if (accessToken != null) {
      setAuthorizationHeader('Bearer $accessToken');
      print('HttpClient: 저장된 액세스 토큰으로 초기화됨');
    }
    
    if (refreshToken != null) {
      updateRefreshToken(refreshToken);
      print('HttpClient: 저장된 리프레시 토큰으로 초기화됨');
    }
    
    print('HttpClient: 초기화 완료, 현재 헤더: $_headers');
  }

  // 토큰 갱신 메서드
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      print('HttpClient: 리프레시 토큰 없음');
      return false;
    }
    
    print('HttpClient: 토큰 갱신 시도');
    
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_refreshToken'
      };
      
      // 베이스 URL 정규화
      final baseWithoutSlash = baseUrl.endsWith('/') ? 
          baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      
      // 액세스 토큰 갱신 URL
      final url = '$baseWithoutSlash/auth/access-token';
      print('HttpClient: 토큰 갱신 요청 URL - $url');
      print('HttpClient: 토큰 갱신 요청 헤더 - $headers');
      
      // 리프레시 토큰을 Authorization 헤더에 포함
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );
      
      print('HttpClient: 토큰 갱신 응답 상태 코드 - ${response.statusCode}');
      print('HttpClient: 토큰 갱신 응답 본문 - ${response.body}');
      
      if (response.statusCode == 200) {
        // 헤더에서 새 액세스 토큰 추출
        final newAccessToken = response.headers['authorization'];
        
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Bearer 접두사 제거
          final token = newAccessToken.startsWith('Bearer ') 
              ? newAccessToken.substring(7) 
              : newAccessToken;
          
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: 헤더에서 새 액세스 토큰으로 갱신 성공');
          return true;
        } else {
          print('HttpClient: 응답 헤더에 액세스 토큰이 없습니다');
          
          // 헤더에 토큰이 없는 경우 응답 본문 검사
          if (response.body.contains('AccessToken Reissued')) {
            // 별도 호출을 통해 토큰 확인
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
                print('HttpClient: 토큰 확인 후 새 액세스 토큰으로 갱신 성공');
                return true;
              }
            }
          }
          
          print('HttpClient: 액세스 토큰을 추출할 수 없습니다');
          return false;
        }
      } else {
        print('HttpClient: 토큰 갱신 실패 - ${response.statusCode}, ${response.body}');
        return false;
      }
    } catch (e) {
      print('HttpClient: 토큰 갱신 중 오류 - $e');
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
        // 응답 헤더에서 토큰 확인
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.isNotEmpty) {
          // 헤더에 토큰이 있으면 바로 적용
          final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: 응답 헤더에서 토큰 갱신됨');
          
          // 새 토큰으로 요청 재시도
          return http.get(uri, headers: _headers);
        } else {
          // 헤더에 토큰이 없으면 토큰 갱신 요청
          final refreshed = await refreshAccessToken();
          if (refreshed) {
            // 토큰 갱신 성공 시 요청 재시도
            return http.get(uri, headers: _headers);
          }
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
        // 응답 헤더에서 토큰 확인
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.isNotEmpty) {
          // 헤더에 토큰이 있으면 바로 적용
          final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: 응답 헤더에서 토큰 갱신됨');
          
          // 새 토큰으로 요청 재시도
          return http.post(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        } else {
          // 헤더에 토큰이 없으면 토큰 갱신 요청
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
        // 응답 헤더에서 토큰 확인
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.isNotEmpty) {
          // 헤더에 토큰이 있으면 바로 적용
          final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : authHeader;
          setAuthorizationHeader('Bearer $token');
          await storage.write(key: 'access_token', value: token);
          print('HttpClient: 응답 헤더에서 토큰 갱신됨');
          
          // 새 토큰으로 요청 재시도
          return http.patch(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        } else {
          // 헤더에 토큰이 없으면 토큰 갱신 요청
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
      }
      
      return response;
    } catch (e) {
      throw Exception('PATCH 요청 오류: $e');
    }
  }

  // HTTP PUT 요청 메서드
  Future<http.Response> put(String endpoint, dynamic body) async {
    final uri = Uri.parse(buildUrl(endpoint));
    
    try {
      final response = await http.put(
        uri, 
        headers: _headers,
        body: body is String ? body : jsonEncode(body),
      );
      
      // 401 Unauthorized - 토큰 갱신 시도
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // 토큰 갱신 성공 시 요청 재시도
          return http.put(
            uri, 
            headers: _headers,
            body: body is String ? body : jsonEncode(body),
          );
        }
      }
      
      return response;
    } catch (e) {
      throw Exception('PUT 요청 오류: $e');
    }
  }

  // 기타 필요한 HTTP 메서드 (DELETE 등) 구현 가능
}
