import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapsService {
  static final MethodChannel _channel = MethodChannel('com.medicall/maps');
  
  static Future<void> initializeApiKey() async {
    try {
      // 직접 키 설정 (일관성을 위해)
      await _channel.invokeMethod('initGoogleMaps', {'apiKey': 'AIzaSyDeqCNi-eeLBLPbRNv2TsX2eIzuSSVO_7w'});
    } catch (e) {
      print('Failed to initialize Google Maps: $e');
      // 오류 발생해도 계속 진행 (AppDelegate에서 이미 초기화했으므로)
    }
  }
}
