import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../config/api_config.dart';

class EmployeeRepository {
  final String? token;
  EmployeeRepository({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<Employee>> getEmployees() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.employeesUrl), headers: _headers)
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Employee.fromMap(e)).toList();
      }
      throw Exception('Server error (${response.statusCode})');
    } catch (e) {
      throw Exception('Server is warming up or connection lost. Please try again.');
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes('image', await image.readAsBytes(), filename: image.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }
      
      // Execute request with authoritative timeout governance
      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['imageUrl'];
      }
      throw Exception('Image upload failed (${response.statusCode})');
    } catch (e) {
      debugPrint('🚨 [NETWORK] Upload Error: $e');
      throw Exception('Could not reach image server. Please check your connection.');
    }
  }

  Future<void> addEmployee(Employee employee) async {
    final response = await http.post(
      Uri.parse(ApiConfig.employeesUrl),
      headers: _headers,
      body: jsonEncode(employee.toMap()),
    ).timeout(const Duration(seconds: 45));
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add record (Status: ${response.statusCode})');
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    const url = ApiConfig.employeesUrl; // Upsert uses the base POST endpoint
    final body = jsonEncode(employee.toMap());
    debugPrint('📡 [UPSERT] Employee Request: $url');
    debugPrint('📦 Payload: $body');
    
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    ).timeout(const Duration(seconds: 45));
    
    debugPrint('📥 [UPSERT] Employee Response (${response.statusCode})');
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Update failed (Status: ${response.statusCode})');
    }
  }

  Future<void> deleteEmployee(String id) async {
    final url = '${ApiConfig.employeesUrl}/$id';
    debugPrint('📡 [DELETE] Employee Request: $url');
    
    final response = await http.delete(
      Uri.parse(url), 
      headers: _headers
    ).timeout(const Duration(seconds: 45));
    
    debugPrint('📥 [DELETE] Employee Response (${response.statusCode})');
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Deletion failed (Status: ${response.statusCode})');
    }
  }
}
