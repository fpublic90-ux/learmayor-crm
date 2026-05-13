import 'package:flutter/material.dart';
import '../models/report.dart';
import '../repositories/report_repository.dart';
import '../utils/result.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository = ReportRepository();
  List<WorkReport> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WorkReport> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReportProvider() {
    fetchReports();
  }

  // Get reports for a specific staff member
  List<WorkReport> getReportsByStaff(String staffId) {
    return _reports.where((r) => r.staffId == staffId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Admin: Get all pending reports
  List<WorkReport> get pendingReports => 
    _reports.where((r) => r.status == ReportStatus.pending).toList();

  Future<void> fetchReports({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final fetchedReports = await _repository.getReports();
      _reports = fetchedReports;
    } catch (e) {
      debugPrint('❌ [ERROR] Failed to fetch reports: $e');
      if (showLoading) _errorMessage = 'Failed to load reports: $e';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<Result<void, Exception>> submitReport(WorkReport report) async {
    try {
      await _repository.submitReport(report);
      fetchReports(showLoading: false); // Silent background sync
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
        fetchReports(showLoading: false); // Silent background sync
        return const Success(null);
      }
      return Failure(Exception('Report not found'));
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
