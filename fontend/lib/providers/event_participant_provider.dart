import 'package:flutter/material.dart';
import 'package:attendance/models/event_participant.dart';
import 'package:attendance/services/event_participant_service.dart';

class EventParticipantProvider with ChangeNotifier {
  final EventParticipantService _service = EventParticipantService();
  List<EventParticipant> _participants = [];
  bool _isLoading = false;
  String? _error;

  List<EventParticipant> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getEventParticipants(String eventId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _participants = await _service.getEventParticipants(eventId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addParticipants(String eventId, List<String> userIds) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _service.addParticipants(eventId, userIds);
      await getEventParticipants(eventId); 

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateParticipant(
      String participantId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _service.updateParticipant(participantId, data);

      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = EventParticipant.fromJson({
          ..._participants[index].toJson(),
          ...data,
        });
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

  Future<void> deleteParticipant(String participantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _service.deleteParticipant(participantId);

      _participants.removeWhere((p) => p.id == participantId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveEvent(String eventId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.leaveEvent(eventId);
      await getEventParticipants(eventId); // Refresh danh sách sau khi rời

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
