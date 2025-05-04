import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MapboxUtils {
  // Get the public token (can be used in UI aspects)
  static String getPublicToken() {
    return dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';
  }
  
  // Get the access token (used for API calls)
  static String getAccessToken() {
    return dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? getPublicToken();
  }
  
  // Updated: Get the token for downloading SDK (now using access token)
  static String getSecretToken() {
    // Use the access token for downloads since only public and access tokens are provided.
    return getAccessToken();
  }
  
  // Initialize tokens for Mapbox Navigation
  static Future<void> initMapboxTokens() async {
    await dotenv.load();
    final publicToken = getPublicToken();
    final accessToken = getAccessToken();
    print("Mapbox Public Token: ${publicToken.substring(0, 10)}...");
    print("Mapbox Access Token: ${accessToken.isNotEmpty ? '${accessToken.substring(0, 10)}...' : 'Not found'}");
  }
  
  // Update: Create documentation for setting up .netrc file using the access token.
  static Future<String> createNetrcInstructions() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/mapbox_setup_instructions.txt';
    final accessToken = getAccessToken();
    
    final instructions = '''
Mapbox Navigation SDK 설치 가이드

1. 홈 디렉토리로 이동:
   cd ~

2. .netrc 파일 생성 또는 편집:
   touch ~/.netrc

3. 다음 내용 추가 (기존 내용이 있다면 아래만 추가):
   machine api.mapbox.com
     login mapbox
     password ${accessToken.isNotEmpty ? accessToken : "여기에_ACCESS_TOKEN을_입력하세요"}

4. 권한 설정 (보안상 필수):
   chmod 600 ~/.netrc

5. iOS 프로젝트 폴더로 이동하여 pod install 실행:
   cd ios
   pod install

주의: 이 Access Token은 절대 앱 코드에 포함시키지 마세요.
''';

    final file = File(filePath);
    await file.writeAsString(instructions);
    return filePath;
  }
}
