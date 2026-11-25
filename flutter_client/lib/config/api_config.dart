import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _defaultWebPort = '5000';
  static const String _serverUrlKey = 'bloodbridge_custom_server_url';

  static String _customBaseUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customBaseUrl = prefs.getString(_serverUrlKey) ?? '';
  }

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:$_defaultWebPort';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps 10.0.2.2 to host machine's localhost
      return 'http://10.0.2.2:$_defaultWebPort';
    }
    return 'http://localhost:$_defaultWebPort';
  }

  static Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_customBaseUrl.isEmpty) {
      await prefs.remove(_serverUrlKey);
    } else {
      await prefs.setString(_serverUrlKey, _customBaseUrl);
    }
  }

  static bool get isCustomUrlSet => _customBaseUrl.isNotEmpty;

  // Authentication
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerUrl => '$baseUrl/api/auth/register';
  static String get meUrl => '$baseUrl/api/auth/me';

  // Donors
  static String get donorSearchUrl => '$baseUrl/api/donors/search';
  static String get allDonorsUrl => '$baseUrl/api/donors';
  static String get donorRegisterLegacyUrl => '$baseUrl/api/donors/register';
  static String get donorAvailabilityMeUrl => '$baseUrl/api/donors/availability/me';
  static String get donorAvailabilityUrl => '$baseUrl/api/donors/availability';
  static String get donorProfileUrl => '$baseUrl/api/donors/profile';
  static String get donorRemindersTriggerUrl => '$baseUrl/api/donors/availability/reminders/trigger';

  // Requests
  static String get requestsUrl => '$baseUrl/api/requests';
  static String get myRequestsUrl => '$baseUrl/api/requests/my';
  static String requestAcceptUrl(String id) => '$baseUrl/api/requests/$id/accept';
  static String requestStatusUrl(String id) => '$baseUrl/api/requests/$id/status';

  // Notifications
  static String get notificationsUrl => '$baseUrl/api/notifications';
  static String notificationReadUrl(String id) => '$baseUrl/api/notifications/$id/read';
  static String get notificationsReadAllUrl => '$baseUrl/api/notifications/read-all';

  // Admin
  static String get adminStatsUrl => '$baseUrl/api/admin/stats';
  static String get adminUsersUrl => '$baseUrl/api/admin/users';
}
