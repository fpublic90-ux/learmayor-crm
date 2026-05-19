import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../app/globals.dart';
import '../../app/theme.dart';
import '../../core/models/notification.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/auth_provider.dart';
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
        onBack: () {
          HapticFeedback.lightImpact();
          context.pop();
        },
        actions: [
          if (provider.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.markAllAsRead();
                  Globals.showPremiumSuccess('All notifications marked as read');
                },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: AppTheme.primary.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: provider.isLoading && notifications.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surface,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await provider.fetchNotifications();
              },
              child: notifications.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: const EmptyStateWidget(
                          title: 'All caught up!',
                          message: 'You have no new notifications at the moment.',
                          icon: Icons.notifications_active_outlined,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildNotificationCard(
                        notifications[index],
                        provider,
                        theme,
                      ),
                    ),
            ),
    );
  }

  Widget _buildNotificationCard(
    AppNotification notification,
    NotificationProvider provider,
    ThemeData theme,
  ) {
    final bool isLeave = notification.type == NotificationType.leave;
    final bool isReport = notification.type == NotificationType.report;

    final color = isLeave
        ? AppTheme.primary
        : (isReport ? AppTheme.accent : AppTheme.textMid);

    final icon = isLeave
        ? Icons.calendar_today_rounded
        : (isReport ? Icons.analytics_rounded : Icons.info_outline_rounded);

    final auth = context.read<AuthProvider>();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        provider.deleteNotification(notification.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.error, Color(0xFFE53935)], // deeper red
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      child: BentoCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        color: notification.isRead
            ? AppTheme.surface
            : AppTheme.primary.withOpacity(0.04),
        onTap: () {
          HapticFeedback.selectionClick();
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }

          // Contextual Navigation
          if (isLeave) {
            context.push(auth.isAdmin ? '/reports/leave' : '/staff/leave/list');
          } else if (isReport) {
            context.push(auth.isAdmin ? '/reports/admin' : '/staff/hub');
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w900,
                            fontSize: 15,
                            color: AppTheme.textDark,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: notification.isRead ? AppTheme.textLight : AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: notification.isRead ? AppTheme.textMid : AppTheme.textDark.withOpacity(0.8),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Unread indicator badge
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 12, top: 6),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method for smart time formatting
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0 && now.day == time.day) {
      return DateFormat('hh:mm a').format(time); // Today: "02:30 PM"
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != time.day)) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(time); // This week: "Monday"
    } else {
      return DateFormat('MMM dd').format(time); // Older: "Oct 24"
    }
  }
}
