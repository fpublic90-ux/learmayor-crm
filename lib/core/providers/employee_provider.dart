 import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/employee.dart';
import '../repositories/employee_repository.dart';
import '../utils/result.dart';

class EmployeeProvider extends ChangeNotifier {
  EmployeeRepository _repository = EmployeeRepository();
  // Internal list of employees
  List<Employee> _employees = [];
  // Loading state and error handling
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  // Exposing properties to the UI
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update repository with new token
  void updateToken(String? token) {
    _repository = EmployeeRepository(token: token);
    if (token != null) {
      fetchEmployees();
      _startPolling();
    } else {
      _stopPolling();
      _employees = [];
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchEmployees());
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

  // Fetches all employees and updates the local list
  Future<void> fetchEmployees() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newEmployees = await _repository.getEmployees();
      _employees = newEmployees;
    } catch (e) {
      _errorMessage = 'Failed to fetch employees: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handles profile image uploads during Add/Edit
  Future<String?> uploadImage(XFile image) async {
    try {
      return await _repository.uploadImage(image);
    } catch (e) {      
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  // Logic to add a new employee to both repository and local list
  Future<Result<void, Exception>> addEmployee(Employee employee) async {
    try {
      await _repository.addEmployee(employee);
      fetchEmployees(); // Trigger background sync (don't await)
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // Logic to update existing employee details
  Future<Result<void, Exception>> updateEmployee(Employee employee) async {
    try {
      await _repository.updateEmployee(employee);
      fetchEmployees(); // Trigger background sync (don't await)
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // Logic to remove an employee
  Future<Result<void, Exception>> deleteEmployee(String id) async {
    try {
      await _repository.deleteEmployee(id);
      fetchEmployees(); // Trigger background sync (don't await)
      return const Success(null);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }
}
