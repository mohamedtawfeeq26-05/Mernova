import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class DonorProvider extends ChangeNotifier {
  // Donor Search State
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchMessage;

  List<UserModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchMessage => _searchMessage;

  // Donor Availability State
  String _availability = 'Available';
  DateTime? _lastDonationDate;
  DateTime? _nextEligibleDate;
  int _daysRemaining = 0;
  int _totalDonations = 0;
  bool _isCoolingDown = false;
  bool _availabilityLoading = false;
  String? _availabilityMessage;
  String? _availabilityMessageType;
  bool _reminderLoading = false;

  String get availability => _availability;
  DateTime? get lastDonationDate => _lastDonationDate;
  DateTime? get nextEligibleDate => _nextEligibleDate;
  int get daysRemaining => _daysRemaining;
  int get totalDonations => _totalDonations;
  bool get isCoolingDown => _isCoolingDown;
  bool get availabilityLoading => _availabilityLoading;
  String? get availabilityMessage => _availabilityMessage;
  String? get availabilityMessageType => _availabilityMessageType;
  bool get reminderLoading => _reminderLoading;

  bool get isEligibleNow => _daysRemaining <= 0;

  DonorProvider() {
    SocketService.onAvailabilityUpdated((data) {
      if (data['availability'] != null) {
        _availability = data['availability'].toString();
        _daysRemaining = 0;
        _isCoolingDown = false;
        _availabilityMessage = data['message'] ?? 'You are now eligible to donate blood again!';
        _availabilityMessageType = 'success';
        notifyListeners();
      }
    });
  }

  // ==========================================
  // DONOR SEARCH
  // ==========================================
  Future<void> searchDonors({String? bloodGroup, String? city}) async {
    _isSearching = true;
    _searchMessage = null;
    notifyListeners();

    try {
      _searchResults = await ApiService.searchDonors(
        bloodGroup: bloodGroup,
        city: city,
      );
      if (_searchResults.isEmpty) {
        _searchMessage = 'No matching donors found.';
      }
    } catch (e) {
      _searchMessage = 'Unable to search donors: $e';
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _searchMessage = null;
    notifyListeners();
  }

  // ==========================================
  // DONOR AVAILABILITY
  // ==========================================
  Future<void> fetchAvailability(String token) async {
    _availabilityLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getDonorAvailability(token);
      if (data['success'] == true) {
        _availability = data['availability'] ?? 'Available';
        _daysRemaining = (data['daysRemaining'] as num?)?.toInt() ?? 0;
        _isCoolingDown = data['isCoolingDown'] == true;
        _totalDonations = (data['totalDonations'] as num?)?.toInt() ?? 0;

        if (data['lastDonationDate'] != null) {
          _lastDonationDate = DateTime.tryParse(data['lastDonationDate'].toString());
        }
        if (data['nextEligibleDate'] != null) {
          _nextEligibleDate = DateTime.tryParse(data['nextEligibleDate'].toString());
        }
      }
    } catch (_) {
      // Ignored
    } finally {
      _availabilityLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleAvailability(String token, String newStatus) async {
    _availabilityLoading = true;
    _availabilityMessage = null;
    notifyListeners();

    try {
      final updated = await ApiService.updateDonorAvailability(token, availability: newStatus);
      _availability = updated.availability;
      _availabilityMessage = 'Status updated to $newStatus!';
      _availabilityMessageType = 'success';
      _availabilityLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _availabilityMessage = e.message;
      _availabilityMessageType = 'error';
      _availabilityLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _availabilityMessage = 'Failed to update: $e';
      _availabilityMessageType = 'error';
      _availabilityLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordDonationDate(String token, String dateStr) async {
    _availabilityLoading = true;
    _availabilityMessage = null;
    notifyListeners();

    try {
      final updated = await ApiService.updateDonorAvailability(
        token,
        lastDonationDate: dateStr,
        incrementDonationCount: true,
      );

      _availability = updated.availability;
      _lastDonationDate = updated.lastDonationDate;
      _nextEligibleDate = updated.nextEligibleDate;
      _totalDonations = updated.totalDonations;

      if (_nextEligibleDate != null) {
        final diff = _nextEligibleDate!.difference(DateTime.now());
        _daysRemaining = diff.inDays > 0 ? diff.inDays : 0;
        _isCoolingDown = _daysRemaining > 0;
      }

      _availabilityMessage = 'Donation date recorded! 90-day recovery cooldown is active.';
      _availabilityMessageType = 'success';
      _availabilityLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _availabilityMessage = e.message;
      _availabilityMessageType = 'error';
      _availabilityLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _availabilityMessage = 'Failed to record donation: $e';
      _availabilityMessageType = 'error';
      _availabilityLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> triggerReminders(String? token) async {
    _reminderLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.triggerAvailabilityReminders();
      final count = data['result']?['processedCount'] ?? 0;
      _availabilityMessage = 'Automated reminder check ran! $count donors notified.';
      _availabilityMessageType = 'success';

      if (token != null) {
        await fetchAvailability(token);
      }
    } catch (e) {
      _availabilityMessage = 'Failed to run reminder check: $e';
      _availabilityMessageType = 'error';
    } finally {
      _reminderLoading = false;
      notifyListeners();
    }
  }
}
