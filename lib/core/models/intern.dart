import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Intern {
  // Unique ID for each intern
  final String id;
  // Personal and Academic details
  final String name;
  final String email;
  final String phone;
  final String college; // University/College name
  final String department; // Domain of internship (e.g., UI/UX)
  final DateTime startDate; // Internship beginning date
  DateTime get joiningDate => startDate; // Alias for consistency with Employee model
  final DateTime endDate; // Expected completion date
  final double stipend; // Monthly allowance
  final String mentor; // Assigned supervisor
  final String? photoUrl; // Profile image path
  final String status; // ongoing, completed, or terminated
  final bool certificateIssued; // Flag for certificate status

  // Constructor with default values for status and certificate
  Intern({
    String? id,
    required this.name,
    required this.email,
    required this.phone,
    required this.college,
    required this.department,
    required this.startDate,
    required this.endDate,
    required this.stipend,
    required this.mentor,
    this.photoUrl,
    this.status = 'ongoing',
    this.certificateIssued = false,
  }) : id = (id == null || id.isEmpty) ? _uuid.v4() : id;

  // Helper getter to calculate the total length of the internship in months
  int get durationInMonths {
    return endDate.difference(startDate).inDays ~/ 30;
  }

  // Readable duration string used in UI
  String get duration {
    final months = durationInMonths;
    if (months <= 0) {
      final days = endDate.difference(startDate).inDays;
      if (days <= 0) return 'Just started';
      return '$days Days';
    }
    if (months == 1) return '1 Month';
    return '$months Months';
  }

  // Converts the object to a Map for database/API storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'college': college,
        'department': department,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'stipend': stipend,
        'mentor': mentor,
        'photoUrl': photoUrl,
        'status': status,
        'certificateIssued': certificateIssued,
      };

  // Recreates the object from a stored Map
  factory Intern.fromMap(Map<String, dynamic> map) {
    // Robust Identity Resolution: Fallback chain for various backend implementations
    String resolvedId = (map['id']?.toString() ?? '');
    if (resolvedId.isEmpty) resolvedId = (map['_id']?.toString() ?? '');
    if (resolvedId.isEmpty) resolvedId = _uuid.v4(); // Last resort for local stability

    return Intern(
      id: resolvedId,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        college: map['college'] ?? '',
        department: map['department'] ?? '',
        startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
        stipend: (map['stipend'] ?? 0).toDouble(),
        mentor: map['mentor'] ?? '',
        photoUrl: map['photoUrl'],
        status: map['status'] ?? 'ongoing',
        certificateIssued: map['certificateIssued'] ?? false,
      );
  }

  // Returns a new instance with specific fields modified
  Intern copyWith({
    String? name,
    String? email,
    String? phone,
    String? college,
    String? department,
    DateTime? startDate,
    DateTime? endDate,
    double? stipend,
    String? mentor,
    String? photoUrl,
    String? status,
    bool? certificateIssued,
  }) =>
      Intern(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        college: college ?? this.college,
        department: department ?? this.department,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        stipend: stipend ?? this.stipend,
        mentor: mentor ?? this.mentor,
        photoUrl: photoUrl ?? this.photoUrl,
        status: status ?? this.status,
        certificateIssued: certificateIssued ?? this.certificateIssued,
      );
}
