import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationRepository _repository = NotificationRepository();
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _token;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void updateToken(String? newToken) {
    if (_token != newToken) {
      _token = newToken;
      _repository = NotificationRepository(token: _token);
      if (_token != null) {
        fetchNotifications();
      } else {
        _notifications = [];
        notifyListeners();
      }
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications();
    } catch (e) {
      debugPrint('❌ [ERROR] Notification Sync Failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      // Optimistic Update
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          recipientEmail: _notifications[index].recipientEmail,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to mark notification read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        recipientEmail: n.recipientEmail,
        title: n.title,
        message: n.message,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to mark all notifications read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      // Optimistic Update: Remove from list immediately to prevent Dismissible crashes
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
      
      await _repository.deleteNotification(id);
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
      // Re-fetch to recover state if server deletion fails
      fetchNotifications();
    }
  }
}
