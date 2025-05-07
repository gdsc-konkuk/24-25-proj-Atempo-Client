import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../services/http_client_service.dart';
import 'map_screen.dart';
import 'login_screen.dart';
import 'dart:convert';

class EmtLicenseVerificationScreen extends StatefulWidget {
  const EmtLicenseVerificationScreen({Key? key}) : super(key: key);

  @override
  _EmtLicenseVerificationScreenState createState() => _EmtLicenseVerificationScreenState();
}

class _EmtLicenseVerificationScreenState extends State<EmtLicenseVerificationScreen> {
  final storage = FlutterSecureStorage();
  String dropdownValue = 'NREMT';
  final TextEditingController _licenseController = TextEditingController();
  String? _errorText;
  bool _isVerifying = false;
  String? _verificationMessage;
  bool _isVerificationError = false;
  
  // Define the license types and their formats
  final Map<String, String> licenseFormats = {
    'NREMT': 'Alphanumeric (e.g., GDG143, MED911)',
    'EMT(KOREA)': '제 + 6 digits + 호 (e.g., 제123456호)',
    'EMS': '12 digits (e.g., 123456789012)',
  };
  
  @override
  void initState() {
    super.initState();
    _licenseController.addListener(_validateInput);
    _setupAuthToken();
  }

  Future<void> _setupAuthToken() async {
    try {
      print('EMT 화면: 인증 토큰 설정 시작');
      final accessToken = await storage.read(key: 'access_token');
      print('EMT 화면: 현재 액세스 토큰 - ${accessToken != null ? "토큰 있음" : "토큰 없음"}');
      
      if (accessToken != null) {
        // HttpClientService와 AuthProvider 모두 토큰 설정
        final httpClient = Provider.of<HttpClientService>(context, listen: false);
        httpClient.setAuthorizationHeader('Bearer $accessToken');
        print("EMT 화면: HttpClient에 인증 헤더 설정됨 - ${httpClient.getHeaders()}");
        
        // 인증 상태 확인을 위해 AuthProvider 업데이트
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.loadCurrentUser();
          print('EMT 화면: AuthProvider 사용자 정보 로드됨');
        } catch (e) {
          print('EMT 화면: 사용자 정보 로드 실패, 계속 진행: $e');
        }
      } else {
        print('EMT 화면: 액세스 토큰이 없어서 인증 헤더를 설정할 수 없음');
      }
    } catch (e) {
      print("EMT 화면: 인증 토큰 설정 중 오류 발생 - $e");
    }
  }

  @override
  void dispose() {
    _licenseController.removeListener(_validateInput);
    _licenseController.dispose();
    super.dispose();
  }
  
  void _validateInput() {
    setState(() {
      _errorText = null;
      
      if (_licenseController.text.isEmpty) {
        return;
      }
    });
  }
  
  String getHintText() {
    switch (dropdownValue) {
      case 'NREMT':
        return 'Enter your NREMT license number';
      case 'EMT(KOREA)':
        return 'Enter your Korean EMT license number';
      case 'EMS':
        return 'Enter your EMS license number';
      default:
        return '';
    }
  }
  
  void _onDropdownChanged(String? newValue) {
    if (newValue != null && newValue != dropdownValue) {
      setState(() {
        dropdownValue = newValue;
        _licenseController.clear();
        _errorText = null;
      });
    }
  }
  
  // Format license number for submission
  String _formatLicenseForSubmission() {
    return _licenseController.text.trim();
  }
  
  Future<void> _verifyLicense() async {
    final formattedLicense = _formatLicenseForSubmission();
    
    if (_errorText != null || formattedLicense.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid license number'),
          backgroundColor: Colors.red,
        )
      );
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _verificationMessage = null;
      _isVerificationError = false;
    });
    
    try {
      final httpClient = Provider.of<HttpClientService>(context, listen: false);
      
      // 요청 전 헤더와 바디 로깅
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      
      print('EMT 화면: 인증 전 토큰 - 액세스 토큰: ${accessToken != null ? "있음" : "없음"}, 리프레시 토큰: ${refreshToken != null ? "있음" : "없음"}');
      
      if (accessToken != null) {
        httpClient.setAuthorizationHeader('Bearer $accessToken');
      }
      
      final requestBody = {
        'certification_type': dropdownValue,
        'certification_number': formattedLicense,
      };
      
      final endpoint = 'members/certification';
      final url = httpClient.buildUrl(endpoint);
      
      print('EMT 화면: 요청 헤더 - ${httpClient.getHeaders()}');
      print('EMT 화면: 요청 바디 - $requestBody');
      print('EMT 화면: 요청 URL - $url');
      
      // Send license verification request to server
      final response = await httpClient.patch(
        endpoint,
        jsonEncode(requestBody),
      );
      
      print('EMT 화면: 응답 상태 코드 - ${response.statusCode}');
      print('EMT 화면: 응답 본문 - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // AuthProvider를 통해 사용자 정보 업데이트
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // 현재 토큰 다시 확인
        final updatedAccessToken = await storage.read(key: 'access_token');
        final updatedRefreshToken = await storage.read(key: 'refresh_token');
        print('EMT 화면: 인증 성공 후 토큰 - 액세스 토큰: ${updatedAccessToken != null ? "있음" : "없음"}, 리프레시 토큰: ${updatedRefreshToken != null ? "있음" : "없음"}');
        
        // 토큰이 없거나 만료된 경우를 대비해 먼저 확인
        if (updatedAccessToken == null || updatedAccessToken.isEmpty) {
          print('EMT 화면: 액세스 토큰이 없어 로그인 화면으로 이동합니다.');
          setState(() {
            _isVerifying = false;
            _verificationMessage = '인증 세션이 만료되었습니다. 다시 로그인해주세요.';
            _isVerificationError = true;
          });
          
          // 잠시 후 로그인 화면으로 이동
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              // 모든 화면을 제거하고 로그인 화면으로 이동
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            }
          });
          return;
        }
        
        // HttpClient 갱신
        httpClient.setAuthorizationHeader('Bearer $updatedAccessToken');
        if (updatedRefreshToken != null) {
          httpClient.updateRefreshToken(updatedRefreshToken);
        }
        
        // 사용자 정보 다시 로드
        await authProvider.loadCurrentUser();
        print('EMT 화면: 사용자 정보 업데이트 완료');
        
        setState(() {
          _isVerifying = false;
          _verificationMessage = '자격증 인증이 성공적으로 완료되었습니다.';
        });
        
        // 잠시 기다린 후 지도 화면으로 이동
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            // 백스택을 정리하고 새로운 MapScreen으로 이동
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => MapScreen()),
              (route) => false,
            );
          }
        });
      } else {
        final errorData = jsonDecode(response.body);
        print('EMT 화면: 오류 데이터 - $errorData');
        setState(() {
          _isVerifying = false;
          _verificationMessage = errorData['message'] ?? '자격증 인증에 실패했습니다. 다시 시도해주세요.';
          _isVerificationError = true;
        });
      }
    } catch (e, stackTrace) {
      print('EMT 화면: 인증 중 오류 발생 - $e');
      print('EMT 화면: 스택 트레이스 - $stackTrace');
      setState(() {
        _isVerifying = false;
        _verificationMessage = '자격증 인증 중 오류가 발생했습니다: $e';
        _isVerificationError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Title
              Text(
                'Enter Your',
                style: GoogleFonts.notoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'EMT License Number',
                style: GoogleFonts.notoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'This service is only available for certified EMTs.',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              // License type dropdown and text field
              Row(
                children: [
                  // Dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: _onDropdownChanged,
                        items: <String>['NREMT', 'KOREA', 'EMS']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // License number text field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _errorText != null ? Colors.red : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _licenseController,
                        decoration: InputDecoration(
                          hintText: getHintText(),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          errorText: _errorText,
                          errorStyle: const TextStyle(
                            fontSize: 0,
                            height: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                  child: Text(
                    _errorText!,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // License format hint
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Format: ${licenseFormats[dropdownValue]}',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (_verificationMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: Text(
                    _verificationMessage!,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: _isVerificationError ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              // "Don't know your license number?" link
              Center(
                child: GestureDetector(
                  onTap: () {
                    // No functionality as requested
                  },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't know your license number? ",
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        TextSpan(
                          text: 'Learn more',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyLicense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD94B4B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isVerifying
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                      'Verify License',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom formatter to convert all text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
