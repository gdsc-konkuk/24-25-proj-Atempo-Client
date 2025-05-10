import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/http_client_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/location_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:medicall/services/env_service.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

// Set deep link URI scheme
const String CUSTOM_URI_SCHEME = 'medicall';

// Add global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await EnvService.load();
  
  // Initialize HTTP client service
  final httpClient = HttpClientService();
  await httpClient.initialize();

  // Set Mapbox token - Uncomment and modify if needed
  await dotenv.load(fileName: '.env');
  final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  if (mapboxToken.isNotEmpty) {
    print("Mapbox token loaded successfully");
  } else {
    print("Warning: Mapbox token is empty or not found in .env file");
  }
  
  // 로그 API BASE URL
  print('API_BASE_URL: ${dotenv.env['API_BASE_URL'] ?? '로드 실패'}');

  runApp(
    MultiProvider(
      providers: [
        Provider<HttpClientService>.value(value: httpClient),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
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
    // Handle deep link when the app was completely terminated
    try {
      _initialLink = await getInitialLink();
      if (_initialLink != null) {
        debugPrint('Initial deep link detected: $_initialLink');
        _handleDeepLink(_initialLink!);
      }
    } catch (e) {
      debugPrint('Error processing initial deep link: $e');
    }

    // Handle deep links when the app is in background or running
    _deepLinkSubscription = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('Deep link detected in background: $uri');
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) {
      debugPrint('Deep link stream error: $err');
    });
  }

  void _handleDeepLink(String link) {
    debugPrint('Deep link received: $link');
    
    // Extract authentication code from OAuth redirection URL
    // Example: medicall://auth?code=abc123
    if (link.contains('auth') && link.contains('code=')) {
      final uri = Uri.parse(link);
      final code = uri.queryParameters['code'];
      
      if (code != null) {
        debugPrint('Successfully extracted authentication code: $code');
        setState(() {
          _authCode = code;
        });
      }
    } else {
      debugPrint('Authentication code not found: $link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Added global key
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
          ? LoginScreen(code: _authCode) // If deep link contains code, navigate to login screen
          : SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
