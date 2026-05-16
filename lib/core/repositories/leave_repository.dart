import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave_request.dart';
import '../config/api_config.dart';

class LeaveRepository {
  final String? token;
  LeaveRepository({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<LeaveRequest>> getLeaveRequests() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.leavesUrl), headers: _headers)
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => LeaveRequest.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> submitLeaveRequest(LeaveRequest request) async {
    final response = await http.post(
      Uri.parse(ApiConfig.leavesUrl),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    ).timeout(const Duration(seconds: 45));
    
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to submit request (Status: ${response.statusCode})');
    }
  }

  Future<void> updateLeaveStatus(String id, LeaveStatus status) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.leavesUrl}/$id'),
      headers: _headers,
      body: jsonEncode({'status': status.name}),
    ).timeout(const Duration(seconds: 45));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update status (Status: ${response.statusCode})');
    }
  }

  Future<void> deleteLeaveRequest(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.leavesUrl}/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 45));
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete request (Status: ${response.statusCode})');
    }
  }
}
