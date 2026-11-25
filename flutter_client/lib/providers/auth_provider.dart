import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = true;
  String? _authError;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  bool get isAuthenticated => _token != null && _user != null;
  bool get isDonor => _user?.role == 'donor';
  bool get isRequester => _user?.role == 'requester';
  bool get isAdmin => _user?.role == 'admin';

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await StorageService.getToken();
      _user = await StorageService.getUser();

      if (_token != null && _user != null) {
        _joinSocketRooms(_user!);
        // Refresh profile in background
        _refreshProfile();
      }
    } catch (_) {
      // Ignored
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _joinSocketRooms(UserModel u) {
    SocketService.joinUserRoom(u.id);
    if (u.isDonor && u.bloodGroup != null && u.bloodGroup!.isNotEmpty) {
      SocketService.joinBloodRoom(u.bloodGroup!);
    }
  }

  Future<void> _refreshProfile() async {
    if (_token == null) return;
    try {
      final updated = await ApiService.getMe(_token!);
      _user = updated;
      await StorageService.saveAuth(token: _token!, user: updated);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> login({
    required String email,
    required String password,
    String? role,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final res = await ApiService.login(email: email, password: password, role: role);
      _user = res['user'] as UserModel;
      _token = res['token'] as String;

      await StorageService.saveAuth(token: _token!, user: _user!);
      _joinSocketRooms(_user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _authError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Login failed. Please check server connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> payload) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final res = await ApiService.register(payload);
      _user = res['user'] as UserModel;
      _token = res['token'] as String;

      await StorageService.saveAuth(token: _token!, user: _user!);
      _joinSocketRooms(_user!);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _authError = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Registration failed. Please check server connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_user != null) {
      SocketService.leaveUserRoom(_user!.id);
    }
    _user = null;
    _token = null;
    await StorageService.clearAuth();
    notifyListeners();
  }

  void updateUser(UserModel updated) {
    _user = updated;
    if (_token != null) {
      StorageService.saveAuth(token: _token!, user: updated);
    }
    notifyListeners();
  }
}
