import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/intern.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/widgets/premium_widgets.dart';

class InternDetailScreen extends StatelessWidget {
  final String internId;

  const InternDetailScreen({
    super.key,
    required this.internId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intern = context.watch<InternProvider>().interns.firstWhere(
          (i) => i.id == internId,
          orElse: () => Intern(
            id: '',
            name: 'Not Found',
            email: '',
            phone: '',
            college: '',
            department: '',
            startDate: DateTime.now(),
            endDate: DateTime.now(),
            stipend: 0,
            mentor: '',
          ),
        );

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Intern Profile', style: theme.appBarTheme.titleTextStyle),
            Text('Professional Internship Overview', style: theme.textTheme.labelLarge?.copyWith(fontSize: 9, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: () => context.push('/interns/add', extra: intern.toMap()),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
              onPressed: () => _showDeleteDialog(context, intern),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ResponsiveWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              return Column(
                children: [
                  BentoCard(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primarySubtle, AppTheme.background],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 32 : 24),
                        child: isDesktop ? _buildDesktopHeader(intern, theme) : _buildMobileHeader(intern, theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, intern, theme),
                  const SizedBox(height: 24),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildInternshipDetails(intern, theme)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildFinancials(intern, currencyFormat, theme)),
                      ],
                    )
                  else ...[
                    _buildInternshipDetails(intern, theme),
                    const SizedBox(height: 24),
                    _buildFinancials(intern, currencyFormat, theme),
                  ],
                  const SizedBox(height: 24),
                  _AttendanceSection(personId: intern.id, theme: theme),
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(Intern intern, ThemeData theme) {
    return Row(
      children: [
        Hero(
          tag: 'intern_${intern.id}',
          child: PremiumImage(imageUrl: ApiConfig.getFullImageUrl(intern.photoUrl), size: 140, borderRadius: 24),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intern.name, style: theme.textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(intern.college, style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textMid)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12, runSpacing: 12,
                children: [
                  StatusBadge(label: intern.department.toUpperCase(), color: AppTheme.accent),
                  StatusBadge(label: intern.duration.toUpperCase(), color: AppTheme.primary),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(Intern intern, ThemeData theme) {
    return Column(
      children: [
        Hero(
          tag: 'intern_${intern.id}',
          child: PremiumImage(imageUrl: ApiConfig.getFullImageUrl(intern.photoUrl), size: 120, borderRadius: 24),
        ),
        const SizedBox(height: 20),
        Text(intern.name, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(intern.college, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMid), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10, runSpacing: 10,
          children: [
            StatusBadge(label: intern.department.toUpperCase(), color: AppTheme.accent),
            StatusBadge(label: intern.duration.toUpperCase(), color: AppTheme.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, Intern intern, ThemeData theme) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK ACTIONS', style: theme.textTheme.labelLarge),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: [
              _ActionButton(icon: Icons.phone_rounded, label: 'Call', color: AppTheme.success, onTap: () => _launch('tel:${intern.phone}')),
              _ActionButton(icon: Icons.message_rounded, label: 'WhatsApp', color: const Color(0xFF25D366), onTap: () => _launch("https://wa.me/91${intern.phone.replaceAll(RegExp(r'[^0-9]'), '')}")),
              _ActionButton(icon: Icons.email_rounded, label: 'Email', color: AppTheme.error, onTap: () => _launch('mailto:${intern.email}')),
              _ActionButton(icon: Icons.trending_up_rounded, label: 'Promote', color: AppTheme.primary, onTap: () => _showPromotionDialog(context, intern)),
            ],
          ),
        ],
      ),
    );
  }

  void _showPromotionDialog(BuildContext context, Intern intern) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Promote to Employee?',
        message: 'This will move ${intern.name} from the Intern directory to the Official Staff directory.',
        confirmLabel: 'Promote Now',
        confirmColor: AppTheme.primary,
        icon: Icons.workspace_premium_rounded,
      ),
    );
    if (confirmed == true && context.mounted) {
      // 1. Prepare data for Employee creation
      final employeeData = {
        'name': intern.name,
        'email': intern.email,
        'phone': intern.phone,
        'department': intern.department,
        'photoUrl': intern.photoUrl,
      };

      // 2. Delete the intern record
      await context.read<InternProvider>().deleteIntern(intern.id);
      
      // 3. Navigate to Add Employee screen with pre-filled data
      if (context.mounted) {
        context.push('/employees/add', extra: employeeData);
      }
    }
  }

  Widget _buildInternshipDetails(Intern intern, ThemeData theme) {
    return _InfoSection(
      title: 'Internship Details',
      theme: theme,
      children: [
        Row(
          children: [
            Expanded(child: DetailTile(icon: Icons.calendar_today_rounded, label: 'Start Date', value: DateFormat('MMM dd, yyyy').format(intern.startDate))),
            Expanded(child: DetailTile(icon: Icons.event_rounded, label: 'End Date', value: DateFormat('MMM dd, yyyy').format(intern.endDate))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: DetailTile(icon: Icons.person_pin_rounded, label: 'Mentor', value: intern.mentor)),
            Expanded(child: DetailTile(icon: Icons.timelapse_rounded, label: 'Duration', value: intern.duration)),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancials(Intern intern, NumberFormat format, ThemeData theme) {
    return _InfoSection(
      title: 'Financials & Status',
      theme: theme,
      children: [
        Row(
          children: [
            Expanded(child: DetailTile(icon: Icons.payments_rounded, label: 'Stipend', value: format.format(intern.stipend))),
            Expanded(child: DetailTile(icon: Icons.verified_rounded, label: 'Certificate', value: intern.certificateIssued ? 'Issued' : 'Pending')),
          ],
        ),
      ],
    );
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showDeleteDialog(BuildContext context, Intern intern) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Terminate Internship?',
        message: 'Are you sure you want to remove ${intern.name} from the directory?',
        confirmLabel: 'Terminate',
        confirmColor: AppTheme.error,
        icon: Icons.person_off_rounded,
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<InternProvider>().deleteIntern(intern.id);
      if (context.mounted) context.pop();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 10), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title; final List<Widget> children; final ThemeData theme;
  const _InfoSection({required this.title, required this.children, required this.theme});
  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  final String personId; final ThemeData theme;
  const _AttendanceSection({required this.personId, required this.theme});
  @override
  Widget build(BuildContext context) {
    final records = context.watch<AttendanceProvider>().getAttendanceForPerson(personId);
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ATTENDANCE HISTORY', style: theme.textTheme.labelLarge),
          const SizedBox(height: 20),
          if (records.isEmpty)
            Center(child: Text('No attendance records found', style: theme.textTheme.bodySmall))
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length.clamp(0, 5),
              separatorBuilder: (_, __) => const Divider(height: 24, color: AppTheme.divider),
              itemBuilder: (context, index) {
                final r = records[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM dd, yyyy').format(r.date), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    StatusBadge(label: r.status.name.toUpperCase(), color: r.status == AttendanceStatus.absent ? AppTheme.error : AppTheme.success),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}