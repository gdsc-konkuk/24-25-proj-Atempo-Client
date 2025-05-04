import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/http_client_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

// 딥링크 URI 스킴 설정
const String CUSTOM_URI_SCHEME = 'medicall';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // HTTP 클라이언트 서비스 초기화
  final httpClient = HttpClientService();
  await httpClient.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<HttpClientService>.value(value: httpClient),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _deepLinkSubscription;
  String? _initialLink;
  String? _authCode;
  
  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    // 앱이 완전히 종료된 상태였을 때의 딥링크 처리
    try {
      _initialLink = await getInitialLink();
      if (_initialLink != null) {
        debugPrint('앱 시작 시 딥링크 감지: $_initialLink');
        _handleDeepLink(_initialLink!);
      }
    } catch (e) {
      debugPrint('초기 딥링크 처리 오류: $e');
    }

    // 앱이 백그라운드에 있거나 실행 중일 때의 딥링크 처리
    _deepLinkSubscription = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('백그라운드에서 딥링크 감지: $uri');
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) {
      debugPrint('딥링크 스트림 오류: $err');
    });
  }

  void _handleDeepLink(String link) {
    debugPrint('딥링크 수신: $link');
    
    // OAuth 리디렉션 URL에서 인증 코드 추출
    // 예: medicall://auth?code=abc123
    if (link.contains('auth') && link.contains('code=')) {
      final uri = Uri.parse(link);
      final code = uri.queryParameters['code'];
      
      if (code != null) {
        debugPrint('인증 코드 추출 성공: $code');
        setState(() {
          _authCode = code;
        });
      }
    } else {
      debugPrint('인증 코드를 찾을 수 없음: $link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicall',
      theme: ThemeData(
        primaryColor: const Color(0xFFD94B4B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD94B4B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _authCode != null 
          ? LoginScreen(code: _authCode) // 딥링크에서 코드가 있으면 로그인 화면으로
          : SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
