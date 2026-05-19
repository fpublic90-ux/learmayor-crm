import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../config/api_config.dart';

class NotificationRepository {
  final String? token;

  NotificationRepository({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }
      throw Exception('Failed to load notifications (Status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Network error while fetching notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/read'),
        headers: _headers,
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/read-all'),
        headers: _headers,
      );
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id'),
        headers: _headers,
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Server failed to delete notification (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}
