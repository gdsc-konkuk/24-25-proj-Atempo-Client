import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _searchRadius = 5.0; // default value
  
  // Getter for search radius
  double get searchRadius => _searchRadius;
  
  // Load settings in constructor
  SettingsProvider() {
    _loadSettings();
  }
  
  // Load settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _searchRadius = prefs.getDouble('search_radius') ?? 5.0;
    notifyListeners();
  }
  
  // Set search radius
  Future<void> setSearchRadius(double radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('search_radius', radius);
    _searchRadius = radius;
    notifyListeners();
  }
}
