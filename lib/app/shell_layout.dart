import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:learnyor_hrm/core/providers/attendance_provider.dart';
import 'package:learnyor_hrm/core/providers/employee_provider.dart';
import 'package:learnyor_hrm/core/providers/intern_provider.dart';
import 'package:learnyor_hrm/core/widgets/premium_widgets.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../core/providers/auth_provider.dart';

class ShellLayout extends StatefulWidget {
  final Widget child;

  const ShellLayout({super.key, required this.child});

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _entranceController.forward();

    // Staggered Global Data Warmup to prevent main-thread jank
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        // Phase 1: Directories (Critical for UI Identity)
        await context.read<EmployeeProvider>().fetchEmployees();
        await context.read<InternProvider>().fetchInterns();
        
        // Phase 2: Analytics (Heavy Data, staggered)
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) await context.read<AttendanceProvider>().fetchAttendance();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumConfirmationDialog(
        title: 'Sign Out?',
        message:
            'Are you sure you want to exit your professional session? You will need to sign in again to access the CRM.',
        confirmLabel: 'Sign Out',
        confirmColor: AppTheme.error,
        icon: Icons.logout_rounded,
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  void _syncProfileWithDirectory(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin || !auth.isLoggedIn) return;

    final employeeProvider = context.read<EmployeeProvider>();
    final internProvider = context.read<InternProvider>();
    final userEmail = auth.userEmail?.toLowerCase().trim();

    if (userEmail == null) return;

    String? latestName;
    try {
      if (auth.role == UserRole.employee) {
        latestName = employeeProvider.employees.firstWhere((e) => e.email.toLowerCase().trim() == userEmail).name;
      } else if (auth.role == UserRole.intern) {
        latestName = internProvider.interns.firstWhere((i) => i.email.toLowerCase().trim() == userEmail).name;
      }
    } catch (_) {}

    if (latestName != null && latestName != auth.userName) {
      final nameToSync = latestName!; // Shadow to non-nullable for closure capture
      Future.microtask(() {
        debugPrint('🔄 Auth Sync: Updating local name to $nameToSync');
        auth.refreshLocalProfile(name: nameToSync);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild if the login status or role changes
    final isLoggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    final role = context.select<AuthProvider, UserRole>((a) => a.role);

    // Sync profile data when directory state changes, but don't watch the whole provider
    if (isLoggedIn && role != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncProfileWithDirectory(context));
    }
    
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF1F5F9) : AppTheme.background,
      body: Center(
        child: Container(
          width: isDesktop ? 450 : double.infinity,
          margin: isDesktop ? const EdgeInsets.symmetric(vertical: 32) : null,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: isDesktop ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 50,
                offset: const Offset(0, 20),
              )
            ] : null,
            borderRadius: isDesktop ? BorderRadius.circular(32) : BorderRadius.zero,
          ),
          clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
          child: Column(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );     
    
  }

  String _getAppBarTitle(String location) {
    if (location == '/dashboard') return 'Executive Dashboard';
    if (location == '/staff/hub') return 'Staff Activity Hub';
    if (location.startsWith('/employees')) return 'Staff Directory';
    if (location.startsWith('/interns')) return 'Interns List';
    if (location.startsWith('/attendance')) return 'Attendance';
    if (location.startsWith('/reports')) return 'Performance Analytics';
    if (location == '/settings') return 'Settings';
    return 'Learnyor CRM';
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // Use read to avoid shell-wide rebuilds on auth notifications
    final auth = context.read<AuthProvider>();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home Nav (Changes based on Role)
              _BottomNavItem(
                icon: Icons.dashboard_rounded,
                label: 'Home',
                isSelected: location == '/dashboard' || location == '/staff/hub',
                onTap: () => context.go(auth.isAdmin ? '/dashboard' : '/staff/hub'),
              ),
              
              // Staff only visible to Admin
              if (auth.isAdmin)
                _BottomNavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Staff',
                  isSelected: location.startsWith('/employees'),
                  onTap: () { if (location != '/employees') context.go('/employees'); },
                ),
                
              _BottomNavItem(
                icon: Icons.calendar_today_rounded,
                label: 'Attendance',
                isSelected: location.startsWith('/attendance'),
                onTap: () { if (location != '/attendance') context.go('/attendance'); },
              ),
              
              if (!auth.isAdmin && auth.isLoggedIn)
                _BottomNavItem(
                  icon: Icons.add_rounded,
                  label: 'Add',
                  isSelected: location == '/staff/report/add',
                  isPremium: true,
                  onTap: () => context.push('/staff/report/add'),
                ),

              // Interns only visible to Admin
              if (auth.isAdmin)
                _BottomNavItem(
                  icon: Icons.school_rounded,
                  label: 'Interns',
                  isSelected: location.startsWith('/interns'),
                  onTap: () { if (location != '/interns') context.go('/interns'); },
                ),
                
              _BottomNavItem(
                icon: Icons.analytics_rounded,
                label: auth.isAdmin ? 'Reports' : 'Logs',
                isSelected: location.startsWith('/reports'),
                onTap: () { 
                  final target = auth.isAdmin ? '/reports/admin' : '/reports';
                  if (location != target) context.go(target); 
                },
              ),

              _BottomNavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: location == '/settings',
                onTap: () { if (location != '/settings') context.go('/settings'); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isPremium;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isPremium = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isPremium ? 12 : 8, 
          vertical: isPremium ? 12 : 8
        ),
        decoration: BoxDecoration(
          color: isPremium 
              ? AppTheme.accent 
              : (isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent),
          shape: isPremium ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isPremium ? null : BorderRadius.circular(12),
          boxShadow: isPremium ? [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPremium 
                  ? Colors.white 
                  : (isSelected ? AppTheme.primary : AppTheme.textLight),
              size: isPremium ? 26 : 20,
            ),
            if (!isPremium) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textLight,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
