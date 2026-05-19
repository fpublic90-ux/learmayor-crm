
enum NotificationType { leave, report, system }

class AppNotification {
  final String id;
  final String recipientEmail;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientEmail,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['_id'] ?? '',
    recipientEmail: json['recipientEmail'] ?? '',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    type: NotificationType.values.firstWhere(
      (e) => e.name == json['type'], 
      orElse: () => NotificationType.system
    ),
    isRead: json['isRead'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );
}
