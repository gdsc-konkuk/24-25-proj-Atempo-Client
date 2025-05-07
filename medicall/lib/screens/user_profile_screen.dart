import 'package:flutter/material.dart';
import 'package:medicall/models/user_model.dart';
import 'package:medicall/services/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  User? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = await _userService.getUserInfo();
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '사용자 정보를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사용자 정보'),
        backgroundColor: const Color(0xFFD94B4B),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserInfo,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: const Color(0xFFD94B4B)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD94B4B),
                        ),
                        child: Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 64,
            backgroundColor: Colors.grey[200],
            backgroundImage: _user?.photoUrl != null
                ? NetworkImage(_user!.photoUrl!)
                : null,
            child: _user?.photoUrl == null
                ? Icon(Icons.person, size: 64, color: Colors.grey)
                : null,
          ),
        ),
        SizedBox(height: 24),
        _buildInfoCard(),
        SizedBox(height: 16),
        _buildCertificationCard(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기본 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD94B4B),
              ),
            ),
            Divider(height: 24),
            _buildInfoRow('이름', _user?.name ?? '-'),
            _buildInfoRow('이메일', _user?.email ?? '-'),
            _buildInfoRow('닉네임', _user?.nickName ?? '-'),
            _buildInfoRow('권한', _getRoleText(_user?.role)),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '인증 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD94B4B),
              ),
            ),
            Divider(height: 24),
            _buildInfoRow('인증 유형', _getCertificationTypeText(_user?.certificationType)),
            _buildInfoRow('인증 번호', _user?.certificationNumber ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleText(String? role) {
    if (role == null) return '-';

    switch (role) {
      case 'ADMIN':
        return '관리자';
      case 'USER':
        return '일반 사용자';
      default:
        return role;
    }
  }

  String _getCertificationTypeText(String? type) {
    if (type == null) return '-';

    switch (type) {
      case 'KOREA':
        return '한국 응급구조사';
      case 'US':
        return '미국 응급구조사';
      case 'EMT':
        return '응급구조사';
      default:
        return type;
    }
  }
} 