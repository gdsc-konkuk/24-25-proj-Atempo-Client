class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String accessToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.accessToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      accessToken: json['accessToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
    };
  }
}

// OAuth 로그인 결과를 처리하기 위한 클래스
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
