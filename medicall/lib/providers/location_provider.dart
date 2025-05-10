import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationProvider with ChangeNotifier {
  double _latitude = 37.5662;  // Default: Seoul City Hall
  double _longitude = 126.9785;  // Default: Seoul City Hall
  String _address = "Searching...";
  bool _isLoading = false;

  // Getters
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get address => _address;
  bool get isLoading => _isLoading;

  // Update location
  Future<void> updateLocation(double lat, double lng) async {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
    
    // Update address
    await updateAddressFromCoordinates(lat, lng);
  }

  // Update address only
  void updateAddress(String newAddress) {
    _address = newAddress;
    notifyListeners();
  }

  // Get address from coordinates (reverse geocoding)
  Future<void> updateAddressFromCoordinates(double lat, double lng) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('[LocationProvider] 🔄 Reverse geocoding coordinates: lat=$lat, lng=$lng');
      
      final googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$googleApiKey'
        '&language=en';
      
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final address = data['results'][0]['formatted_address'];
        print('[LocationProvider] ✅ Found address: $address');
        
        _address = address;
        _isLoading = false;
        notifyListeners();
      } else {
        print('[LocationProvider] ⚠️ Geocoding API error: ${data['status']}');
        throw Exception('Address not found: ${data['status']}');
      }
    } catch (e) {
      print('[LocationProvider] ❌ Error during reverse geocoding: $e');
      
      try {
        // Try alternative method if Google Geocoding API has issues
        final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks[0];
          
          // 주소 포맷 개선
          final List<String> addressComponents = [];
          
          // 함수 생성: 공백이나 널이 아닌 문자열만 추가
          void addIfValid(String? component) {
            if (component != null && component.trim().isNotEmpty) {
              // 이미 추가된 컴포넌트와 중복되지 않는지 확인
              if (!addressComponents.contains(component.trim())) {
                addressComponents.add(component.trim());
              }
            }
          }
          
          // 세부 주소부터 추가 (더 구체적인 정보)
          addIfValid(placemark.subThoroughfare);
          addIfValid(placemark.thoroughfare);
          addIfValid(placemark.subLocality);
          addIfValid(placemark.locality);
          addIfValid(placemark.administrativeArea);
          addIfValid(placemark.country);
          
          // 빈 문자열 확인 및 제거
          final filteredComponents = addressComponents.where((c) => c.isNotEmpty).toList();
          
          // 주소 컴포넌트가 비어있는 경우 기본값 설정
          if (filteredComponents.isEmpty) {
            _address = "Location at ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
          } else {
            // 역순으로 표시 (국가, 지역, 도시, 거리 순)
            _address = filteredComponents.join(', ');
          }
          
          print('[LocationProvider] ✅ Formatted address: $_address');
          _isLoading = false;
          notifyListeners();
        } else {
          throw Exception('Address not found');
        }
      } catch (secondError) {
        print('[LocationProvider] ❌ Second error during reverse geocoding: $secondError');
        _address = "Location at ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
        _isLoading = false;
        notifyListeners();
      }
    }
  }
} 