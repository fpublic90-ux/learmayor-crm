import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/intern.dart';
import '../repositories/intern_repository.dart';
import '../utils/result.dart';

class InternProvider extends ChangeNotifier {
  InternRepository _repository = InternRepository();
  // List to hold the current interns in memory
  List<Intern> _interns = [];
  // State variables for loading indicators and error messages
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  // Exposing state to the UI components
  List<Intern> get interns => _interns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update repository with new token
  void updateToken(String? token) {
    _repository = InternRepository(token: token);
    if (token != null) {
      fetchInterns();
      _startPolling();
    } else {
      _stopPolling();
      _interns = [];
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchInterns());
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // Method to retrieve all interns from the repository
  Future<void> fetchInterns({bool force = false}) async {
    // Only show shimmer if we have no data yet or if forced
    if (_interns.isEmpty || force) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final newInterns = await _repository.getInterns();
      _interns = newInterns;
    } catch (e) {
      _errorMessage = 'Failed to fetch interns: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handles the uploading of intern profile pictures
  Future<String?> uploadImage(XFile image) async {
    try {
      return await _repository.uploadImage(image);
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  // Method to add a new intern record
  Future<Result<void, Exception>> addIntern(Intern intern) async {
    try {
      await _repository.addIntern(intern);
      fetchInterns(); // Trigger background sync (don't await)
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // Method to update an existing intern's profile
  Future<Result<void, Exception>> updateIntern(Intern intern) async {
    try {
      await _repository.updateIntern(intern);
      fetchInterns(); // Trigger background sync (don't await)
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // Method to delete an intern from the system
  Future<Result<void, Exception>> deleteIntern(String id) async {
    try {
      await _repository.deleteIntern(id);
      fetchInterns(); // Trigger background sync (don't await)
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
