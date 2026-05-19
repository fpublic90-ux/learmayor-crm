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

class MyLeaveRequestsScreen extends StatefulWidget {
  const MyLeaveRequestsScreen({super.key});

  @override
  State<MyLeaveRequestsScreen> createState() => _MyLeaveRequestsScreenState();
}

class _MyLeaveRequestsScreenState extends State<MyLeaveRequestsScreen> {
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
    
    // Separate into pending and history
    final pendingRequests = provider.leaveRequests
        .where((r) => r.status == LeaveStatus.pending)
        .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
    final historyRequests = provider.leaveRequests
        .where((r) => r.status != LeaveStatus.pending)
        .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GlassAppBar(
        title: 'My Leave Requests',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
      body: provider.isLoading && provider.leaveRequests.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: () => provider.fetchLeaveRequests(force: true),
              color: AppTheme.accent,
              child: provider.leaveRequests.isEmpty
                  ? EmptyStateWidget(
                      title: 'No Leaves Requested',
                      message: 'You have not submitted any leave requests yet.',
                      icon: Icons.event_available_rounded,
                      actionLabel: 'Request Leave',
                      onAction: () => context.push('/staff/leave/request'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      children: [
                        if (pendingRequests.isNotEmpty) ...[
                          _buildSectionHeader('PENDING APPROVAL'),
                          const SizedBox(height: 16),
                          ...pendingRequests.map((r) => _buildLeaveCard(r, provider, theme)),
                          const SizedBox(height: 32),
                        ],
                        if (historyRequests.isNotEmpty) ...[
                          _buildSectionHeader('HISTORY'),
                          const SizedBox(height: 16),
                          ...historyRequests.map((r) => _buildLeaveCard(r, provider, theme)),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff/leave/request'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.type == LeaveType.fullDay ? 'FULL DAY' : 'HALF DAY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ),
                StatusBadge(label: request.status.name.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.date_range_rounded, size: 20, color: AppTheme.textDark),
                const SizedBox(width: 12),
                Text(
                  request.startDate == request.endDate 
                    ? DateFormat('MMM dd, yyyy').format(request.startDate)
                    : '${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              request.reason, 
              style: TextStyle(height: 1.5, color: AppTheme.textDark),
            ),
            if (isPending) ...[
              Divider(height: 32, color: AppTheme.divider),
              SizedBox(
                width: double.infinity,
                child: PremiumButton(
                  label: 'Cancel Request',
                  isOutline: true,
                  color: AppTheme.error,
                  onPressed: () => _handleCancelRequest(provider, request.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleCancelRequest(LeaveProvider provider, String id) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumConfirmationDialog(
        title: 'Cancel Leave Request?',
        message: 'Are you sure you want to withdraw this leave request? This action cannot be undone.',
        confirmLabel: 'Cancel Request',
        confirmColor: AppTheme.error,
        icon: Icons.cancel_outlined,
      ),
    );

    if (confirm == true && mounted) {
      final result = await provider.cancelLeaveRequest(id);
      if (mounted) {
        result.when(
          onSuccess: (_) => Globals.showPremiumSuccess('Leave request cancelled successfully'),
          onFailure: (e) => Globals.showPremiumError(e.toString()),
        );
      }
    }
  }
}
