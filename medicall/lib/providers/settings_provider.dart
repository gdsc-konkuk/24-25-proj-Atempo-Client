import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _searchRadius = 5.0; // Default value is 5km
  static const String _searchRadiusKey = 'search_radius';

  double get searchRadius => _searchRadius;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchRadius = prefs.getDouble(_searchRadiusKey) ?? 5.0;
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
      // Keep default settings if there's an error
    }
  }

  Future<void> setSearchRadius(double value) async {
    try {
      _searchRadius = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_searchRadiusKey, value);
      notifyListeners();
    } catch (e) {
      print('Error saving search radius: $e');
      // Handle error, possibly revert to previous value
    }
  }
}
