import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationProvider with ChangeNotifier {
  double _latitude = 37.5662;  // 기본값: 서울 시청
  double _longitude = 126.9785;  // 기본값: 서울 시청
  String _address = "찾는 중...";
  bool _isLoading = false;

  // 게터
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get address => _address;
  bool get isLoading => _isLoading;

  // 위치 업데이트
  Future<void> updateLocation(double lat, double lng) async {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
    
    // 주소 업데이트
    await updateAddressFromCoordinates(lat, lng);
  }

  // 주소만 업데이트
  void updateAddress(String newAddress) {
    _address = newAddress;
    notifyListeners();
  }

  // 좌표에서 주소 가져오기 (역지오코딩)
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
        throw Exception('주소를 찾을 수 없습니다: ${data['status']}');
      }
    } catch (e) {
      print('[LocationProvider] ❌ Error during reverse geocoding: $e');
      
      try {
        // Google Geocoding API에 문제가 있으면 대체 방법으로 시도
        final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final placemark = placemarks[0];
          
          // 한국어 주소 형식 처리
          String address = "";
          if (placemark.country == 'South Korea' || placemark.country == '대한민국') {
            address = "${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.subLocality ?? ''} ${placemark.thoroughfare ?? ''} ${placemark.subThoroughfare ?? ''}";
          } else {
            address = "${placemark.street}, ${placemark.subLocality}, "
                "${placemark.locality}, ${placemark.administrativeArea}";
          }
          
          address = address.replaceAll(RegExp(r'\s+'), ' ').trim();
          
          _address = address;
          _isLoading = false;
          notifyListeners();
          
          print('[LocationProvider] ✅ Found address via Geocoding package: $address');
        } else {
          throw Exception('주소를 찾을 수 없습니다');
        }
      } catch (secondError) {
        print('[LocationProvider] ❌ Second error during reverse geocoding: $secondError');
        _address = "위도: $lat, 경도: $lng";
        _isLoading = false;
        notifyListeners();
      }
    }
  }
} 