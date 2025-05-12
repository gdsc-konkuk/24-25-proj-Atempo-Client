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
  final String _baseUrl = dotenv.env['API_BASE_URL']!;
  
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
  Future<Map<String, dynamic>> createAdmission(double latitude, double longitude, int searchRadius, String patientCondition) async {
    try {
      print('[HospitalService] 🏥 Creating admission request...');
      print('[HospitalService] 📍 Location: lat=$latitude, lng=$longitude');
      print('[HospitalService] 🔍 Search radius: ${searchRadius}km');
      print('[HospitalService] 📝 Patient condition: $patientCondition');
      
      // ApiService를 사용하여 요청 생성
      final requestData = {
        'location': {
          'latitude': latitude,
          'longitude': longitude
        },
        'search_radius': searchRadius,
        'patient_condition': patientCondition
      };
      
      final response = await _apiService.post('api/v1/admissions', requestData);
      
      if (response != null) {
        final Map<String, dynamic> responseData = {
          'admissionId': response['admissionId']?.toString() ?? '',
          'admissionStatus': response['admissionStatus'] ?? 'ERROR'
        };
        
        final String admissionId = responseData['admissionId'];
        final String status = responseData['admissionStatus'];
        
        print('[HospitalService] ✅ Admission created with ID: $admissionId, Status: $status');
        
        if (status == 'SUCCESS') {
          print('[HospitalService] ✅ Hospitals found successfully');
        } else {
          print('[HospitalService] ⚠️ No hospitals found or error occurred: $status');
        }
        
        return responseData;
      } else {
        print('[HospitalService] ❌ Empty response from server');
        return {
          'admissionId': '',
          'admissionStatus': 'ERROR'
        };
      }
    } catch (e) {
      print('[HospitalService] ❌ Error creating admission: $e');
      return {
        'admissionId': '',
        'admissionStatus': 'ERROR'
      };
    }
  }
  
  // Retry admission request
  Future<Map<String, dynamic>> retryAdmission(String admissionId) async {
    try {
      print('[HospitalService] 🔄 Retrying admission request with ID: $admissionId');
      
      // 추가된 엔드포인트를 사용하여 API 요청
      final response = await _apiService.post('api/v1/admissions/$admissionId/retry', {});
      
      if (response != null) {
        final Map<String, dynamic> responseData = {
          'admissionId': admissionId,
          'admissionStatus': response['admissionStatus'] ?? 'ERROR'
        };
        
        final String status = responseData['admissionStatus'];
        print('[HospitalService] ✅ Admission retry response: $responseData');
        
        if (status == 'SUCCESS') {
          print('[HospitalService] ✅ Admission retry successful');
        } else {
          print('[HospitalService] ⚠️ Admission retry did not find hospitals: $status');
        }
        
        return responseData;
      } else {
        print('[HospitalService] ❌ Empty response for admission retry');
        return {
          'admissionId': admissionId,
          'admissionStatus': 'ERROR'
        };
      }
    } catch (e) {
      print('[HospitalService] ❌ Error retrying admission: $e');
      return {
        'admissionId': admissionId,
        'admissionStatus': 'ERROR'
      };
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
    
    print('[HospitalService] 📡 SSE request information:');
    print('[HospitalService] 🌐 SSE URL: $sseUrl');
    print('[HospitalService] 📤 SSE request headers: ${request.headers}');
    print('[HospitalService] 📦 SSE request method: ${request.method}');
    
    try {
      final response = await _sseClient!.send(request);
      
      print('[HospitalService] 📊 SSE response status code: ${response.statusCode}');
      print('[HospitalService] 📥 SSE response headers: ${response.headers}');
      
      if (response.statusCode == 401) {
        print('[HospitalService] ⚠️ SSE connection 401 error- trying to refresh token');
        final newToken = await _apiService.refreshToken();
        if (newToken.isNotEmpty) {
          print('[HospitalService] ✅ Token refresh successful, retrying SSE connection');
          _sseClient!.close();
          _sseClient = http.Client();
          
          final newRequest = http.Request('GET', Uri.parse(sseUrl));
          newRequest.headers['Accept'] = 'text/event-stream';
          newRequest.headers['Cache-Control'] = 'no-cache';
          newRequest.headers['Authorization'] = 'Bearer $newToken';
          
          print('[HospitalService] 📡 SSE request information:');
          print('[HospitalService] 🌐 SSE URL: $sseUrl');
          print('[HospitalService] 📤 SSE request headers: ${newRequest.headers}');
          
          final newResponse = await _sseClient!.send(newRequest);
          print('[HospitalService] 📊 Token refresh successful, retrying SSE response status code: ${newResponse.statusCode}');
          print('[HospitalService] 📥 Token refresh successful, retrying SSE response headers: ${newResponse.headers}');
          
          _handleSseResponse(newResponse);
        } else {
          print('[HospitalService] ❌ Token refresh failed');
          throw Exception('Token refresh failed');
        }
      } else {
        _handleSseResponse(response);
      }
    } catch (e) {
      print('[HospitalService] ❌ Error during SSE connection: $e');
      rethrow;
    }
  }
  
  void _handleSseResponse(http.StreamedResponse response) {
    print('[HospitalService] 🔄 SSE response handling');
    
    if (response.statusCode == 200) {
      print('[HospitalService] ✅ SSE connection successful (status code: ${response.statusCode})');
      print('[HospitalService] 📥 response headers: ${response.headers}');
      print('[HospitalService] 🔄 Start stream listening...');
      
      response.stream
        .transform(utf8.decoder)
        .listen(
          (data) {
            print('[HospitalService] 📥 SSE data received: $data');
            _processSSEData(data);
          },
          onDone: () {
            print('[HospitalService] ⚠️ SSE connection closed by server');
            closeSSEConnection();
          },
          onError: (error) {
            print('[HospitalService] ❌ SSE stream error: $error');
            print('[HospitalService] ❌ Error message: ${error.toString()}');
            closeSSEConnection();
          }
        );
    } else {
      print('[HospitalService] ❌ SSE connection failed: ${response.statusCode}');
      print('[HospitalService] ❌ Response headers: ${response.headers}');
      
      response.stream.transform(utf8.decoder).listen(
        (data) {
          print('[HospitalService] ❌ SSE failed response body: $data');
        },
        onDone: () {
          closeSSEConnection();
        },
        onError: (error) {
          print('[HospitalService] ❌ SSE error: $error');
          closeSSEConnection();
        }
      );
    }
  }
  
  // Process SSE data
  void _processSSEData(String data) {
    try {
      print('[HospitalService] 🔄 SSE data processing');
      print('[HospitalService] 📦 Original data: $data');
      
      // Check if the data is empty
      if (data.trim().isEmpty) {
        print('[HospitalService] ⚠️ Empty data received');
        return;
      }
      
      // Check if the format is 'event:HOSPITAL_INFO_RESPONSE'
      if (data.contains('event:HOSPITAL_INFO_RESPONSE')) {
        print('[HospitalService] 📌 Event marker received, ignoring');
        return;
      }
      
      // Multiple lines of data may come at once, so process line by line
      final lines = data.split('\n').where((line) => line.trim().isNotEmpty);
      
      for (final line in lines) {
        _processSingleLine(line);
      }
    } catch (e) {
      print('[HospitalService] ❌ Error processing SSE data: $e');
      print('[HospitalService] ❌ Original data: $data');
    }
  }
  
  // Process single line of data
  void _processSingleLine(String line) {
    try {
      print('[HospitalService] 🔄 Processing single line: ${line.substring(0, math.min(50, line.length))}${line.length > 50 ? "..." : ""}');
      
      // SSE Data format case
      if (line.startsWith('data:')) {
        final jsonData = line.substring(5).trim();
        _processJsonData(jsonData);
      } 
      // Direct JSON format case
      else if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
        _processJsonData(line);
      }
      // JSON Array format case
      else if (line.trim().startsWith('[') && line.trim().endsWith(']')) {
        _processJsonArray(line);
      } else {
        print('[HospitalService] ⚠️ Not a recognized data format: $line');
      }
    } catch (e) {
      print('[HospitalService] ❌ Error processing line: $e');
    }
  }
  
  // JSON Data processing
  void _processJsonData(String jsonString) {
    if (jsonString.isEmpty) {
      print('[HospitalService] ⚠️ Empty JSON data');
      return;
    }
    
    try {
      final hospitalData = json.decode(jsonString);
      print('[HospitalService] 🏥 Parsed hospital data: $hospitalData');
      
      if (hospitalData is Map<String, dynamic> && 
          hospitalData.containsKey('name') && 
          hospitalData.containsKey('address')) {
        final hospital = Hospital.fromJson(hospitalData);
        print('[HospitalService] ✅ Created hospital object: name=${hospital.name}, id=${hospital.id}');
        
        // Add to stream immediately to trigger UI update
        _hospitalsStreamController?.add(hospital);
        print('[HospitalService] 📢 Hospital object added to stream');
      } else {
        print('[HospitalService] ⚠️ JSON doesn\'t contain required hospital data: $hospitalData');
      }
    } catch (e) {
      print('[HospitalService] ❌ Error parsing JSON data: $e');
      print('[HospitalService] ❌ Original JSON string: $jsonString');
    }
  }
  
  // JSON Array processing
  void _processJsonArray(String jsonArrayString) {
    try {
      final List<dynamic> hospitalsData = json.decode(jsonArrayString);
      print('[HospitalService] 🏥 Parsed hospitals array with ${hospitalsData.length} items');
      
      for (final hospitalData in hospitalsData) {
        if (hospitalData is Map<String, dynamic> && 
            hospitalData.containsKey('name') && 
            hospitalData.containsKey('address')) {
          final hospital = Hospital.fromJson(hospitalData);
          print('[HospitalService] ✅ Created hospital from array: name=${hospital.name}, id=${hospital.id}');
          
          // Add each hospital info immediately to stream
          _hospitalsStreamController?.add(hospital);
          print('[HospitalService] 📢 Hospital from array added to stream');
        }
      }
    } catch (e) {
      print('[HospitalService] ❌ Error parsing JSON array: $e');
      print('[HospitalService] ❌ Original array string: $jsonArrayString');
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
