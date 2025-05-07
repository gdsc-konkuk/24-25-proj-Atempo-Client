import 'package:flutter/foundation.dart';
import '../models/hospital_model.dart';
import 'api_service.dart';

class HospitalService {
  final ApiService _apiService = ApiService();

  // Get nearby hospitals list
  Future<List<Hospital>> getNearbyHospitals(double latitude, double longitude, {double radius = 5000}) async {
    try {
      final response = await _apiService.get(
        'api/hospitals/nearby?lat=$latitude&lng=$longitude&radius=$radius'
      );

      final List<dynamic> hospitalData = response['data'];
      return hospitalData.map((data) => Hospital.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting nearby hospitals: $e');
      rethrow;
    }
  }

  // Get hospital details
  Future<Hospital> getHospitalDetails(int hospitalId) async {
    try {
      final response = await _apiService.get('api/hospitals/$hospitalId');
      return Hospital.fromJson(response['data']);
    } catch (e) {
      debugPrint('Error getting hospital details: $e');
      rethrow;
    }
  }

  // Check hospital availability
  Future<bool> checkHospitalAvailability(int hospitalId) async {
    try {
      final response = await _apiService.get('api/hospitals/$hospitalId/availability');
      return response['available'] == true;
    } catch (e) {
      debugPrint('Error checking hospital availability: $e');
      return false;
    }
  }

  // Book hospital
  Future<Map<String, dynamic>> bookHospital(int hospitalId, Map<String, dynamic> patientData) async {
    try {
      final response = await _apiService.post(
        'api/reservations', 
        {
          'hospitalId': hospitalId,
          'patientData': patientData,
        }
      );
      return response;
    } catch (e) {
      debugPrint('Error booking hospital: $e');
      rethrow;
    }
  }
}
