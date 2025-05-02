import 'package:flutter/foundation.dart';
import '../models/hospital_model.dart';
import 'api_service.dart';

class HospitalService {
  final ApiService _apiService = ApiService();

  // 주변 병원 목록 가져오기
  Future<List<Hospital>> getNearbyHospitals(double latitude, double longitude, {double radius = 5000}) async {
    try {
      final response = await _apiService.get(
        'api/hospitals/nearby?lat=$latitude&lng=$longitude&radius=$radius'
      );

      final List<dynamic> hospitalData = response['data'];
      return hospitalData.map((data) => Hospital.fromJson(data)).toList();
    } catch (e) {
      debugPrint('주변 병원 가져오기 오류: $e');
      rethrow;
    }
  }

  // 병원 상세 정보 가져오기
  Future<Hospital> getHospitalDetails(int hospitalId) async {
    try {
      final response = await _apiService.get('api/hospitals/$hospitalId');
      return Hospital.fromJson(response['data']);
    } catch (e) {
      debugPrint('병원 상세 정보 가져오기 오류: $e');
      rethrow;
    }
  }

  // 병원 가용성 확인
  Future<bool> checkHospitalAvailability(int hospitalId) async {
    try {
      final response = await _apiService.get('api/hospitals/$hospitalId/availability');
      return response['available'] == true;
    } catch (e) {
      debugPrint('병원 가용성 확인 오류: $e');
      return false;
    }
  }

  // 병원 예약하기
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
      debugPrint('병원 예약 오류: $e');
      rethrow;
    }
  }
}
