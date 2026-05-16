import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../repositories/attendance_repository.dart';
import '../utils/result.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceRepository _repository = AttendanceRepository();
  // List to store all fetched attendance logs
  List<Attendance> _attendanceRecords = [];
  // UI states
  bool _isLoading = false;
  String? _errorMessage;

  // Getters to expose private variables to the UI
  List<Attendance> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update repository with new token
  void updateToken(String? token) {
    _repository = AttendanceRepository(token: token);
    if (token != null) {
      fetchAttendance();
    } else {
      _attendanceRecords = [];
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Method to fetch all attendance data from the repository
  Future<void> fetchAttendance({bool force = false}) async {
    // Only show shimmer if we have no data yet or if forced
    if (_attendanceRecords.isEmpty || force) {
      _isLoading = true; 
      _errorMessage = null;
      notifyListeners(); 
    }

    try {
      _attendanceRecords = await _repository.getAttendance();
    } catch (e) {
      _errorMessage = 'Failed to fetch attendance: $e';
    } finally {
      _isLoading = false; // Hide loading spinner
      notifyListeners(); // Notify UI about data/error update
    }
  }

  // Method to record a person's attendance (Present/Absent/etc.)
  Future<Result<void, Exception>> markAttendance(Attendance attendance) async {
    // OPTIMISTIC UPDATE: Update UI immediately before waiting for the server
    final originalRecords = List<Attendance>.from(_attendanceRecords);
    // Remove any existing record for the same person on the same day
    _attendanceRecords.removeWhere((r) => 
      r.personId == attendance.personId && 
      r.date.year == attendance.date.year &&
      r.date.month == attendance.date.month &&
      r.date.day == attendance.date.day
    );
    // Add the new record
    _attendanceRecords.add(attendance);
    notifyListeners(); // UI updates instantly

    try {
      // Save the change to the persistent storage (repository)
      await _repository.markAttendance(attendance);
      return const Success(null);
    } catch (e) {
      // ROLLBACK: If saving fails, revert to the original list and notify UI
      _attendanceRecords = originalRecords;
      notifyListeners();
      return Failure(Exception(e.toString()));
    }
  }

  // Helper method to filter records for a specific day
  List<Attendance> getAttendanceForDate(DateTime date) {
    return _attendanceRecords.where((record) =>
        record.date.year == date.year &&
        record.date.month == date.month &&
        record.date.day == date.day).toList();
  }

  // Helper method to filter records for a specific person (Employee or Intern)
  List<Attendance> getAttendanceForPerson(String personId) {
    final records = _attendanceRecords.where((record) => record.personId == personId).toList();
    // Sort by date descending (most recent first)
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }
}
