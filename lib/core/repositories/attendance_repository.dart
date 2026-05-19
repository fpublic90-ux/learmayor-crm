import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/attendance.dart';
import '../config/api_config.dart';

class AttendanceRepository {
  final String? token;
  AttendanceRepository({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<Attendance>> getAttendance() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.attendanceUrl), headers: _headers)
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((a) => Attendance.fromMap(a)).toList();
      }
      throw Exception('Registry sync failed (${response.statusCode})');
    } catch (e) {
      debugPrint('🚨 [NETWORK] Attendance Sync Error: $e');
      throw Exception('Analytical server is warming up. Please refresh in a moment.');
    }
  }

  Future<void> markAttendance(Attendance attendance) async {
    final response = await http.post(
      Uri.parse(ApiConfig.attendanceUrl),
      headers: _headers,
      body: jsonEncode(attendance.toMap()),
    ).timeout(const Duration(seconds: 45));
    
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to save (Status: ${response.statusCode})');
    }
  }
}
