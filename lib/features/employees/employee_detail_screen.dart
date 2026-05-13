import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/employee.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/widgets/premium_widgets.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final String employeeId;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeProvider>().employees.firstWhere(
      (e) => e.id == employeeId,
      orElse: () => Employee(id: '', name: 'Not Found', email: '', phone: '', designation: '', department: '', joiningDate: DateTime.now(), salary: 0, address: ''),
    );

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFFF8FAFC).withOpacity(0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary),
                onPressed: () => context.push('/employees/add', extra: employee.toMap()),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _showDeleteDialog(context, employee),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: const FlexibleSpaceBar(
              stretchModes: [StretchMode.zoomBackground],
              titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Text(
                'Staff Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                children: [
                  _buildIdentityHeader(employee),
                  const SizedBox(height: 24),
                  _buildQuickActions(employee),
                  const SizedBox(height: 24),
                  _buildEmploymentDetails(employee, currencyFormat),
                  const SizedBox(height: 24),
                  _buildContactDetails(employee),
                  const SizedBox(height: 24),
                  _AttendanceSection(personId: employee.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityHeader(Employee employee) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Hero(
            tag: 'emp_${employee.id}',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 2),
              ),
              child: PremiumImage(
                imageUrl: ApiConfig.getFullImageUrl(employee.photoUrl),
                size: 100,
                isCircle: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            employee.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
          ),
          Text(
            employee.designation,
            style: TextStyle(fontSize: 14, color: Colors.blueGrey.withOpacity(0.6), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallBadge(employee.department, AppTheme.primary),
              const SizedBox(width: 8),
              _buildSmallBadge('ACTIVE', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildQuickActions(Employee employee) {
    return Row(
      children: [
        _CircleAction(icon: Icons.phone_rounded, color: Colors.green, onTap: () => _makeCall(employee.phone)),
        _CircleAction(icon: Icons.message_rounded, color: const Color(0xFF25D366), onTap: () => _openWhatsApp(employee.phone, employee.name)),
        _CircleAction(icon: Icons.alternate_email_rounded, color: Colors.blue, onTap: () => _sendEmail(employee.email)),
      ],
    );
  }

  Widget _buildEmploymentDetails(Employee employee, NumberFormat f) {
    return _DetailSection(
      title: 'Employment Information',
      children: [
        _DetailRow(icon: Icons.business_center_rounded, label: 'Department', value: employee.department),
        _DetailRow(icon: Icons.event_note_rounded, label: 'Joined On', value: DateFormat('MMM dd, yyyy').format(employee.joiningDate)),
        _DetailRow(icon: Icons.wallet_rounded, label: 'Salary', value: f.format(employee.salary)),
      ],
    );
  }

  Widget _buildContactDetails(Employee employee) {
    return _DetailSection(
      title: 'Contact Information',
      children: [
        _DetailRow(icon: Icons.email_outlined, label: 'Email Address', value: employee.email),
        _DetailRow(icon: Icons.phone_android_rounded, label: 'Phone Number', value: employee.phone),
        _DetailRow(icon: Icons.location_on_outlined, label: 'Home Address', value: employee.address),
      ],
    );
  }

  void _makeCall(String p) async => await launchUrl(Uri.parse('tel:$p'));
  void _sendEmail(String e) async => await launchUrl(Uri.parse('mailto:$e'));
  void _openWhatsApp(String p, String n) async {
    final clean = p.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse("https://wa.me/91$clean?text=Hello $n"), mode: LaunchMode.externalApplication);
  }

  void _showDeleteDialog(BuildContext context, Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Delete Profile?',
        message: 'Are you sure you want to remove ${employee.name}?',
        confirmLabel: 'Delete',
        confirmColor: Colors.redAccent,
        icon: Icons.person_remove_rounded,
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<EmployeeProvider>().deleteEmployee(employee.id);
      if (context.mounted) context.pop();
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title; final List<Widget> children;
  const _DetailSection({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.blueGrey, size: 18)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey.withOpacity(0.6), letterSpacing: 0.5)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  final String personId;
  const _AttendanceSection({required this.personId});

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>().getAttendanceForPerson(personId);
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 20),
          if (attendance.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No attendance records yet', style: TextStyle(color: Colors.blueGrey))))
          else
            Column(
              children: attendance.take(5).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM dd, yyyy').format(a.date), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    _buildStatusTag(a.status),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(AttendanceStatus status) {
    Color color = Colors.grey;
    if (status == AttendanceStatus.present) color = Colors.green;
    if (status == AttendanceStatus.absent) color = Colors.red;
    if (status == AttendanceStatus.halfDay) color = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}