// ...existing imports and code...
class MapsService {
  // ...existing declarations...
  
  // Test location (San Francisco) - if this appears, actual location was not retrieved
  static const double sanFranciscoLat = 37.7749;
  static const double sanFranciscoLng = -122.4194;
  
  // Set default location as Seoul
  static const double defaultLatitude = 37.5665;
  static const double defaultLongitude = 126.9780;
  
  static Future<void> initializeApiKey() async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint("Google Maps API key is missing or empty in the .env file.");
        return;
      }
      
      await _channel.invokeMethod('initGoogleMaps', {'apiKey': apiKey});
      debugPrint("Google Maps API initialization succeeded.");
    } catch (e) {
      debugPrint("Google Maps initialization failed: $e");
    }
  }
  
  static Future<Map<String, dynamic>?> requestNativeLocation() async {
    try {
      if (!Platform.isIOS) return null;
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('requestLocation');
      if (result == null) return null;
      
      return result.map((key, value) => MapEntry(key.toString(), value));
    } catch (e) {
      debugPrint("Failed to request native location: $e");
      return null;
    }
  }
  
  static bool isSanFranciscoLocation(double lat, double lng) {
    const double threshold = 0.1;
    return (lat - sanFranciscoLat).abs() < threshold && (lng - sanFranciscoLng).abs() < threshold;
  }
}
