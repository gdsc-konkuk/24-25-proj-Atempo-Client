import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/hospital_model.dart';
import 'api_service.dart';

class HospitalService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://avenir.my:8080';
  
  // Controller for SSE connection
  StreamController<Hospital>? _hospitalsStreamController;
  http.Client? _sseClient;

  // Close SSE connection
  void closeSSEConnection() {
    print('[HospitalService] 🔌 Closing SSE connection');
    _sseClient?.close();
    _hospitalsStreamController?.close();
    _sseClient = null;
    _hospitalsStreamController = null;
    print('[HospitalService] ✅ SSE connection successfully closed');
  }

  // Create admission request
  Future<String> createAdmission(double latitude, double longitude, int searchRadius, String patientCondition) async {
    try {
      print('[HospitalService] 🏥 Creating admission request...');
      print('[HospitalService] 📍 Location: lat=$latitude, lng=$longitude');
      print('[HospitalService] 🔍 Search radius: ${searchRadius}km');
      print('[HospitalService] 📝 Patient condition: $patientCondition');
      
      // Check and get token
      final storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'access_token');
      
      if (token == null || token.isEmpty) {
        print('[HospitalService] ❌ Authentication token not found or empty');
        
        // Try to refresh token via api_service
        try {
          print('[HospitalService] 🔄 Attempting to refresh token via ApiService');
          token = await _apiService.refreshToken();
          
          if (token.isEmpty) {
            print('[HospitalService] ❌ Token refresh failed');
            throw Exception('Authentication token refresh failed');
          }
          print('[HospitalService] ✅ Token refreshed successfully');
        } catch (refreshError) {
          print('[HospitalService] ❌ Error during token refresh: $refreshError');
          throw Exception('Authentication token not found and refresh failed: $refreshError');
        }
      }
      print('[HospitalService] 🔑 Authentication token retrieved (length: ${token.length})');
      print('[HospitalService] 🔍 Token starts with: ${token.substring(0, math.min(10, token.length))}...');
      
      final url = '$_baseUrl/api/v1/admissions';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      final body = jsonEncode({
        'location': {
          'latitude': latitude,
          'longitude': longitude
        },
        'search_radius': searchRadius,
        'patient_condition': patientCondition
      });

      print('[HospitalService] 🌐 Sending admission request to: $url');
      print('[HospitalService] 📤 Request headers: $headers');
      print('[HospitalService] 📦 Request body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('[HospitalService] 📊 Response status code: ${response.statusCode}');
      print('[HospitalService] 📥 Response headers: ${response.headers}');
      print('[HospitalService] 📄 Response body: ${response.body}');
      
      // Check token expiration (401)
      if (response.statusCode == 401) {
        print('[HospitalService] ⚠️ Token expired (401) - attempting to refresh');
        
        // Try to refresh token
        try {
          final newToken = await _apiService.refreshToken();
          if (newToken.isNotEmpty) {
            print('[HospitalService] ✅ Token refreshed successfully, retrying request');
            
            // Retry request with new token
            final retryHeaders = {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken'
            };
            
            final retryResponse = await http.post(
              Uri.parse(url),
              headers: retryHeaders,
              body: body,
            );
            
            print('[HospitalService] 📊 Retry response status code: ${retryResponse.statusCode}');
            print('[HospitalService] 📄 Retry response body: ${retryResponse.body}');
            
            if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
              final data = json.decode(retryResponse.body);
              final admissionId = data['admissionId']?.toString() ?? '';
              
              if (admissionId.isEmpty) {
                print('[HospitalService] ❌ Invalid admission ID received from server after token refresh');
                throw Exception('Invalid admission ID received from server after token refresh');
              }
              
              print('[HospitalService] ✅ Admission created with ID: $admissionId after token refresh');
              return admissionId;
            } else {
              print('[HospitalService] ❌ Server error after token refresh: ${retryResponse.statusCode} - ${retryResponse.body}');
              throw Exception('Server error after token refresh: ${retryResponse.statusCode} - ${retryResponse.body}');
            }
          } else {
            print('[HospitalService] ❌ Token refresh failed');
            throw Exception('Token refresh failed for 401 response');
          }
        } catch (refreshError) {
          print('[HospitalService] ❌ Error during token refresh: $refreshError');
          throw Exception('Authentication error: $refreshError');
        }
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final admissionId = data['admissionId']?.toString() ?? '';
        
        if (admissionId.isEmpty) {
          print('[HospitalService] ❌ Invalid admission ID received from server');
          throw Exception('Invalid admission ID received from server');
        }
        
        print('[HospitalService] ✅ Admission created with ID: $admissionId');
        return admissionId;
      } else {
        print('[HospitalService] ❌ Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[HospitalService] ❌ Error creating admission: $e');
      rethrow;
    }
  }
  
  // Retry admission request
  Future<String> retryAdmission(String admissionId) async {
    try {
      print('[HospitalService] 🔄 Retrying admission request with ID: $admissionId');
      
      // Check and get token
      final storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'access_token');
      
      if (token == null || token.isEmpty) {
        print('[HospitalService] ❌ Authentication token not found or empty for retry');
        
        // Try to refresh token via api_service
        try {
          print('[HospitalService] 🔄 Attempting to refresh token via ApiService for retry');
          token = await _apiService.refreshToken();
          
          if (token.isEmpty) {
            print('[HospitalService] ❌ Token refresh failed for retry');
            throw Exception('Authentication token refresh failed for retry');
          }
          print('[HospitalService] ✅ Token refreshed successfully for retry');
        } catch (refreshError) {
          print('[HospitalService] ❌ Error during token refresh for retry: $refreshError');
          throw Exception('Authentication token not found and refresh failed for retry: $refreshError');
        }
      }
      print('[HospitalService] 🔑 Authentication token retrieved for retry (length: ${token.length})');
      
      final url = '$_baseUrl/api/v1/admissions/$admissionId/retry';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      };
      
      print('[HospitalService] 🌐 Sending retry request to: $url');
      print('[HospitalService] 📤 Request headers: $headers');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      );
      
      print('[HospitalService] 📊 Response status code: ${response.statusCode}');
      print('[HospitalService] 📥 Response headers: ${response.headers}');
      print('[HospitalService] 📄 Response body: ${response.body}');
      
      // Check token expiration (401)
      if (response.statusCode == 401) {
        print('[HospitalService] ⚠️ Token expired (401) for retry - attempting to refresh');
        
        // Try to refresh token
        try {
          final newToken = await _apiService.refreshToken();
          if (newToken.isNotEmpty) {
            print('[HospitalService] ✅ Token refreshed successfully for retry, retrying request');
            
            // Retry request with new token
            final retryHeaders = {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken'
            };
            
            final retryResponse = await http.post(
              Uri.parse(url),
              headers: retryHeaders,
            );
            
            print('[HospitalService] 📊 Retry response status code: ${retryResponse.statusCode}');
            print('[HospitalService] 📄 Retry response body: ${retryResponse.body}');
            
            if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
              print('[HospitalService] ✅ Admission retry successful after token refresh');
              return admissionId;
            } else {
              print('[HospitalService] ❌ Server error after token refresh for retry: ${retryResponse.statusCode} - ${retryResponse.body}');
              throw Exception('Server error after token refresh for retry: ${retryResponse.statusCode} - ${retryResponse.body}');
            }
          } else {
            print('[HospitalService] ❌ Token refresh failed for retry');
            throw Exception('Token refresh failed for 401 response during retry');
          }
        } catch (refreshError) {
          print('[HospitalService] ❌ Error during token refresh for retry: $refreshError');
          throw Exception('Authentication error during retry: $refreshError');
        }
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[HospitalService] ✅ Admission retry successful');
        return admissionId;
      } else {
        print('[HospitalService] ❌ Server error for retry: ${response.statusCode} - ${response.body}');
        throw Exception('Server error for retry: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[HospitalService] ❌ Error retrying admission: $e');
      rethrow;
    }
  }
  
  // Return SSE subscription stream
  Stream<Hospital> subscribeToHospitalUpdates() {
    print('[HospitalService] 📡 Creating hospital updates subscription');
    if (_hospitalsStreamController == null || _hospitalsStreamController!.isClosed) {
      print('[HospitalService] 🔄 Initializing new stream controller');
      _hospitalsStreamController = StreamController<Hospital>.broadcast();
    }
    
    _connectToSSE();
    
    print('[HospitalService] ✅ Returning hospital updates stream');
    return _hospitalsStreamController!.stream;
  }
  
  // Set up SSE connection
  Future<void> _connectToSSE() async {
    try {
      if (_sseClient != null) {
        print('[HospitalService] ⚠️ SSE client already exists, skipping connection');
        return;
      }
      
      print('[HospitalService] 🔄 Connecting to SSE...');
      String? token = await _storage.read(key: 'access_token');
      
      if (token == null) {
        print('[HospitalService] ❌ Authentication token not found for SSE connection');
        throw Exception('Authentication token not found');
      }
      
      // SSE 연결 시도
      await _tryConnectWithToken(token);
      
    } catch (e) {
      print('[HospitalService] ❌ Error connecting to SSE: $e');
      closeSSEConnection();
    }
  }
  
  Future<void> _tryConnectWithToken(String token) async {
    _sseClient = http.Client();
    final sseUrl = '$_baseUrl/api/v1/notifications/subscribe';
    final request = http.Request('GET', Uri.parse(sseUrl));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';
    request.headers['Authorization'] = 'Bearer $token';
    
    print('[HospitalService] 📡 SSE 요청 정보:');
    print('[HospitalService] 🌐 SSE URL: $sseUrl');
    print('[HospitalService] 📤 SSE 요청 헤더: ${request.headers}');
    print('[HospitalService] 📦 SSE 요청 방식: ${request.method}');
    
    try {
      final response = await _sseClient!.send(request);
      
      print('[HospitalService] 📊 SSE 응답 상태 코드: ${response.statusCode}');
      print('[HospitalService] 📥 SSE 응답 헤더: ${response.headers}');
      
      if (response.statusCode == 401) {
        // 토큰 갱신 시도
        print('[HospitalService] ⚠️ SSE 연결 401 오류 - 토큰 갱신 시도');
        final newToken = await _apiService.refreshToken();
        if (newToken.isNotEmpty) {
          print('[HospitalService] ✅ 토큰 갱신 성공, SSE 연결 재시도');
          // 이전 클라이언트 정리
          _sseClient!.close();
          _sseClient = http.Client();
          
          // 새 토큰으로 재시도
          final newRequest = http.Request('GET', Uri.parse(sseUrl));
          newRequest.headers['Accept'] = 'text/event-stream';
          newRequest.headers['Cache-Control'] = 'no-cache';
          newRequest.headers['Authorization'] = 'Bearer $newToken';
          
          print('[HospitalService] 📡 토큰 갱신 후 SSE 재요청 정보:');
          print('[HospitalService] 🌐 SSE URL: $sseUrl');
          print('[HospitalService] 📤 SSE 재요청 헤더: ${newRequest.headers}');
          
          final newResponse = await _sseClient!.send(newRequest);
          print('[HospitalService] 📊 토큰 갱신 후 SSE 응답 상태 코드: ${newResponse.statusCode}');
          print('[HospitalService] 📥 토큰 갱신 후 SSE 응답 헤더: ${newResponse.headers}');
          
          _handleSseResponse(newResponse);
        } else {
          print('[HospitalService] ❌ 토큰 갱신 실패');
          throw Exception('토큰 갱신 실패');
        }
      } else {
        _handleSseResponse(response);
      }
    } catch (e) {
      print('[HospitalService] ❌ SSE 요청 중 예외 발생: $e');
      rethrow;
    }
  }
  
  void _handleSseResponse(http.StreamedResponse response) {
    print('[HospitalService] 🔄 SSE 응답 처리 시작');
    
    if (response.statusCode == 200) {
      print('[HospitalService] ✅ SSE 연결 성공 (상태 코드: ${response.statusCode})');
      print('[HospitalService] 📥 응답 헤더: ${response.headers}');
      print('[HospitalService] 🔄 스트림 리스닝 시작...');
      
      response.stream.transform(utf8.decoder).listen(
        (data) {
          print('[HospitalService] 📥 SSE 데이터 수신: $data');
          _processSSEData(data);
        },
        onDone: () {
          print('[HospitalService] ⚠️ SSE 연결 서버에 의해 종료됨');
          closeSSEConnection();
        },
        onError: (error) {
          print('[HospitalService] ❌ SSE 스트림 에러: $error');
          print('[HospitalService] ❌ 에러 상세: ${error.toString()}');
          closeSSEConnection();
        }
      );
    } else {
      print('[HospitalService] ❌ SSE 연결 실패: ${response.statusCode}');
      print('[HospitalService] ❌ 응답 헤더: ${response.headers}');
      
      // 응답 본문도 로깅 시도
      response.stream.transform(utf8.decoder).listen(
        (data) {
          print('[HospitalService] ❌ SSE 연결 실패 응답 본문: $data');
        },
        onDone: () {
          closeSSEConnection();
        },
        onError: (error) {
          print('[HospitalService] ❌ SSE 연결 실패 응답 읽기 오류: $error');
          closeSSEConnection();
        }
      );
    }
  }
  
  // Process SSE data
  void _processSSEData(String data) {
    try {
      print('[HospitalService] 🔄 SSE 데이터 처리 중');
      print('[HospitalService] 📦 원본 데이터: $data');
      
      // SSE data format: data: {...JSON data...}
      if (data.startsWith('data:')) {
        final jsonData = data.substring(5).trim();
        print('[HospitalService] 📦 추출된 JSON 데이터: $jsonData');
        
        if (jsonData.isNotEmpty) {
          try {
            final hospitalData = json.decode(jsonData);
            print('[HospitalService] 🏥 파싱된 병원 데이터: $hospitalData');
            
            final hospital = Hospital.fromJson(hospitalData);
            print('[HospitalService] ✅ 생성된 병원 객체: 이름=${hospital.name}, ID=${hospital.id}');
            
            _hospitalsStreamController?.add(hospital);
            print('[HospitalService] 📢 스트림에 병원 객체 추가 완료');
          } catch (e) {
            print('[HospitalService] ❌ 병원 데이터 파싱 오류: $e');
            print('[HospitalService] ❌ 파싱 시도한 원본 데이터: $jsonData');
          }
        } else {
          print('[HospitalService] ⚠️ SSE 메시지의 JSON 데이터가 비어있음');
        }
      } else {
        print('[HospitalService] ⚠️ 데이터 이벤트가 아님: $data');
      }
    } catch (e) {
      print('[HospitalService] ❌ SSE 데이터 처리 오류: $e');
      print('[HospitalService] ❌ 오류 발생 원본 데이터: $data');
    }
  }

  // Get nearby hospitals list
  Future<List<Hospital>> getNearbyHospitals(double latitude, double longitude, {double radius = 5000}) async {
    try {
      print('[HospitalService] 🔍 Getting nearby hospitals: lat=$latitude, lng=$longitude, radius=${radius}m');
      final response = await _apiService.get(
        'api/hospitals/nearby?lat=$latitude&lng=$longitude&radius=$radius'
      );

      final List<dynamic> hospitalData = response['data'];
      print('[HospitalService] ✅ Retrieved ${hospitalData.length} nearby hospitals');
      return hospitalData.map((data) => Hospital.fromJson(data)).toList();
    } catch (e) {
      print('[HospitalService] ❌ Error getting nearby hospitals: $e');
      rethrow;
    }
  }

  // Get hospital details
  Future<Hospital> getHospitalDetails(int hospitalId) async {
    try {
      print('[HospitalService] 🔍 Getting hospital details for ID: $hospitalId');
      final response = await _apiService.get('api/hospitals/$hospitalId');
      print('[HospitalService] ✅ Hospital details retrieved');
      return Hospital.fromJson(response['data']);
    } catch (e) {
      print('[HospitalService] ❌ Error getting hospital details: $e');
      rethrow;
    }
  }

  // Check hospital availability
  Future<bool> checkHospitalAvailability(int hospitalId) async {
    try {
      print('[HospitalService] 🔍 Checking availability for hospital ID: $hospitalId');
      final response = await _apiService.get('api/hospitals/$hospitalId/availability');
      final bool isAvailable = response['available'] == true;
      print('[HospitalService] ✅ Hospital availability: $isAvailable');
      return isAvailable;
    } catch (e) {
      print('[HospitalService] ❌ Error checking hospital availability: $e');
      return false;
    }
  }

  // Book hospital
  Future<Map<String, dynamic>> bookHospital(int hospitalId, Map<String, dynamic> patientData) async {
    try {
      print('[HospitalService] 📝 Booking hospital ID: $hospitalId');
      print('[HospitalService] 📄 Patient data: $patientData');
      
      final response = await _apiService.post(
        'api/reservations', 
        {
          'hospitalId': hospitalId,
          'patientData': patientData,
        }
      );
      
      print('[HospitalService] ✅ Hospital booking successful');
      return response;
    } catch (e) {
      print('[HospitalService] ❌ Error booking hospital: $e');
      rethrow;
    }
  }
}
