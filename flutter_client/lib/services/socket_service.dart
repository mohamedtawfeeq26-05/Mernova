import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

typedef SocketNotificationCallback = void Function(Map<String, dynamic> data);
typedef SocketEmergencyCallback = void Function(Map<String, dynamic> data);
typedef SocketRequestCreatedCallback = void Function(Map<String, dynamic> data);
typedef SocketRequestAcceptedCallback = void Function(Map<String, dynamic> data);
typedef SocketAvailabilityCallback = void Function(Map<String, dynamic> data);

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  static final List<SocketNotificationCallback> _notificationListeners = [];
  static final List<SocketEmergencyCallback> _emergencyListeners = [];
  static final List<SocketRequestCreatedCallback> _requestCreatedListeners = [];
  static final List<SocketRequestAcceptedCallback> _requestAcceptedListeners = [];
  static final List<SocketAvailabilityCallback> _availabilityListeners = [];

  static bool get isConnected => _isConnected;

  static void init() {
    if (_socket != null) {
      _socket?.dispose();
    }

    try {
      _socket = IO.io(
        ApiConfig.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('⚡ Flutter Socket.IO connected: ${_socket?.id}');
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint('🔌 Flutter Socket.IO disconnected');
      });

      _socket?.onConnectError((err) {
        debugPrint('❌ Flutter Socket.IO connection error: $err');
      });

      // Events from Server
      _socket?.on('new_notification', (data) {
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          for (final listener in _notificationListeners) {
            listener(map);
          }
        }
      });

      _socket?.on('emergency_broadcast', (data) {
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          for (final listener in _emergencyListeners) {
            listener(map);
          }
        }
      });

      _socket?.on('blood_request_created', (data) {
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          for (final listener in _requestCreatedListeners) {
            listener(map);
          }
        }
      });

      _socket?.on('request_accepted', (data) {
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          for (final listener in _requestAcceptedListeners) {
            listener(map);
          }
        }
      });

      _socket?.on('availability_updated', (data) {
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          for (final listener in _availabilityListeners) {
            listener(map);
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing SocketService: $e');
    }
  }

  // Room Join Methods
  static void joinUserRoom(String userId) {
    if (_socket != null && userId.isNotEmpty) {
      _socket?.emit('join_user_room', userId);
      debugPrint('👤 Emitted join_user_room for user_$userId');
    }
  }

  static void leaveUserRoom(String userId) {
    if (_socket != null && userId.isNotEmpty) {
      _socket?.emit('leave_user_room', userId);
      debugPrint('Emitted leave_user_room for user_$userId');
    }
  }

  static void joinBloodRoom(String bloodGroup) {
    if (_socket != null && bloodGroup.isNotEmpty) {
      _socket?.emit('join_blood_room', bloodGroup);
      debugPrint('🩸 Emitted join_blood_room for blood_$bloodGroup');
    }
  }

  // Listener subscriptions
  static void onNotification(SocketNotificationCallback cb) => _notificationListeners.add(cb);
  static void offNotification(SocketNotificationCallback cb) => _notificationListeners.remove(cb);

  static void onEmergency(SocketEmergencyCallback cb) => _emergencyListeners.add(cb);
  static void offEmergency(SocketEmergencyCallback cb) => _emergencyListeners.remove(cb);

  static void onRequestCreated(SocketRequestCreatedCallback cb) => _requestCreatedListeners.add(cb);
  static void offRequestCreated(SocketRequestCreatedCallback cb) => _requestCreatedListeners.remove(cb);

  static void onRequestAccepted(SocketRequestAcceptedCallback cb) => _requestAcceptedListeners.add(cb);
  static void offRequestAccepted(SocketRequestAcceptedCallback cb) => _requestAcceptedListeners.remove(cb);

  static void onAvailabilityUpdated(SocketAvailabilityCallback cb) => _availabilityListeners.add(cb);
  static void offAvailabilityUpdated(SocketAvailabilityCallback cb) => _availabilityListeners.remove(cb);
}
