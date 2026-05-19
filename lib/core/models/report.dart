import 'dart:convert';

enum ReportStatus { pending, approved, rejected }

class WorkReport {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime date;
  final String description;
  final List<String> tasks;
  final int hoursWorked;
  final ReportStatus status;
  final List<String> attachments;

  WorkReport({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.date,
    required this.description,
    required this.tasks,
    required this.hoursWorked,
    this.status = ReportStatus.pending,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'date': date.toIso8601String(),
      'description': description,
      'tasks': tasks,
      'hoursWorked': hoursWorked,
      'status': status.toString().split('.').last,
      'attachments': attachments,
    };
  }

  factory WorkReport.fromMap(Map<String, dynamic> map) {
    return WorkReport(
      id: map['id'] ?? '',
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      date: DateTime.parse(map['date']),
      description: map['description'] ?? '',
      tasks: List<String>.from(map['tasks'] ?? []),
      hoursWorked: map['hoursWorked'] ?? 0,
      status: ReportStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkReport.fromJson(String source) => WorkReport.fromMap(json.decode(source));
}
