
enum LeaveStatus { pending, approved, rejected }
enum LeaveType { fullDay, halfDay }

class LeaveRequest {
  final String id;
  final String staffId;
  final String staffName;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final LeaveType type;
  final DateTime createdAt;

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  LeaveRequest({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.type = LeaveType.fullDay,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffId': staffId,
    'staffName': staffName,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'reason': reason,
    'status': status.name,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    staffId: json['staffId'] ?? '',
    staffName: json['staffName'] ?? '',
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    reason: json['reason'] ?? '',
    status: LeaveStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => LeaveStatus.pending),
    type: LeaveType.values.firstWhere((e) => e.name == json['type'], orElse: () => LeaveType.fullDay),
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );
}
