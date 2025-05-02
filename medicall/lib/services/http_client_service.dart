import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// 쿠키 상태를 유지하는 HTTP 클라이언트 서비스
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;

  late Dio _dio;
  // 전역으로 쿠키 저장소 유지
  final CookieJar cookieJar = CookieJar();

  HttpClientService._internal() {
    _dio = Dio(
      BaseOptions(
        followRedirects: false,                 // 자동 리다이렉트 비활성
        validateStatus: (s) => s != null && (s < 400 || s == 302),
      ),
    );
    
    // 쿠키 관리자 설정
    _dio.interceptors.add(CookieManager(cookieJar));
    
    // 로깅 설정 (디버그 모드에서만)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        requestHeader: true,
      ));
    }
  }

  Dio get client => _dio;
  
  /// WebView에서 추출한 JSESSIONID를 Dio에 주입
  void injectSessionCookie(String jsessionId, String domain, {String path = '/'}) {
    final cookie = Cookie('JSESSIONID', jsessionId)
      ..domain = domain
      ..path = path;
    
    final uri = Uri.parse('http://$domain');
    cookieJar.saveFromResponse(uri, [cookie]);
    
    if (kDebugMode) {
      print('JSESSIONID 쿠키 주입 완료: $jsessionId');
    }
  }

  /// OAuth 로그인 URL 리다이렉션 획득
  Future<String> getLoginRedirect(String url) async {
    try {
      final res = await _dio.get(url);             // 302 예상
      if (res.statusCode == 302) {
        final loc = res.headers[HttpHeaders.locationHeader]?.first;
        if (loc == null || loc.isEmpty) {
          throw Exception('Location 헤더 없음');
        }
        return loc;                               // 최종 리다이렉트 URL 반환
      }
      throw Exception('예상치 못한 상태: ${res.statusCode}');
    } catch (e) {
      debugPrint('HTTP 리다이렉트 요청 오류: $e');
      rethrow;
    }
  }

  /// Post 요청 수행 (쿠키 관리 포함)
  Future<Response> post(String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options ?? Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      return response;
    } catch (e) {
      debugPrint('HTTP POST 요청 오류: $e');
      rethrow;
    }
  }

  /// 특정 도메인의 쿠키 삭제
  void clearCookies(String domain) {
    cookieJar.delete(Uri.parse(domain));
  }

  /// 모든 쿠키 삭제
  void clearAllCookies() {
    cookieJar.deleteAll();
  }
}
