import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/globals.dart';
import '../../core/models/leave_request.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/widgets/premium_widgets.dart';

class AdminLeaveListScreen extends StatefulWidget {
  const AdminLeaveListScreen({super.key});

  @override
  State<AdminLeaveListScreen> createState() => _AdminLeaveListScreenState();
}

class _AdminLeaveListScreenState extends State<AdminLeaveListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().fetchLeaveRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LeaveProvider>();
    final pendingRequests = provider.pendingRequests;
    final otherRequests = provider.leaveRequests.where((r) => r.status != LeaveStatus.pending).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GlassAppBar(
        title: 'Leave Management',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
      body: provider.isLoading && provider.leaveRequests.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: () => provider.fetchLeaveRequests(force: true),
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (pendingRequests.isNotEmpty) ...[
                    _buildSectionHeader('PENDING APPROVAL'),
                    const SizedBox(height: 16),
                    ...pendingRequests.map((r) => _buildLeaveCard(r, provider, theme)),
                    const SizedBox(height: 32),
                  ],
                  if (otherRequests.isNotEmpty) ...[
                    _buildSectionHeader('RECENT HISTORY'),
                    const SizedBox(height: 16),
                    ...otherRequests.map((r) => _buildLeaveCard(r, provider, theme)),
                  ],
                  if (pendingRequests.isEmpty && otherRequests.isEmpty)
                    const EmptyStateWidget(
                      title: 'No Leave Requests',
                      message: 'Personnel requests will appear here.',
                      icon: Icons.event_busy_rounded,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppTheme.textMid,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRequest request, LeaveProvider provider, ThemeData theme) {
    final isPending = request.status == LeaveStatus.pending;
    final statusColor = request.status == LeaveStatus.approved 
      ? AppTheme.success 
      : (request.status == LeaveStatus.rejected ? AppTheme.error : AppTheme.accent);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BentoCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.staffName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(request.staffId, style: const TextStyle(color: AppTheme.textMid, fontSize: 12)),
                    ],
                  ),
                ),
                StatusBadge(label: request.status.name.toUpperCase(), color: statusColor),
              ],
            ),
            const Divider(height: 32, color: AppTheme.divider),
            Row(
              children: [
                const Icon(Icons.date_range_rounded, size: 18, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text(
                  '${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd').format(request.endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.type == LeaveType.fullDay ? 'FULL DAY' : 'HALF DAY',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(request.reason, style: const TextStyle(height: 1.5, color: AppTheme.textDark)),
            if (isPending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      label: 'REJECT',
                      isOutline: true,
                      color: AppTheme.error,
                      onPressed: () => _handleStatusUpdate(provider, request.id, LeaveStatus.rejected),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PremiumButton(
                      label: 'APPROVE',
                      color: AppTheme.success,
                      onPressed: () => _handleStatusUpdate(provider, request.id, LeaveStatus.approved),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusUpdate(LeaveProvider provider, String id, LeaveStatus status) async {
    HapticFeedback.mediumImpact();
    final result = await provider.updateLeaveStatus(id, status);
    result.when(
      onSuccess: (_) => Globals.showSnackBar('Leave ${status.name} successfully'),
      onFailure: (e) => Globals.showSnackBar('Action failed: ${e.toString()}', isError: true),
    );
  }
}
