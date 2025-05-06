// ...existing imports and code...
class ApiService {
  // ...existing declarations...
  
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
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => get(endpoint));
      }
      return _handleResponse(response);
    } catch (e) {
      debugPrint("GET request error: $e");
      rethrow;
    }
  }
  
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
      if (response.statusCode == 401) {
        return await _retryWithNewToken(() => post(endpoint, data));
      }
      return _handleResponse(response);
    } catch (e) {
      debugPrint("POST request error: $e");
      rethrow;
    }
  }
  
  Future<dynamic> _retryWithNewToken(Future<dynamic> Function() request) async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      return await request();
    } else {
      throw Exception("Authentication expired. Please log in again.");
    }
  }
  
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception("Server error: ${response.statusCode} - ${response.body}");
    }
  }
}
