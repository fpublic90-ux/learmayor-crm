import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../config/api_config.dart';

class ReportRepository {
  final String _baseUrl = ApiConfig.reportsUrl;
  final String? token;

  ReportRepository({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<List<WorkReport>> getReports() async {
    try {
      debugPrint('📡 [REPORT REPO] GET request to $_baseUrl');
      final response = await http.get(Uri.parse(_baseUrl), headers: _headers);
      debugPrint('📡 [REPORT REPO] GET response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded.map((item) => WorkReport.fromMap(item)).toList();
      } else {
        debugPrint('❌ [REPORT REPO ERROR] GET failed. Code: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch reports (${response.statusCode}): ${response.body}');
      }
    } catch (e, s) {
      debugPrint('❌ [REPORT REPO EXCEPTION] GET exception: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<WorkReport> submitReport(WorkReport report) async {
    try {
      debugPrint('📡 [REPORT REPO] POST request to $_baseUrl');
      final bodyStr = jsonEncode(report.toMap());
      debugPrint('📡 [REPORT REPO] Request Body: $bodyStr');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: bodyStr,
      );
      
      debugPrint('📡 [REPORT REPO] POST response status: ${response.statusCode}');
      debugPrint('📡 [REPORT REPO] Response Headers: ${response.headers}');
      debugPrint('📡 [REPORT REPO] Response Body: ${response.body}');
      
      if (response.statusCode == 201) {
        return WorkReport.fromMap(jsonDecode(response.body));
      } else {
        debugPrint('❌ [REPORT REPO ERROR] POST failed. Code: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to submit report (${response.statusCode}): ${response.body}');
      }
    } catch (e, s) {
      debugPrint('❌ [REPORT REPO EXCEPTION] POST exception: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<WorkReport> updateReport(WorkReport report) async {
    try {
      final url = '$_baseUrl/${report.id}';
      debugPrint('📡 [REPORT REPO] PUT request to $url');
      final bodyStr = jsonEncode(report.toMap());
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: bodyStr,
      );
      
      debugPrint('📡 [REPORT REPO] PUT response status: ${response.statusCode}');
      debugPrint('📡 [REPORT REPO] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return WorkReport.fromMap(jsonDecode(response.body));
      } else {
        debugPrint('❌ [REPORT REPO ERROR] PUT failed. Code: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to update report (${response.statusCode}): ${response.body}');
      }
    } catch (e, s) {
      debugPrint('❌ [REPORT REPO EXCEPTION] PUT exception: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}
