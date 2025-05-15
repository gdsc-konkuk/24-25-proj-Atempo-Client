import 'package:medicall/models/user_model.dart';
import 'package:medicall/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // User information retrieval API
  Future<User> getUserInfo() async {
    try {
      final dynamic apiResponse = await _apiService.get('api/v1/members');
      final accessToken = await _storage.read(key: 'access_token') ?? '';
      
      // Retrieve stored ID in case the response doesn't have an ID
      final storedId = await _storage.read(key: 'user_id') ?? '';
      
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final Map<String, dynamic> response = {};
      if (apiResponse is Map) {
        apiResponse.forEach((key, value) {
          if (key is String) {
            response[key] = value;
          }
        });
      }
      
      // Merge API response with stored values
      final userData = <String, dynamic>{
        ...response,
        'id': response['id'] ?? storedId,
        'accessToken': accessToken,
      };
      
      return User.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to retrieve user information: $e');
    }
  }
  
  // User information update API (Using PATCH method)
  Future<User> updateUserInfo({
    String? nickName,
    String? role,
    String? certificationType,
    String? certificationNumber,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      // Only include fields that have values to change
      if (nickName != null) updateData['nick_name'] = nickName;
      if (role != null) updateData['role'] = role;
      if (certificationType != null) updateData['certification_type'] = certificationType;
      if (certificationNumber != null) updateData['certification_number'] = certificationNumber;
      
      if (updateData.isEmpty) {
        throw Exception('No information to update.');
      }
      
      // Update user information with PATCH method
      final response = await _apiService.patch('api/v1/members', updateData);
      
      if (response == null) {
        throw Exception('No server response.');
      }
      
      // Return updated user information
      return await getUserInfo();
    } catch (e) {
      throw Exception('Failed to update user information: $e');
    }
  }
  
  // User role update API (Using PATCH method)
  Future<User> updateUserRole(String userId, String newRole) async {
    try {
      // Update user role with PATCH method
      final response = await _apiService.patch('api/v1/members/$userId/role', {
        'role': newRole
      });
      
      if (response == null) {
        throw Exception('No server response.');
      }
      
      // Return updated user information
      return await getUserInfo();
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }
} 