import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MapboxTokenHelper {
  /// 설치 문서 표시 다이얼로그
  static Future<void> showNetrcSetupDialog(BuildContext context) async {
    String secretToken = dotenv.env['MAPBOX_SECRET_TOKEN'] ?? '';
    if (secretToken.isEmpty || !secretToken.startsWith('sk.')) {
      secretToken = "유효한 Secret Token이 없습니다. Mapbox 계정에서 확인하세요.";
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('⚠️ MapBox SDK 설치 필요'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MapBox 내비게이션을 사용하려면 개발 환경에 인증 설정이 필요합니다:'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
'''1. 홈 디렉토리에서 .netrc 파일을 만드세요:
   touch ~/.netrc
   
2. 다음 내용을 추가하세요:
   machine api.mapbox.com
   login mapbox
   password $secretToken
   
3. 파일 권한을 설정하세요:
   chmod 600 ~/.netrc
   
4. iOS 폴더에서 pod install을 실행하세요:
   cd ios && pod install''',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              SizedBox(height: 16),
              Text('이 설정은 개발 환경에서 한 번만 필요합니다.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            child: Text('확인, 설정했습니다'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 앱 내에서 사용할 토큰 가져오기
  static String getMapboxPublicToken() {
    return dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';
  }
}
