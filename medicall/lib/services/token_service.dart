import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TokenService {
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080';

  // POST /api/v1/auth/refresh-token
  // Submit refresh token in Authorization header as Bearer token to obtain new refresh token
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
      // Example: Get new token through 'refreshToken' key in response JSON (modify if key is different)
      return data['refreshToken'];
    } else {
      throw Exception('Failed to refresh refresh token: ${response.statusCode}');
    }
  }

  // POST /api/v1/auth/access-token
  // Submit refresh token in Authorization header as Bearer token to obtain access token
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
      // Example: Get new token through 'accessToken' key in response JSON (modify if key is different)
      return data['accessToken'];
    } else {
      throw Exception('Failed to get access token: ${response.statusCode}');
    }
  }
}
