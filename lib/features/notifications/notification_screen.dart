import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/models/notification.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/widgets/premium_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GlassAppBar(
        title: 'Notifications',
        showBackButton: true,
        onBack: () => context.pop(),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
      body: provider.isLoading && notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: () => provider.fetchNotifications(),
              child: notifications.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildNotificationCard(notifications[index], provider),
                    ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle, border: Border.all(color: AppTheme.border)),
            child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.textLight),
          ),
          const SizedBox(height: 24),
          const Text('All caught up!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('No new notifications found', style: TextStyle(color: AppTheme.textMid)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, NotificationProvider provider) {
    final color = notification.type == NotificationType.leave 
        ? AppTheme.primary 
        : (notification.type == NotificationType.report ? AppTheme.accent : AppTheme.textMid);
    
    final icon = notification.type == NotificationType.leave 
        ? Icons.event_note_rounded 
        : (notification.type == NotificationType.report ? Icons.description_rounded : Icons.info_outline_rounded);

    return BentoCard(
      onTap: () => provider.markAsRead(notification.id),
      color: notification.isRead ? Colors.white : AppTheme.primary.withOpacity(0.02),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w900, fontSize: 14)),
                    Text(
                      DateFormat('MMM dd, hh:mm a').format(notification.createdAt),
                      style: const TextStyle(fontSize: 9, color: AppTheme.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.message, style: const TextStyle(fontSize: 12, color: AppTheme.textMid, height: 1.4)),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
