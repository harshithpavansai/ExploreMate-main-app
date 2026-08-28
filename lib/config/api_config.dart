import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  // Set this to your host computer's local Wi-Fi IP if you are testing on a physical mobile phone
  static const String hostIp = '172.20.130.40';

  // Toggle this to true when testing on a physical Android/iOS phone instead of an emulator
  static const bool usePhysical = true;

  static String get defaultLocalUrl {
    if (kIsWeb) return 'http://localhost:5000/api/v1';
    
    if (usePhysical) {
      return 'http://$hostIp:5000/api/v1';
    }

    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/api/v1';
    } catch (_) {}
    return 'http://localhost:5000/api/v1';
  }

  static const String renderBaseUrl = 'https://exploremate-backend.onrender.com/api/v1';

  static String activeBaseUrl = defaultLocalUrl;

  /// Helper to get a full URI from a path suffix
  static Uri getUri(String path) {
    // Ensure standard slash structure
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$activeBaseUrl$cleanPath');
  }

  /// Switch the active base URL between local and Render fallback
  static void useBackupUrl() {
    activeBaseUrl = renderBaseUrl;
  }
}
