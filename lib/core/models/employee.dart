import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Employee {
  // Unique identifier for each employee (generated via UUID)
  final String id;
  // Personal and Professional details
  final String name;
  final String email;
  final String phone;
  final String designation; // Role (e.g., Software Engineer)
  final String department; // Team (e.g., Development)
  final DateTime joiningDate; // When the employee started
  final double salary; // Monthly payout
  final String address; // Contact address
  final String? photoUrl; // Optional path to profile photo
  final String status; // Current state: active, resigned, or onLeave

  // Constructor with automatic ID generation if not provided
  Employee({
    String? id,
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.department,
    required this.joiningDate,
    required this.salary,
    required this.address,
    this.photoUrl,
    this.status = 'active',
  }) : id = id ?? _uuid.v4();

  // Converts the Employee object into a JSON-compatible Map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'designation': designation,
        'department': department,
        'joiningDate': joiningDate.toIso8601String(), // Store as ISO string
        'salary': salary,
        'address': address,
        'photoUrl': photoUrl,
        'status': status,
      };

  // Factory constructor to create an Employee object from a Map (e.g., from a database)
  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
        id: (map['id'] ?? map['_id'] ?? '').toString(),
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        designation: map['designation'] ?? '',
        department: map['department'] ?? '',
        // Handle potentially invalid date strings gracefully
        joiningDate: DateTime.tryParse(map['joiningDate'] ?? '') ?? DateTime.now(),
        // Ensure salary is treated as a double
        salary: (map['salary'] ?? 0).toDouble(),
        address: map['address'] ?? '',
        photoUrl: map['photoUrl'],
        status: map['status'] ?? 'active',
      );

  // Creates a copy of the current Employee with some updated fields
  Employee copyWith({
    String? name,
    String? email,
    String? phone,
    String? designation,
    String? department,
    DateTime? joiningDate,
    double? salary,
    String? address,
    String? photoUrl,
    String? status,
  }) =>
      Employee(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        designation: designation ?? this.designation,
        department: department ?? this.department,
        joiningDate: joiningDate ?? this.joiningDate,
        salary: salary ?? this.salary,
        address: address ?? this.address,
        photoUrl: photoUrl ?? this.photoUrl,
        status: status ?? this.status,
      );
}
