import 'package:flutter/material.dart';
import '../models/leave_request.dart';
import '../repositories/leave_repository.dart';
import '../utils/result.dart';

class LeaveProvider extends ChangeNotifier {
  LeaveRepository _repository = LeaveRepository();
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = false; 
  String? _errorMessage;
  String? _token;

  List<LeaveRequest> get leaveRequests => _leaveRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Selective filters
  List<LeaveRequest> getMyRequests(String staffId) {
    return _leaveRequests.where((r) => r.staffId == staffId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LeaveRequest> get pendingRequests => 
    _leaveRequests.where((r) => r.status == LeaveStatus.pending).toList();

  void updateToken(String? newToken) {
    if (_token != newToken) {
      _token = newToken;
      _repository = LeaveRepository(token: _token);
      if (_token != null) {
        fetchLeaveRequests();
      } else {
        _leaveRequests = [];
        notifyListeners();
      }
    }
  }

  Future<void> fetchLeaveRequests({bool force = false}) async {
    final shouldShowShimmer = _leaveRequests.isEmpty || force;
    
    if (shouldShowShimmer) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _leaveRequests = await _repository.getLeaveRequests();
    } catch (e) {
      debugPrint('❌ [ERROR] Failed to fetch leave requests: $e');
      if (shouldShowShimmer) _errorMessage = 'Failed to load leave requests: $e';
    } finally {
      if (shouldShowShimmer) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<Result<void, Exception>> submitLeaveRequest(LeaveRequest request) async {
    try {
      await _repository.submitLeaveRequest(request);
      fetchLeaveRequests(); // Silent background sync
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> updateLeaveStatus(String id, LeaveStatus status) async {
    try {
      await _repository.updateLeaveStatus(id, status);
      fetchLeaveRequests(); // Silent background sync
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> cancelLeaveRequest(String id) async {
    try {
      await _repository.deleteLeaveRequest(id);
      fetchLeaveRequests(); // Silent background sync
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
