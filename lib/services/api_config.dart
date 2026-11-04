import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Production API URL hosted on Dewacloud
  static const String productionBaseUrl =
      'https://env-opentask.user.cloudjkt02.com/api/convena';

  /// Development URL for Android Emulator (10.0.2.2 routes to the host machine)
  static const String devAndroidEmulatorUrl = 'http://10.0.2.2:8000';

  /// Development URL for iOS Simulator, Web, or Desktop
  static const String devDefaultUrl = 'http://127.0.0.1:8000';

  /// Resolves the appropriate base URL based on runtime environment.
  /// 
  /// 1. Prioritizes build-time flag: `--dart-define=API_URL=...`
  /// 2. If in release mode (`kReleaseMode`), points to production Dewacloud
  /// 3. In debug mode (`kDebugMode`), points to local host machine
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl.replaceAll(RegExp(r'/+$'), '');
    }

    if (kReleaseMode) {
      return productionBaseUrl;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return devAndroidEmulatorUrl;
    }

    return devDefaultUrl;
  }
}

