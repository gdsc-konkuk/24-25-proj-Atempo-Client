import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _searchRadius = 5.0; // 기본값
  
  // 검색 반경 getter
  double get searchRadius => _searchRadius;
  
  // 생성자에서 설정 불러오기
  SettingsProvider() {
    _loadSettings();
  }
  
  // 설정 불러오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _searchRadius = prefs.getDouble('search_radius') ?? 5.0;
    notifyListeners();
  }
  
  // 검색 반경 설정하기
  Future<void> setSearchRadius(double radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('search_radius', radius);
    _searchRadius = radius;
    notifyListeners();
  }
}
