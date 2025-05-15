import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
  
  static String get mapboxPublicToken {
    return dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';
  }
  
  static String get mapboxSecretToken {
    return dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  }
}
