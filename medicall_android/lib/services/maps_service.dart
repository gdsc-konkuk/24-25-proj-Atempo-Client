import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class MapsService {
  static final MethodChannel _channel = MethodChannel('com.medicall/maps');
  
  // San Francisco location (test location) - If this location appears, it means we couldn't retrieve the actual location
  static const double sanFranciscoLat = 37.7749;
  static const double sanFranciscoLng = -122.4194;
  
  // Set default location to Seoul
  static const double defaultLatitude = 37.5665;
  static const double defaultLongitude = 126.9780;
  
  static Future<void> initializeApiKey() async {
    try {
      // Get API key from .env file
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('Google Maps API key is missing or empty in .env file.');
        return;
      }
      
      // Pass API key through platform channel
      await _channel.invokeMethod('initGoogleMaps', {'apiKey': apiKey});
      debugPrint('Google Maps API initialization successful');
    } catch (e) {
      debugPrint('Google Maps initialization failed: $e');
      // Continue even if error occurs (might have already been initialized in AppDelegate)
    }
  }
  
  // Request location directly from iOS (using CoreLocation)
  static Future<Map<String, dynamic>?> requestNativeLocation() async {
    try {
      if (!Platform.isIOS) return null;
      
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('requestLocation');
      if (result == null) return null;
      
      // Convert dynamic type to String, dynamic
      return result.map((key, value) => MapEntry(key.toString(), value));
    } catch (e) {
      debugPrint('Native location request failed: $e');
      return null;
    }
  }
  
  // Check if current location is San Francisco (verify if it's a test location)
  static bool isSanFranciscoLocation(double lat, double lng) {
    // Location error tolerance
    const double threshold = 0.1;
    
    return (lat - sanFranciscoLat).abs() < threshold && 
           (lng - sanFranciscoLng).abs() < threshold;
  }
}
