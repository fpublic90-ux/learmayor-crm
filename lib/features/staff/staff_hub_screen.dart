import 'package:flutter/material.dart';
import 'package:learnyor_hrm/core/models/report.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/report_provider.dart';
import '../../core/widgets/premium_widgets.dart';

class StaffHubScreen extends StatelessWidget {
  const StaffHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Authentication Guard: Prevents building complex UI during logout transition
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    debugPrint('💼 [BUILD] StaffHubScreen');
    final theme = Theme.of(context);
    
    final userEmail = auth.userEmail ?? 'anonymous';
    
    // Selective Watching: Only rebuild if the current staff's reports change
    final myReports = context.select<ReportProvider, List<WorkReport>>(
      (p) => p.getReportsByStaff(userEmail)
    );
    
    final today = DateFormat('EEEE, MMMM dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.background.withOpacity(0.8),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, ${auth.userName?.split(' ').first ?? (auth.role.name == 'intern' ? 'Intern' : 'Staff')}', 
                    style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 26)),
                  Text(today, style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, color: AppTheme.textMid)),
                ],
              ),
            ),
            actions: [const NotificationBell(),
              IconButton(
                icon: Icon(Icons.settings_rounded, color: AppTheme.primary),
                onPressed: () => context.push('/settings'),
              ),
              
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildActionCard(
                        context: context,
                        title: 'Daily Report',
                        subtitle: 'Log activities',
                        icon: Icons.edit_document,
                        color: AppTheme.accent,
                        onTap: () => _showSubmitDialog(context),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildActionCard(
                        context: context,
                        title: 'Request Leave',
                        subtitle: 'Future dates',
                        icon: Icons.calendar_today_rounded,
                        color: AppTheme.primary,
                        onTap: () => context.push('/staff/leave/request'),
                      )),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildRecentLogsHeader(theme),
                  const SizedBox(height: 16),
                  if (myReports.isEmpty)
                    _buildEmptyState(theme)
                ],
              ),
            ),
          ),
          if (myReports.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildReportCard(myReports[index], theme),
                  childCount: myReports.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 71, 105, 80))),
        ],
      ),
    );
  }

  Widget _buildRecentLogsHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('RECENT WORK LOGS', style: theme.textTheme.labelLarge),
        TextButton(onPressed: () {}, child: const Text('View All')),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppTheme.textLight.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No logs found', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(dynamic report, ThemeData theme) {
    final statusStr = report.status.toString().split('.').last;
    final statusColor = statusStr == 'approved' ? AppTheme.success : (statusStr == 'rejected' ? AppTheme.error : AppTheme.accent);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BentoCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMM dd, yyyy').format(report.date), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                StatusBadge(label: statusStr.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.description, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: report.tasks.map<Widget>((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(6)),
                child: Text('#$t', style: TextStyle(fontSize: 10, color: AppTheme.textMid, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    context.push('/staff/report/add');
  }
}
