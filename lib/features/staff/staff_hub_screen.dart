import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/report_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/widgets/premium_widgets.dart';

class StaffHubScreen extends StatelessWidget {
  const StaffHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('💼 [BUILD] StaffHubScreen');
    final theme = Theme.of(context);
    
    // Selective Watching: Only rebuild when data actually changes
    final auth = context.read<AuthProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final reportProvider = context.watch<ReportProvider>();
    
    final myReports = reportProvider.getReportsByStaff(auth.userEmail ?? 'anonymous');
    final today = DateFormat('EEEE, MMMM dd').format(DateTime.now());

    // Memoized Lookup: Search once per build cycle efficiently
    final myRecord = auth.role == UserRole.employee
        ? employeeProvider.employees.cast<dynamic>().firstWhere((e) => e.email == auth.userEmail, orElse: () => null)
        : auth.role == UserRole.intern
            ? internProvider.interns.cast<dynamic>().firstWhere((i) => i.email == auth.userEmail, orElse: () => null)
            : null;

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
                  Text('Hi, ${auth.userName?.split(' ').first ?? 'Staff'}', 
                    style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 26)),
                  Text(today, style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, color: AppTheme.textMid)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildDailyAction(context, theme),
                  
                  const SizedBox(height: 24),
                  _buildAttendanceSummary(context, theme),

                  if (myRecord != null) ...[
                    const SizedBox(height: 32),
                    Text('OFFICIAL DETAILS', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 16),
                    _buildOfficialInfo(myRecord, theme),
                  ],

                  const SizedBox(height: 32),
                  _buildRecentLogsHeader(theme),
                  const SizedBox(height: 16),
                  if (myReports.isEmpty)
                    _buildEmptyState(theme)
                  else
                    ...myReports.map((report) => _buildReportCard(report, theme)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialInfo(dynamic record, ThemeData theme) {
    final isEmployee = record.runtimeType.toString() == 'Employee';
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _InfoRow(
            label: isEmployee ? 'Designation' : 'Academic Partner', 
            value: isEmployee ? record.designation : record.college, 
            icon: isEmployee ? Icons.badge_outlined : Icons.school_outlined
          ),
          const Divider(height: 32),
          _InfoRow(
            label: 'Department', 
            value: record.department, 
            icon: Icons.account_tree_outlined
          ),
          const Divider(height: 32),
          _InfoRow(
            label: 'Joined On', 
            value: DateFormat('MMM dd, yyyy').format(record.joiningDate), 
            icon: Icons.calendar_today_outlined
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAction(BuildContext context, ThemeData theme) {
    return BentoCard(
      onTap: () => _showSubmitDialog(context),
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.edit_document, color: AppTheme.accent, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Report', style: theme.textTheme.titleLarge),
                Text('Log your activities for today', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.add_circle_rounded, color: AppTheme.accent, size: 32),
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
                child: Text('#$t', style: const TextStyle(fontSize: 10, color: AppTheme.textMid, fontWeight: FontWeight.bold)),
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

  Widget _buildAttendanceSummary(BuildContext context, ThemeData theme) {
    return BentoCard(
      onTap: () => context.push('/attendance'),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available_rounded, color: AppTheme.success, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Tracking', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const Text('View your monthly work presence', style: TextStyle(color: AppTheme.textMid, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMid),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label; final String value; final IconData icon;
  const _InfoRow({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMid),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textMid, fontSize: 13, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
