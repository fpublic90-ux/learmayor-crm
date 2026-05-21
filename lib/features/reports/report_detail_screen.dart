import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../app/globals.dart';
import '../../core/models/report.dart';
import '../../core/providers/report_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/config/api_config.dart';

class ReportDetailScreen extends StatefulWidget {
  final WorkReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isActioning = false;

  Future<void> _handleStatusChange(BuildContext context, ReportProvider provider, ReportStatus status) async {
    if (_isActioning) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: '${status == ReportStatus.approved ? 'Approve' : 'Reject'} Report?',
        message: 'Are you sure you want to change this daily report\'s status to ${status.name.toUpperCase()}?',
        confirmLabel: status == ReportStatus.approved ? 'Approve' : 'Reject',
        confirmColor: status == ReportStatus.approved ? AppTheme.success : AppTheme.error,
        icon: status == ReportStatus.approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isActioning = true);
      HapticFeedback.heavyImpact();
      
      final result = await provider.updateReportStatus(widget.report.id, status);
      
      if (mounted) {
        setState(() => _isActioning = false);
        result.when(
          onSuccess: (_) {
            Globals.showSnackBar('Report ${status.name} successfully');
            Navigator.of(context).pop(); // Back to list view after successful action
          },
          onFailure: (e) {
            Globals.showSnackBar('Action failed: ${e.toString()}', isError: true);
          },
        );
      }
    }
  }

  String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final decoded = Uri.decodeComponent(uri.pathSegments.last);
      return decoded.split('/').last;
    } catch (_) {
      return 'Attachment';
    }
  }

  IconData _getFileIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final reportProvider = context.watch<ReportProvider>();
    
    // Watch report provider to reflect updates instantly (if modified externally or locally)
    final report = reportProvider.reports.firstWhere(
      (r) => r.id == widget.report.id, 
      orElse: () => widget.report
    );

    // Resolve author context (avatar image and role labels)
    final authorEmail = report.staffId.toLowerCase().trim();
    final employee = context.read<EmployeeProvider>().employees.where((e) => e.email.toLowerCase().trim() == authorEmail).firstOrNull;
    final intern = employee == null ? context.read<InternProvider>().interns.where((i) => i.email.toLowerCase().trim() == authorEmail).firstOrNull : null;
    
    final photoUrl = employee?.photoUrl ?? intern?.photoUrl;
    final isEmployee = employee != null;
    final isIntern = !isEmployee && intern != null;
    
    final roleLabel = isEmployee ? 'STAFF' : (isIntern ? 'INTERN' : 'NEW');
    final roleColor = isEmployee ? AppTheme.primary : AppTheme.accent;
    final statusColor = report.status == ReportStatus.approved 
        ? AppTheme.success 
        : (report.status == ReportStatus.rejected ? AppTheme.error : AppTheme.accent);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Report Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reporter Profile Card
                BentoCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      PremiumImage(
                        imageUrl: ApiConfig.getFullImageUrl(photoUrl),
                        size: 56,
                        isCircle: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.staffName, 
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.textDark)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.staffId, 
                              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight)
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.08), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          roleLabel, 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 0.5)
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Metrics Row (Bento style)
                Row(
                  children: [
                    Expanded(
                      child: BentoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.timer_rounded, color: AppTheme.primary, size: 24),
                            const SizedBox(height: 12),
                            Text(
                              '${report.hoursWorked} Hours', 
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.textDark)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'WORKED TODAY', 
                              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textLight, letterSpacing: 0.5)
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BentoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.assignment_turned_in_rounded, color: statusColor, size: 24),
                            const SizedBox(height: 12),
                            StatusBadge(
                              label: report.status.name, 
                              color: statusColor
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'REVIEW STATUS', 
                              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textLight, letterSpacing: 0.5)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Report Date Details
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primary.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Text(
                      'SUBMISSION DATE: ${DateFormat('EEEE, MMMM dd, yyyy').format(report.date)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMid, letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Description Bento Card
                BentoCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY SUMMARY', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1.0)
                      ),
                      const SizedBox(height: 12),
                      Text(
                        report.description, 
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textDark, height: 1.6, fontSize: 14)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Achievements / Specific Tasks List
                if (report.tasks.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.fact_check_rounded, size: 14, color: AppTheme.primary.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        'SPECIFIC ACHIEVEMENTS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMid, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BentoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: report.tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.accent, 
                                shape: BoxShape.circle
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task, 
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4
                                )
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Supporting Documents & Attachments
                if (report.attachments.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.attach_file_rounded, size: 14, color: AppTheme.primary.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        'SUPPORTING DOCUMENTS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMid, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BentoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: report.attachments.map((url) {
                            final name = _getFileName(url);
                            final icon = _getFileIcon(url);
                            return ActionChip(
                              avatar: Icon(icon, size: 18, color: AppTheme.primary),
                              label: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              onPressed: () async {
                                debugPrint('📂 [LAUNCH ATTACHMENT] Attempting to open URL: $url');
                                final isImage = url.toLowerCase().contains(RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)')) || url.contains('image/upload');
                                if (isImage) {
                                  PremiumImageViewer.show(context, url);
                                } else {
                                  final uri = Uri.parse(url);
                                  try {
                                    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    if (!launched) {
                                      debugPrint('❌ [LAUNCH ATTACHMENT ERROR] launchUrl returned false for: $url');
                                      Globals.showSnackBar('Could not open attachment', isError: true);
                                    }
                                  } catch (e) {
                                    debugPrint('❌ [LAUNCH ATTACHMENT ERROR] Exception: $e');
                                    Globals.showSnackBar('Could not open attachment', isError: true);
                                  }
                                }
                              },
                              backgroundColor: AppTheme.background,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppTheme.border.withOpacity(0.5)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Extra padding to avoid overlaying floating panel
                if (auth.isAdmin && report.status == ReportStatus.pending)
                  const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Floating Action Panel for Administrators (Approve/Reject)
          if (auth.isAdmin && report.status == ReportStatus.pending)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PremiumButton(
                          label: 'REJECT',
                          color: AppTheme.error,
                          isOutline: true,
                          isLoading: _isActioning,
                          onPressed: () => _handleStatusChange(context, reportProvider, ReportStatus.rejected),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PremiumButton(
                          label: 'APPROVE',
                          color: AppTheme.success,
                          isLoading: _isActioning,
                          onPressed: () => _handleStatusChange(context, reportProvider, ReportStatus.approved),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
