import 'package:flutter/material.dart';
import '../models/report.dart';
import '../repositories/report_repository.dart';
import '../utils/result.dart';

class ReportProvider extends ChangeNotifier {
  ReportRepository _repository = ReportRepository();
  List<WorkReport> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  List<WorkReport> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReportProvider();

  // Handle token updates from AuthProvider
  void updateToken(String? newToken) {
    if (_token != newToken) {
      _token = newToken;
      _repository = ReportRepository(token: _token);
      if (_token != null) {
        fetchReports();
      } else {
        _reports = [];
        notifyListeners();
      }
    }
  }

  // Get reports for a specific staff member
  List<WorkReport> getReportsByStaff(String staffId) {
    return _reports.where((r) => r.staffId == staffId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Admin: Get all pending reports
  List<WorkReport> get pendingReports => 
    _reports.where((r) => r.status == ReportStatus.pending).toList();

  Future<void> fetchReports({bool force = false}) async {
    // Only show shimmer if we have no data yet or if forced
    final shouldShowShimmer = _reports.isEmpty || force;
    
    if (shouldShowShimmer) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final fetchedReports = await _repository.getReports();
      _reports = fetchedReports;
    } catch (e) {
      debugPrint('❌ [ERROR] Failed to fetch reports: $e');
      if (shouldShowShimmer) _errorMessage = 'Failed to load reports: $e';
    } finally {
      if (shouldShowShimmer) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<Result<void, Exception>> submitReport(WorkReport report) async {
    try {
      await _repository.submitReport(report);
      fetchReports(); // Silent background sync (force=false by default)
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> updateReportStatus(String id, ReportStatus status) async {
    try {
      final index = _reports.indexWhere((r) => r.id == id);
      if (index != -1) {
        final old = _reports[index];
        final updated = WorkReport(
          id: old.id,
          staffId: old.staffId,
          staffName: old.staffName,
          date: old.date,
          description: old.description,
          tasks: old.tasks,
          hoursWorked: old.hoursWorked,
          status: status,
        );
        await _repository.updateReport(updated);
        fetchReports(); // Silent background sync (force=false by default)
        return const Success(null);
      }
      return Failure(Exception('Report not found'));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
