// ...existing imports and code...
class HospitalService {
  // ...existing declarations...
  
  Future<List<Hospital>> getNearbyHospitals(double latitude, double longitude, {double radius = 5000}) async {
    try {
      final response = await _apiService.get('api/hospitals/nearby?lat=$latitude&lng=$longitude&radius=$radius');
      final List<dynamic> hospitalData = response['data'];
      return hospitalData.map((data) => Hospital.fromJson(data)).toList();
    } catch (e) {
      debugPrint("Error fetching nearby hospitals: $e");
      rethrow;
    }
  }

  Future<Hospital> getHospitalDetails(int hospitalId) async {
    try {
      final response = await _apiService.get('api/hospitals/$hospitalId');
      return Hospital.fromJson(response['data']);
    } catch (e) {
      debugPrint("Error fetching hospital details: $e");
      rethrow;
    }
  }

  Future<bool> checkHospitalAvailability(int hospitalId) async {
    try {
      final response = await _apiService.get('api/hospitals/$hospitalId/availability');
      return response['available'] == true;
    } catch (e) {
      debugPrint("Error checking hospital availability: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> bookHospital(int hospitalId, Map<String, dynamic> patientData) async {
    try {
      final response = await _apiService.post('api/reservations', {
        'hospitalId': hospitalId,
        'patientData': patientData,
      });
      return response;
    } catch (e) {
      debugPrint("Error booking hospital: $e");
      rethrow;
    }
  }
}
