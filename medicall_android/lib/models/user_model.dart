class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String accessToken;
  final String? role;  // Added role field
  final String? nickName;  // Added nickname field
  final String? certificationType;  // Added certification type field
  final String? certificationNumber;  // Added certification number field

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.accessToken,
    this.role,
    this.nickName,
    this.certificationType,
    this.certificationNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'] ?? json['profile_url'],
      accessToken: json['accessToken'] ?? '',
      role: json['role'],
      nickName: json['nick_name'],
      certificationType: json['certification_type'],
      certificationNumber: json['certification_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
      'role': role,
      'nick_name': nickName,
      'certification_type': certificationType,
      'certification_number': certificationNumber,
    };
  }
}

// Class to handle OAuth login results
class OAuthLoginResult {
  final String loginUrl;
  final String baseUrl;
  final Future<User> Function(Map<String, dynamic> authData) onLoginSuccess;

  OAuthLoginResult({
    required this.loginUrl,
    required this.baseUrl,
    required this.onLoginSuccess,
  });
}
