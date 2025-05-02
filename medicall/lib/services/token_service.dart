import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TokenService {
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080/';

  // POST /api/v1/auth/refresh-token
  // Refresh 토큰을 Authorization 헤더에 Bearer 토큰 형태로 제출하여 새 Refresh 토큰 발급
  static Future<String> refreshRefreshToken(String refreshToken) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/refresh-token');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $refreshToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 예시: 응답 JSON에서 'refreshToken' 키를 통해 새 토큰 획득 (다른 키일 경우 수정 필요)
      return data['refreshToken'];
    } else {
      throw Exception('Failed to refresh refresh token: ${response.statusCode}');
    }
  }

  // POST /api/v1/auth/access-token
  // Refresh 토큰을 Authorization 헤더에 Bearer 토큰 형태로 제출하여 Access 토큰 발급
  static Future<String> getAccessToken(String refreshToken) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/access-token');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $refreshToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // 예시: 응답 JSON에서 'accessToken' 키를 통해 새 토큰 획득 (다른 키일 경우 수정 필요)
      return data['accessToken'];
    } else {
      throw Exception('Failed to get access token: ${response.statusCode}');
    }
  }
}
