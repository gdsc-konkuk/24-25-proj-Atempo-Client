import 'package:flutter/material.dart';
import 'package:medicall/models/user_model.dart';
import 'package:medicall/services/user_service.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  bool _isLoading = true;
  bool _isLoggingOut = false;
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
        _error = 'Failed to load user information: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // 서버에 로그아웃 요청 보내기
      await _apiService.delete('api/v1/auth/logout');
      
      // 로컬 저장소에서 토큰 제거
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      
      // AuthProvider 상태 업데이트
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      // 로그인 화면으로 이동
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      setState(() {
        _isLoggingOut = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: $e'))
      );
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.pretendard(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.pretendard(
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.pretendard(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text(
                'Logout',
                style: GoogleFonts.pretendard(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.buildAppBar(
        title: 'User Profile',
        leading: AppTheme.buildBackButton(context),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserInfo,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.errorColor),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _buildUserProfile(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isLoggingOut
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.errorColor,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _showLogoutConfirmation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.pretendard(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
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
                ? Icon(Icons.person, size: 64, color: AppTheme.primaryColor)
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
              'Profile Details',
              style: GoogleFonts.pretendard(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(height: 24),
            _buildInfoRow('Name', _user?.name ?? '-'),
            _buildInfoRow('Email', _user?.email ?? '-'),
            _buildInfoRow('Role', _getRoleText(_user?.role)),
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
              'Certification Information',
              style: GoogleFonts.pretendard(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Divider(height: 24),
            _buildInfoRow('Certification Type', _getCertificationTypeText(_user?.certificationType)),
            _buildInfoRow('Certification Number', _user?.certificationNumber ?? '-'),
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
              style: GoogleFonts.pretendard(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.pretendard(
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
        return 'Emergency Medical Technician';
      case 'USER':
        return 'Regular User';
      default:
        return role;
    }
  }

  String _getCertificationTypeText(String? type) {
    if (type == null) return '-';

    switch (type) {
      case 'KOREA':
        return 'Korean EMT';
      case 'US':
        return 'US EMT';
      case 'EMT':
        return 'EMT';
      default:
        return type;
    }
  }
} 