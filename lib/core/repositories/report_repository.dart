import 'dart:convert';
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
    final response = await http.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      return decoded.map((item) => WorkReport.fromMap(item)).toList();
    } else {
      throw Exception('Failed to fetch reports (${response.statusCode})');
    }
  }

  Future<WorkReport> submitReport(WorkReport report) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode(report.toMap()),
    );
    if (response.statusCode == 201) {
      return WorkReport.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to submit report (${response.statusCode})');
    }
  }

  Future<WorkReport> updateReport(WorkReport report) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/${report.id}'),
      headers: _headers,
      body: jsonEncode(report.toMap()),
    );
    if (response.statusCode == 200) {
      return WorkReport.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update report (${response.statusCode})');
    }
  }
}
