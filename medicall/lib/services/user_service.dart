import 'package:medicall/models/user_model.dart';
import 'package:medicall/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // 사용자 정보 조회 API
  Future<User> getUserInfo() async {
    try {
      final dynamic apiResponse = await _apiService.get('api/v1/members');
      final accessToken = await _storage.read(key: 'access_token') ?? '';
      
      // 응답에 id가 없을 경우를 대비해 저장된 ID 조회
      final storedId = await _storage.read(key: 'user_id') ?? '';
      
      // Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
      final Map<String, dynamic> response = {};
      if (apiResponse is Map) {
        apiResponse.forEach((key, value) {
          if (key is String) {
            response[key] = value;
          }
        });
      }
      
      // API 응답과 저장된 값을 병합
      final userData = <String, dynamic>{
        ...response,
        'id': response['id'] ?? storedId,
        'accessToken': accessToken,
      };
      
      return User.fromJson(userData);
    } catch (e) {
      throw Exception('사용자 정보 조회 실패: $e');
    }
  }
  
  // 사용자 정보 업데이트 API (PATCH 메서드 사용)
  Future<User> updateUserInfo({
    String? nickName,
    String? role,
    String? certificationType,
    String? certificationNumber,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      // 변경할 값이 있는 필드만 포함
      if (nickName != null) updateData['nick_name'] = nickName;
      if (role != null) updateData['role'] = role;
      if (certificationType != null) updateData['certification_type'] = certificationType;
      if (certificationNumber != null) updateData['certification_number'] = certificationNumber;
      
      if (updateData.isEmpty) {
        throw Exception('업데이트할 정보가 없습니다.');
      }
      
      // PATCH 메서드로 사용자 정보 업데이트
      final response = await _apiService.patch('api/v1/members', updateData);
      
      if (response == null) {
        throw Exception('서버 응답이 없습니다.');
      }
      
      // 업데이트된 사용자 정보 반환
      return await getUserInfo();
    } catch (e) {
      throw Exception('사용자 정보 업데이트 실패: $e');
    }
  }
  
  // 사용자 역할 변경 API (PATCH 메서드 사용)
  Future<User> updateUserRole(String userId, String newRole) async {
    try {
      // PATCH 메서드로 사용자 역할 업데이트
      final response = await _apiService.patch('api/v1/members/$userId/role', {
        'role': newRole
      });
      
      if (response == null) {
        throw Exception('서버 응답이 없습니다.');
      }
      
      // 업데이트된 사용자 정보 반환
      return await getUserInfo();
    } catch (e) {
      throw Exception('사용자 역할 업데이트 실패: $e');
    }
  }
} 