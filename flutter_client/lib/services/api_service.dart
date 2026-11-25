import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import '../models/notification_model.dart';
import '../models/admin_stats_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static Map<String, String> _headers([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = {'message': res.body};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      final msg = body is Map
          ? (body['message'] ?? body['error'] ?? 'Request failed (${res.statusCode})')
          : 'Request failed (${res.statusCode})';
      throw ApiException(msg.toString(), res.statusCode);
    }
  }

  // ==========================================
  // AUTH
  // ==========================================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
  }) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'password': password,
      if (role != null) 'role': role,
    };

    final res = await http.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: _headers(),
      body: jsonEncode(body),
    );

    final data = _handleResponse(res);
    final user = UserModel.fromJson(data['user']);
    final token = data['token'] as String;

    return {'user': user, 'token': token};
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse(ApiConfig.registerUrl),
      headers: _headers(),
      body: jsonEncode(payload),
    );

    final data = _handleResponse(res);
    final user = UserModel.fromJson(data['user']);
    final token = data['token'] as String;

    return {'user': user, 'token': token};
  }

  static Future<UserModel> getMe(String token) async {
    final res = await http.get(
      Uri.parse(ApiConfig.meUrl),
      headers: _headers(token),
    );
    final data = _handleResponse(res);
    return UserModel.fromJson(data['user']);
  }

  // ==========================================
  // DONORS
  // ==========================================
  static Future<List<UserModel>> searchDonors({
    String? bloodGroup,
    String? city,
    String? availability,
  }) async {
    final queryParams = <String, String>{};
    if (bloodGroup != null && bloodGroup.isNotEmpty) {
      queryParams['bloodGroup'] = bloodGroup;
    }
    if (city != null && city.trim().isNotEmpty) {
      queryParams['city'] = city.trim();
    }
    if (availability != null && availability.isNotEmpty) {
      queryParams['availability'] = availability;
    }

    final uri = Uri.parse(ApiConfig.donorSearchUrl).replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers());
    final data = _handleResponse(res);

    final list = data['donors'] as List? ?? [];
    return list.map((item) => UserModel.fromJson(item)).toList();
  }

  static Future<List<UserModel>> getAllDonors() async {
    final res = await http.get(Uri.parse(ApiConfig.allDonorsUrl), headers: _headers());
    final data = _handleResponse(res);
    final list = data['donors'] as List? ?? [];
    return list.map((item) => UserModel.fromJson(item)).toList();
  }

  static Future<Map<String, dynamic>> registerDonorLegacy(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse(ApiConfig.donorRegisterLegacyUrl),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getDonorAvailability(String token) async {
    final res = await http.get(
      Uri.parse(ApiConfig.donorAvailabilityMeUrl),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  static Future<UserModel> updateDonorAvailability(
    String token, {
    String? availability,
    String? lastDonationDate,
    bool? incrementDonationCount,
  }) async {
    final body = <String, dynamic>{};
    if (availability != null) body['availability'] = availability;
    if (lastDonationDate != null) body['lastDonationDate'] = lastDonationDate;
    if (incrementDonationCount != null) {
      body['incrementDonationCount'] = incrementDonationCount;
    }

    final res = await http.put(
      Uri.parse(ApiConfig.donorAvailabilityUrl),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = _handleResponse(res);
    return UserModel.fromJson(data['donor']);
  }

  static Future<Map<String, dynamic>> triggerAvailabilityReminders() async {
    final res = await http.post(
      Uri.parse(ApiConfig.donorRemindersTriggerUrl),
      headers: _headers(),
    );
    return _handleResponse(res);
  }

  // ==========================================
  // REQUESTS
  // ==========================================
  static Future<List<BloodRequestModel>> getRequests({
    String? bloodGroup,
    String? city,
    String? urgency,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (bloodGroup != null && bloodGroup.isNotEmpty) queryParams['bloodGroup'] = bloodGroup;
    if (city != null && city.trim().isNotEmpty) queryParams['city'] = city.trim();
    if (urgency != null && urgency.isNotEmpty) queryParams['urgency'] = urgency;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse(ApiConfig.requestsUrl).replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers());
    final data = _handleResponse(res);

    final list = data['requests'] as List? ?? [];
    return list.map((item) => BloodRequestModel.fromJson(item)).toList();
  }

  static Future<BloodRequestModel> createRequest(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse(ApiConfig.requestsUrl),
      headers: _headers(token),
      body: jsonEncode(payload),
    );
    final data = _handleResponse(res);
    return BloodRequestModel.fromJson(data['bloodRequest']);
  }

  static Future<BloodRequestModel> acceptRequest(String token, String requestId) async {
    final res = await http.put(
      Uri.parse(ApiConfig.requestAcceptUrl(requestId)),
      headers: _headers(token),
    );
    final data = _handleResponse(res);
    return BloodRequestModel.fromJson(data['bloodRequest']);
  }

  static Future<BloodRequestModel> updateRequestStatus(
    String token,
    String requestId,
    String status,
  ) async {
    final res = await http.put(
      Uri.parse(ApiConfig.requestStatusUrl(requestId)),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );
    final data = _handleResponse(res);
    return BloodRequestModel.fromJson(data['bloodRequest']);
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  static Future<Map<String, dynamic>> getNotifications(String token) async {
    final res = await http.get(
      Uri.parse(ApiConfig.notificationsUrl),
      headers: _headers(token),
    );
    final data = _handleResponse(res);
    final list = data['notifications'] as List? ?? [];
    final notifications = list.map((item) => NotificationModel.fromJson(item)).toList();
    final unreadCount = data['unreadCount'] is num
        ? (data['unreadCount'] as num).toInt()
        : 0;

    return {
      'notifications': notifications,
      'unreadCount': unreadCount,
    };
  }

  static Future<void> markNotificationRead(String token, String id) async {
    final res = await http.put(
      Uri.parse(ApiConfig.notificationReadUrl(id)),
      headers: _headers(token),
    );
    _handleResponse(res);
  }

  static Future<void> markAllNotificationsRead(String token) async {
    final res = await http.put(
      Uri.parse(ApiConfig.notificationsReadAllUrl),
      headers: _headers(token),
    );
    _handleResponse(res);
  }

  // ==========================================
  // ADMIN
  // ==========================================
  static Future<AdminStatsModel> getAdminStats(String token) async {
    final res = await http.get(
      Uri.parse(ApiConfig.adminStatsUrl),
      headers: _headers(token),
    );
    final data = _handleResponse(res);
    return AdminStatsModel.fromJson(data['stats']);
  }

  static Future<List<UserModel>> getAdminUsers(String token) async {
    final res = await http.get(
      Uri.parse(ApiConfig.adminUsersUrl),
      headers: _headers(token),
    );
    final data = _handleResponse(res);
    final list = data['users'] as List? ?? [];
    return list.map((item) => UserModel.fromJson(item)).toList();
  }
}
