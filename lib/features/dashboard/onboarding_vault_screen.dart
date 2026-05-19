 import 'package:flutter/material.dart';
import 'package:learnyor_hrm/app/globals.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';

class OnboardingVaultScreen extends StatefulWidget {
  const OnboardingVaultScreen({super.key});

  @override
  State<OnboardingVaultScreen> createState() => _OnboardingVaultScreenState();
}

class _OnboardingVaultScreenState extends State<OnboardingVaultScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mandatory Global Sync: Ensure the Vault and Dashboard are in perfect agreement
      context.read<AuthProvider>().fetchAllUsers();
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<InternProvider>().fetchInterns();
      if (mounted) _loadPendingUsers();
    });
  }

  Future<void> _loadPendingUsers() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final empProvider = context.read<EmployeeProvider>();
    final intProvider = context.read<InternProvider>();

    try {
      debugPrint('📡 Vault: Synchronizing Onboarding Data...');
      // Force refresh official lists first to be sure
      await Future.wait([
        empProvider.fetchEmployees(),
        intProvider.fetchInterns(),
        auth.fetchAllUsers(),
      ]);

      final allUsers = auth.allUsers;
      debugPrint('📥 Vault: Received ${allUsers.length} total users from database');
      
      // Filter out existing staff/interns by email (Case-Insensitive & Trimmed)
      final existingEmails = {
        ...empProvider.employees.map((e) => e.email.toLowerCase().trim()),
        ...intProvider.interns.map((i) => i.email.toLowerCase().trim()),
      };

      final pending = allUsers.where((u) {
        final email = (u['email'] as String?)?.toLowerCase().trim() ?? '';
        final isAdmin = email == 'jafarevx123@gmail.com';
        final isAlreadyOnboarded = existingEmails.contains(email);
        
        return email.isNotEmpty && !isAdmin && !isAlreadyOnboarded;
      }).toList();

      debugPrint('🎯 Vault: Found ${pending.length} pending users for onboarding');

      if (mounted) {
        setState(() {
          _pendingUsers = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Vault Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Globals.showSnackBar('Failed to synchronize vault: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Onboarding Vault'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loadPendingUsers, 
            icon: Icon(Icons.refresh_rounded, color: AppTheme.primary)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : _pendingUsers.isEmpty
          ? RefreshIndicator(
              onRefresh: _loadPendingUsers,
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const EmptyStateWidget(
                    title: 'Vault is Empty', 
                    message: 'All registered users are already onboarded.',
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPendingUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = _pendingUsers[index];
                  return _buildPendingCard(user, theme);
                },
              ),
            ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> user, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BentoCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.person_outline_rounded, color: AppTheme.accent),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? 'New User', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  Text(user['email'] ?? '', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _handleDeleteUser(user['email']),
              icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              tooltip: 'Delete User Account',
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _startOnboarding(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ONBOARD'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteUser(String? email) async {
    if (email == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Delete User Account?',
        message: 'Are you sure you want to permanently delete $email from the database? This action cannot be undone.',
        confirmLabel: 'Delete Permanently',
        confirmColor: AppTheme.error,
        icon: Icons.delete_forever_rounded,
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AuthProvider>().deleteUser(email);
      if (success) {
        Globals.showSnackBar('User account deleted successfully');
        _loadPendingUsers(); // Refresh the list
      } else {
        Globals.showSnackBar('Failed to delete user account', isError: true);
      }
    }
  }

  void _startOnboarding(Map<String, dynamic> user) {
    final role = user['role'] ?? 'employee';
    final targetRoute = role == 'intern' ? '/interns/add' : '/employees/add';
    
    context.push(targetRoute, extra: {
      'name': user['name'],
      'email': user['email'],
    });
  }
}
