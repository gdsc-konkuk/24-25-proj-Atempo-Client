import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicall/utils/mapbox_utils.dart';

class MapboxSetupScreen extends StatefulWidget {
  const MapboxSetupScreen({Key? key}) : super(key: key);

  @override
  _MapboxSetupScreenState createState() => _MapboxSetupScreenState();
}

class _MapboxSetupScreenState extends State<MapboxSetupScreen> {
  String _setupInstructions = '';
  String _secretToken = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructions();
  }

  Future<void> _loadInstructions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await MapboxUtils.initMapboxTokens();
      _secretToken = MapboxUtils.getSecretToken();
      
      if (_secretToken.isEmpty || !_secretToken.startsWith('sk.')) {
        // Secret 토큰이 없는 경우 사용자에게 알림
        setState(() {
          _setupInstructions = '''
⚠️ Mapbox Secret Token이 없습니다!

Mapbox 계정에서 sk.로 시작하는 Secret Token을 발급받아 .env 파일에 추가해주세요:
MAPBOX_SECRET_TOKEN=sk.your_secret_token_here

Secret Token을 발급받는 방법:
1. Mapbox 계정(https://account.mapbox.com)에 로그인합니다.
2. Access Tokens 메뉴로 이동합니다.
3. 'Create a token' 버튼을 클릭합니다.
4. 'Secret' 스코프가 포함된 토큰을 생성합니다.
5. 생성된 sk.로 시작하는 토큰을 .env 파일에 추가합니다.
''';
          _isLoading = false;
        });
        return;
      }
      
      String instructions = '''
1. 홈 디렉토리로 이동:
   cd ~

2. .netrc 파일 생성 또는 편집:
   touch .netrc

3. 다음 내용 추가 (기존 내용이 있다면 아래만 추가):
   machine api.mapbox.com
     login mapbox
     password $_secretToken

4. 권한 설정 (보안상 필수):
   chmod 600 ~/.netrc

5. iOS 프로젝트 폴더로 이동하여 pod install 실행:
   cd ios
   pod install
''';

      setState(() {
        _setupInstructions = instructions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _setupInstructions = '설정 정보를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapbox 설정 안내'),
        backgroundColor: Color(0xFFE93C4A),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ Mapbox Navigation SDK 설치 오류',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mapbox Navigation SDK를 사용하려면 .netrc 파일에 인증 정보를 설정해야 합니다. 아래 안내를 따라 진행해주세요.',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '설정 방법',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      _setupInstructions,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _setupInstructions),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('클립보드에 복사되었습니다')),
                          );
                        },
                        icon: Icon(Icons.copy),
                        label: Text('지침 복사'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _secretToken),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Secret Token이 복사되었습니다')),
                          );
                        },
                        icon: Icon(Icons.vpn_key),
                        label: Text('Secret Token 복사'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Card(
                    elevation: 4,
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ 보안 주의사항',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Secret Token은 절대 앱 코드에 직접 포함시키지 마세요.\n'
                            '• .netrc 파일은 시스템 파일이므로 chmod 600으로 권한을 제한하세요.\n'
                            '• 앱 내에서는 Public Token만 사용하세요.',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('확인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE93C4A),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
