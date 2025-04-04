import 'package:flutter/material.dart';
import 'package:attendance/models/absence_request.dart';
import 'package:attendance/services/absence_request_service.dart';

class AbsenceRequestProvider with ChangeNotifier {
  final AbsenceRequestService _service = AbsenceRequestService();
  bool _isLoading = false;
  String? _error;
  List<AbsenceRequest> _eventRequests = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AbsenceRequest> get eventRequests => _eventRequests;

  Future<void> createRequest(Map<String, dynamic> requestData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _service.createRequest(requestData);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> getEventRequests(String eventId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Provider fetching requests for event: $eventId'); // Log
      _eventRequests = await _service.getEventRequests(eventId);
      print('Got ${_eventRequests.length} requests'); // Log

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error in provider: $e'); // Log error
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.updateStatus(requestId, status);
      
      // Cập nhật trạng thái trong danh sách local
      final index = _eventRequests.indexWhere((req) => req.id == requestId);
      if (index != -1) {
        _eventRequests[index] = _eventRequests[index].copyWith(status: status);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchCreatorRequests() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _eventRequests = await _service.getCreatorRequests();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
