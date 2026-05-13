import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../config/api_config.dart';

class ReportRepository {
  final String _baseUrl = ApiConfig.reportsUrl;

  Future<List<WorkReport>> getReports() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((item) => WorkReport.fromMap(item)).toList();
    } else {
      throw Exception('Failed to fetch reports');
    }
  }

  Future<WorkReport> submitReport(WorkReport report) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(report.toMap()),
    );
    if (response.statusCode == 201) {
      return WorkReport.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to submit report');
    }
  }

  Future<WorkReport> updateReport(WorkReport report) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/${report.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(report.toMap()),
    );
    if (response.statusCode == 200) {
      return WorkReport.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update report');
    }
  }
}
