import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AppConfig {
  AppConfig._();

  /// Default API URL pointing to the FastAPI backend.
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
      return '$scheme://$host:8000/api/v1';
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  // Active Base URL (can be updated at runtime for switching between mock and real API)
  static String activeBaseUrl = defaultBaseUrl;

  // Dev Accounts
  static const String devDriverUsername = 'driver@waypoint.com';
  static const String devLoaderUsername = 'loader@waypoint.com';
  static const String devPassword = 'pass123';

  // Simulated Offline toggle (debug helper)
  static bool simulatedOffline = false;

  /// MOCK ONLY: name of the Prism example to return for /auth/login and /me
  /// ('driver' | 'loader' | 'dispatcher'). Null = send nothing (real backend).
  static String? mockExample;

  /// Paths whose YAML responses have per-role named examples.
  static const Set<String> mockExamplePaths = {'/auth/login', '/me'};

  /// Returns device time formatted with Asia/Colombo (+05:30) offset in ISO-8601
  static String nowColomboIso() {
    final nowUtc = DateTime.now().toUtc();
    final colombo = nowUtc.add(const Duration(hours: 5, minutes: 30));
    final dateStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(colombo);
    return '$dateStr+05:30';
  }


  /// Formats date or ISO string to HH:mm in Asia/Colombo time
  static String formatClockTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    // If it's already HH:MM
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timeStr)) {
      return timeStr;
    }
    try {
      final dt = DateTime.parse(timeStr)
          .toUtc()
          .add(const Duration(hours: 5, minutes: 30));
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  /// Formats date to YYYY-MM-DD
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Today';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
