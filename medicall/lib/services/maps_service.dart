import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class MapsService {
  static final MethodChannel _channel = MethodChannel('com.medicall/maps');
  
  // 샌프란시스코 위치(테스트 위치) - 이 위치가 나타나면 실제 위치를 가져오지 못한 것
  static const double sanFranciscoLat = 37.7749;
  static const double sanFranciscoLng = -122.4194;
  
  // 기본 위치를 서울로 설정
  static const double defaultLatitude = 37.5665;
  static const double defaultLongitude = 126.9780;
  
  static Future<void> initializeApiKey() async {
    try {
      // .env 파일에서 API 키를 가져옴
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('Google Maps API 키가 .env 파일에 없거나 비어 있습니다.');
        return;
      }
      
      // 플랫폼 채널을 통해 API 키 전달
      await _channel.invokeMethod('initGoogleMaps', {'apiKey': apiKey});
      debugPrint('Google Maps API 초기화 성공');
    } catch (e) {
      debugPrint('Google Maps 초기화 실패: $e');
      // 오류 발생해도 계속 진행 (AppDelegate에서 이미 초기화했을 수 있음)
    }
  }
  
  // iOS에서 직접 위치 요청 (CoreLocation 사용)
  static Future<Map<String, dynamic>?> requestNativeLocation() async {
    try {
      if (!Platform.isIOS) return null;
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('requestLocation');
      if (result == null) return null;
      
      // dynamic 타입을 String, dynamic으로 변환
      return result.map((key, value) => MapEntry(key.toString(), value));
    } catch (e) {
      debugPrint('네이티브 위치 요청 실패: $e');
      return null;
    }
  }
  
  // 현재 위치가 샌프란시스코인지 체크 (테스트 위치인지 확인)
  static bool isSanFranciscoLocation(double lat, double lng) {
    const double threshold = 0.1; // 위치 오차 허용 범위
    
    return (lat - sanFranciscoLat).abs() < threshold && 
           (lng - sanFranciscoLng).abs() < threshold;
  }
}
