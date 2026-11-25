import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ToastAlert {
  final String title;
  final String message;
  final String type;
  final String? urgency;

  ToastAlert({
    required this.title,
    required this.message,
    required this.type,
    this.urgency,
  });

  bool get isEmergency => type == 'EMERGENCY_ALERT' || urgency == 'Emergency' || urgency == 'Critical';
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  ToastAlert? _activeToast;
  Timer? _toastTimer;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  ToastAlert? get activeToast => _activeToast;

  NotificationProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    SocketService.onNotification((data) {
      final notifData = data['notification'] is Map<String, dynamic>
          ? data['notification'] as Map<String, dynamic>
          : data;

      try {
        final notif = NotificationModel.fromJson(notifData);
        _notifications.insert(0, notif);
        _unreadCount++;

        String? urgency;
        if (data['bloodRequest'] is Map) {
          urgency = data['bloodRequest']['urgency']?.toString();
        }

        showToast(ToastAlert(
          title: notif.title,
          message: notif.message,
          type: notif.type,
          urgency: urgency,
        ));
      } catch (_) {}

      notifyListeners();
    });

    SocketService.onEmergency((data) {
      showToast(ToastAlert(
        title: '🚨 CRITICAL EMERGENCY ALERT',
        message: data['message']?.toString() ?? 'Urgent blood needed immediately!',
        type: 'EMERGENCY_ALERT',
        urgency: 'Emergency',
      ), duration: const Duration(seconds: 8));
    });
  }

  void showToast(ToastAlert toast, {Duration duration = const Duration(seconds: 6)}) {
    _toastTimer?.cancel();
    _activeToast = toast;
    notifyListeners();

    _toastTimer = Timer(duration, () {
      _activeToast = null;
      notifyListeners();
    });
  }

  void dismissToast() {
    _toastTimer?.cancel();
    _activeToast = null;
    notifyListeners();
  }

  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getNotifications(token);
      _notifications = res['notifications'] as List<NotificationModel>;
      _unreadCount = res['unreadCount'] as int;
    } catch (_) {
      // Ignored
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String token, String id) async {
    try {
      await ApiService.markNotificationRead(token, id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].read) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead(String token) async {
    try {
      await ApiService.markAllNotificationsRead(token);
      _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _activeToast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
