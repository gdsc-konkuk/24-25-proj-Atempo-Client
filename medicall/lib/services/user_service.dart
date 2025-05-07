import 'package:medicall/models/user_model.dart';
import 'package:medicall/services/api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  // 사용자 정보 조회 API
  Future<User> getUserInfo() async {
    try {
      final response = await _apiService.get('api/v1/members');
      
      // id와 accessToken은 기존 저장된 값을 사용해야 하므로
      // 여기서는 응답에서 필요한 정보만 추출하여 User 객체를 생성합니다.
      final userData = {
        ...response,
        'id': response['id'] ?? '', // API 응답에 id가 없을 경우 빈 문자열 사용
        'accessToken': '', // 기존 토큰을 유지
      };
      
      return User.fromJson(userData);
    } catch (e) {
      throw Exception('사용자 정보 조회 실패: $e');
    }
  }
} 