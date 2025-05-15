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
          
          // Improve address formatting
          final List<String> addressComponents = [];
          
          // Create function: add only non-empty strings
          void addIfValid(String? component) {
            if (component != null && component.trim().isNotEmpty) {
              // Check if the component is not already in the list
              if (!addressComponents.contains(component.trim())) {
                addressComponents.add(component.trim());
              }
            }
          }
          
          // Add subThoroughfare first (more specific information)
          addIfValid(placemark.subThoroughfare);
          addIfValid(placemark.thoroughfare);
          addIfValid(placemark.subLocality);
          addIfValid(placemark.locality);
          addIfValid(placemark.administrativeArea);
          addIfValid(placemark.country);
          
          // Check for empty strings and remove them
          final filteredComponents = addressComponents.where((c) => c.isNotEmpty).toList();
          
          // If address components are empty, set default value
          if (filteredComponents.isEmpty) {
            _address = "Location at ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
          } else {
            // Display in reverse order (country, region, city, street)
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