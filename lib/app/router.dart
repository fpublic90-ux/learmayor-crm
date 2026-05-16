import 'package:go_router/go_router.dart';
import 'package:learnyor_hrm/features/notifications/notification_screen.dart';
import '../core/providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/employees/employees_screen.dart';
import '../features/employees/add_edit_employee_screen.dart';
import '../features/employees/employee_detail_screen.dart';
import '../features/interns/interns_screen.dart';
import '../features/interns/add_edit_intern_screen.dart';
import '../features/interns/intern_detail_screen.dart';
import '../features/attendance/attendance_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/reports/admin_reports_list_screen.dart';
import '../features/leave/admin_leave_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/staff/staff_hub_screen.dart';
import '../features/staff/submit_report_screen.dart';
import '../features/dashboard/onboarding_vault_screen.dart';
import '../features/leave/request_leave_screen.dart';
import 'shell_layout.dart';

class AppRouter {
  static GoRouter getRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) { 
        final isLoggedIn = auth.isLoggedIn;
        final isOnLogin = state.matchedLocation == '/login';
        
        if (!isLoggedIn && !isOnLogin) return '/login';
        if (isLoggedIn && isOnLogin) {
          return auth.isAdmin ? '/dashboard' : '/staff/hub';
        }

        // Security Guard: Prevent Staff from accessing Admin-only directories
        if (isLoggedIn && !auth.isAdmin) {
          final adminOnlyRoutes = ['/dashboard', '/employees', '/interns', '/onboarding'];
          if (adminOnlyRoutes.any((route) => state.matchedLocation.startsWith(route))) {
            return '/staff/hub';
          }
        }

        // Optional: Prevent Admin from accessing Staff Hub (send to Dashboard)
        if (isLoggedIn && auth.isAdmin && state.matchedLocation.startsWith('/staff')) {
          return '/dashboard';
        }
        
        return null;
      },
      refreshListenable: auth,
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        
        // ShellRoute wraps all internal pages with ShellLayout (Sidebar/TopBar)
        ShellRoute(
          builder: (context, state, child) => ShellLayout(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            
            // Employee Management
            GoRoute(path: '/employees', builder: (_, __) => const EmployeesScreen()),
            
            GoRoute(
              path: '/employees/add',
              builder: (_, state) => AddEditEmployeeScreen(employee: state.extra as Map<String, dynamic>?),
            ),
            GoRoute(
              path: '/employees/detail',
              builder: (_, state) => EmployeeDetailScreen(employeeId: state.extra as String),
            ),
            
            // Intern Management
            GoRoute(path: '/interns', builder: (_, __) => const InternsScreen()),
            GoRoute(
              path: '/interns/add',
              builder: (_, state) => AddEditInternScreen(intern: state.extra as Map<String, dynamic>?),
            ),
            GoRoute(
              path: '/interns/detail',
              builder: (_, state) => InternDetailScreen(internId: state.extra as String),
            ),
            
            // CRM Features
            GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
            GoRoute(path: '/reports/admin', builder: (_, __) => const AdminReportsListScreen()),
            GoRoute(path: '/reports/leave', builder: (_, __) => const AdminLeaveListScreen()),
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
            GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingVaultScreen()),
            GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),

            // Staff Portal Specific Routes
            GoRoute(path: '/staff/hub', builder: (_, __) => const StaffHubScreen()),
            GoRoute(path: '/staff/report/add', builder: (_, __) => const SubmitReportScreen()),
            GoRoute(path: '/staff/leave/request', builder: (_, __) => const RequestLeaveScreen()),
          ],
        ),
      ],
    );
  }
}
