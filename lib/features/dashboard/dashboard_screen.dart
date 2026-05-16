import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:learnyor_hrm/core/config/api_config.dart';
import 'package:learnyor_hrm/core/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../core/models/attendance.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/report_provider.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final auth = context.watch<AuthProvider>();

    final employeeCount = employeeProvider.employees.length;
    final internCount = internProvider.interns.length;
    final totalStaff = employeeCount + internCount;

    final todayAttendance = attendanceProvider.getAttendanceForDate(DateTime.now())
        .where((a) => a.status == AttendanceStatus.present || a.status == AttendanceStatus.halfDay)
        .length;

    final attendancePercent = totalStaff > 0 ? todayAttendance / totalStaff : 0.0;
    final isLoading = employeeProvider.isLoading || internProvider.isLoading || attendanceProvider.isLoading;
    final allUsers = auth.allUsers;

    // Relational Diagnostics: Identifying pending sign-ups across the system
    final onboardedEmails = {
      ...employeeProvider.employees.map((e) => e.email.toLowerCase().trim()),
      ...internProvider.interns.map((i) => i.email.toLowerCase().trim()),
    };
    
    final pendingUsers = allUsers.where((u) {
      final email = u['email']?.toString().toLowerCase().trim();
      if (email == null || email.isEmpty || email == 'null') return false;
      
      final isSelf = email == auth.userEmail?.toLowerCase().trim();
      final isAlreadyOnboarded = onboardedEmails.contains(email);
      
      // We are looking for any user who is NOT the admin and NOT yet officially onboarded
      return !isSelf && !isAlreadyOnboarded;
    }).toList();

    debugPrint('📊 [DASHBOARD] Sync: ${allUsers.length} total users, ${pendingUsers.length} pending onboarding');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint('🔄 [ACTION] Manual Refresh Triggered');
          await Future.wait<void>([
            context.read<AuthProvider>().fetchAllUsers(),
            context.read<EmployeeProvider>().fetchEmployees(),
            context.read<InternProvider>().fetchInterns(),
            context.read<ReportProvider>().fetchReports(),
            context.read<AttendanceProvider>().fetchAttendance(),
          ]);
        },
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primarySubtle.withOpacity(0.3),
                AppTheme.background,
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(context, auth, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: isLoading 
                    ? _buildSkeleton()
                    : AnimationLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 800),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 40.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              const SizedBox(height: 12),
                              if (pendingUsers.isNotEmpty) ...[
                                _buildRegistrationAlert(context, pendingUsers.length, theme),
                                const SizedBox(height: 24),
                              ],
                              _buildAttendanceHero(context, attendancePercent, todayAttendance, totalStaff, theme),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ExecutiveStatCard(
                                      title: 'STAFF MEMBERS',
                                      value: employeeCount.toString(),
                                      icon: Icons.people_rounded,
                                      color: AppTheme.primary,
                                      onTap: () => context.push('/employees'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _ExecutiveStatCard(
                                      title: 'INTERNS',
                                      value: internCount.toString(),
                                      icon: Icons.school_rounded,
                                      color: AppTheme.accent,
                                      onTap: () => context.push('/interns'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildQuickActionSection(context, theme),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationAlert(BuildContext context, int count, ThemeData theme) {
    return BentoCard(
      isKinetic: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.person_add_rounded, color: AppTheme.warning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PENDING ONBOARDING', style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.warning, letterSpacing: 1)),
                Text('$count new sign-ups detected', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/onboarding'), 
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.background.withValues(alpha: 0.8),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            centerTitle: false,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  auth.userName?.split(' ')[0] ?? 'Admin',
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 22),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1), width: 1.5),
                boxShadow: AppTheme.softShadow,
              ),
              child: PremiumImage(
                imageUrl: ApiConfig.getFullImageUrl(auth.profilePicUrl),
                size: 42,
                isCircle: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
 }

  Widget _buildAttendanceHero(BuildContext context, double percent, int present, int total, ThemeData theme) {
    return BentoCard(
      isKinetic: true,
      onTap: () => context.push('/attendance'),
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text('LIVE STATUS', style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.success)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Daily Presence', style: theme.textTheme.headlineMedium),
                Text('Real-time tracking active', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _buildMiniBadge(Icons.check_circle_rounded, '$present Active', AppTheme.success),
                    const SizedBox(width: 12),
                    _buildMiniBadge(Icons.group_rounded, '$total Total', AppTheme.accent),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(width: 90, height: 90, child: CircularProgressIndicator(value: 1.0, strokeWidth: 10, valueColor: AlwaysStoppedAnimation(AppTheme.divider))),
              SizedBox(
                width: 90, height: 90,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percent),
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.elasticOut,
                  builder: (context, value, _) => CircularProgressIndicator(value: value, strokeWidth: 10, strokeCap: StrokeCap.round, valueColor: const AlwaysStoppedAnimation(AppTheme.accent)),
                ),
              ),
              Text('${(percent * 100).toInt()}%', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData i, String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.1))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 14, color: c), const SizedBox(width: 6), Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c))]),
    );
  }

  Widget _buildQuickActionSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACTIONS', style: theme.textTheme.labelLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionTile(context, 'Hire Staff', Icons.person_add_rounded, AppTheme.primary, () => context.push('/employees/add'), theme)),
            const SizedBox(width: 16),
            Expanded(child: _buildActionTile(context, 'Onboard Intern', Icons.school_rounded, AppTheme.accent, () => context.push('/interns/add'), theme)),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          context, 
          'Manage Leave Requests', 
          Icons.event_note_rounded, 
          AppTheme.primary, 
          () => context.push('/reports/leave'), 
          theme,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, String t, IconData i, Color c, VoidCallback onTap, ThemeData theme, {bool isFullWidth = false}) {
    return BentoCard(
      isKinetic: true,
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: isFullWidth 
        ? Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                child: Icon(i, color: c, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(t, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textLight),
            ],
          )
        : Column(
            children: [
              Icon(i, color: c, size: 28),
              const SizedBox(height: 12),
              Text(t, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ],
          ),
    );
  }

  Widget _buildSkeleton() {
    return const Column(children: [SizedBox(height: 20), ShimmerLoading(width: double.infinity, height: 180, borderRadius: 28), SizedBox(height: 24), Row(children: [Expanded(child: ShimmerLoading(width: double.infinity, height: 150, borderRadius: 28)), SizedBox(width: 16), Expanded(child: ShimmerLoading(width: double.infinity, height: 150, borderRadius: 28))])]);
  }


class _ExecutiveStatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color; final VoidCallback onTap;
  const _ExecutiveStatCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      isKinetic: true,
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 24),
          Text(value, style: theme.textTheme.displayMedium),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
