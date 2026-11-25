import 'package:flutter/material.dart';
import '../models/blood_request_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class RequestProvider extends ChangeNotifier {
  List<BloodRequestModel> _requests = [];
  bool _isLoading = false;
  bool _actionLoading = false;
  String? _statusMessage;
  String? _errorMessage;

  List<BloodRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  bool get actionLoading => _actionLoading;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;

  RequestProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    SocketService.onRequestCreated((data) {
      if (data['bloodRequest'] is Map<String, dynamic>) {
        try {
          final newReq = BloodRequestModel.fromJson(data['bloodRequest']);
          _requests.removeWhere((r) => r.id == newReq.id);
          _requests.insert(0, newReq);
          notifyListeners();
        } catch (_) {}
      }
    });

    SocketService.onRequestAccepted((data) {
      final reqId = data['bloodRequestId']?.toString();
      final donorData = data['donor'] is Map<String, dynamic>
          ? data['donor'] as Map<String, dynamic>
          : null;

      if (reqId != null) {
        final index = _requests.indexWhere((r) => r.id == reqId);
        if (index != -1) {
          final old = _requests[index];
          _requests[index] = BloodRequestModel(
            id: old.id,
            requesterId: old.requesterId,
            requesterName: old.requesterName,
            requesterPhone: old.requesterPhone,
            requesterEmail: old.requesterEmail,
            patientName: old.patientName,
            hospitalName: old.hospitalName,
            bloodGroup: old.bloodGroup,
            unitsRequired: old.unitsRequired,
            urgency: old.urgency,
            city: old.city,
            address: old.address,
            contactPhone: old.contactPhone,
            notes: old.notes,
            status: 'Accepted',
            acceptedBy: donorData ?? old.acceptedBy,
            acceptedAt: DateTime.now(),
            createdAt: old.createdAt,
          );
          notifyListeners();
        }
      }
    });
  }

  void clearStatus() {
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchRequests({
    String? bloodGroup,
    String? city,
    String? urgency,
    String? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _requests = await ApiService.getRequests(
        bloodGroup: bloodGroup,
        city: city,
        urgency: urgency,
        status: status,
      );
    } catch (e) {
      _errorMessage = 'Failed to load blood requests: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest(String token, Map<String, dynamic> payload) async {
    _actionLoading = true;
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await ApiService.createRequest(token, payload);
      _requests.removeWhere((r) => r.id == created.id);
      _requests.insert(0, created);
      _statusMessage = 'Blood request posted successfully! Matching donors are being alerted.';
      _actionLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _actionLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create request: $e';
      _actionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptRequest(String token, String requestId) async {
    _actionLoading = true;
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await ApiService.acceptRequest(token, requestId);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updated;
      }
      _statusMessage = 'You have accepted this blood request! Requester notified.';
      _actionLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _actionLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to accept request: $e';
      _actionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String token, String requestId, String newStatus) async {
    _actionLoading = true;
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await ApiService.updateRequestStatus(token, requestId, newStatus);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updated;
      }
      _statusMessage = 'Request marked as $newStatus.';
      _actionLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _actionLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update request: $e';
      _actionLoading = false;
      notifyListeners();
      return false;
    }
  }
}
