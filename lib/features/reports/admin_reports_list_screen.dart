import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import '../../app/globals.dart';
import '../../core/providers/report_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/models/report.dart';
import '../../core/widgets/premium_widgets.dart';

class AdminReportsListScreen extends StatefulWidget {
  const AdminReportsListScreen({super.key});

  @override
  State<AdminReportsListScreen> createState() => _AdminReportsListScreenState();
}

class _AdminReportsListScreenState extends State<AdminReportsListScreen> {
  ReportStatus? _filterStatus;
  String? _filterRole; // 'STAFF' or 'INTERN'
  DateTime? _selectedDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.accent,
            onPrimary: Colors.white,
            onSurface: AppTheme.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<InternProvider>().fetchInterns();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportProvider = context.watch<ReportProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final employeeIds = employeeProvider.employees.map((e) => e.id.trim()).toSet();
    final internIds = internProvider.interns.map((i) => i.id.trim()).toSet();
    
    // Filter logic
    List<WorkReport> filteredReports = List.from(reportProvider.reports);
    
    // 1. Status Filter
    if (_filterStatus != null) {
      filteredReports = filteredReports.where((r) => r.status == _filterStatus).toList();
    }
    
    // 2. Role Filter
    if (_filterRole != null && _filterRole != 'ALL') {
      filteredReports = filteredReports.where((r) {
        final id = r.staffId.trim();
        if (_filterRole == 'STAFF') return employeeIds.contains(id);
        if (_filterRole == 'INTERN') return internIds.contains(id);
        return true;
      }).toList();
    }

    // 3. Date Filter (Timezone Safe)
    if (_selectedDate != null) {
      final sel = _selectedDate!;
      filteredReports = filteredReports.where((r) {
        final d = r.date.toLocal();
        return d.year == sel.year && d.month == sel.month && d.day == sel.day;
      }).toList();
    }

    // 4. Search Filter
    if (_searchQuery.isNotEmpty) {
      filteredReports = filteredReports.where((r) => 
        r.staffName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        r.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Sort by date (newest first)
    filteredReports.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.background.withValues(alpha: 0.8),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance Analytics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                Text('Staff Work Log Review', style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textLight, letterSpacing: 0.5)),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverHeaderDelegate(
              child: Container(
                color: AppTheme.background,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search staff or tasks...',
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.symmetric(vertical: 0),
                      ).applyDefaults(theme.inputDecorationTheme),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (_selectedDate != null || _filterStatus != null || _filterRole != null || _searchQuery.isNotEmpty) ...[
                            _StatusChip(
                              label: 'Reset',
                              isSelected: true,
                              color: AppTheme.error,
                              icon: Icons.restart_alt_rounded,
                              onTap: () => setState(() {
                                _selectedDate = null;
                                _filterStatus = null;
                                _filterRole = null;
                                _searchController.clear();
                                _searchQuery = '';
                              }),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 1.5, height: 24, color: AppTheme.divider),
                            const SizedBox(width: 16),
                          ],
                          // Date Picker Trigger
                          _StatusChip(
                            label: _selectedDate == null ? 'Filter Date' : DateFormat('MMM dd').format(_selectedDate!),
                            isSelected: _selectedDate != null,
                            color: AppTheme.accent,
                            icon: Icons.calendar_month_rounded,
                            onTap: _pickDate,
                          ),
                          if (_selectedDate != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() => _selectedDate = null),
                              icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.error),
                              style: IconButton.styleFrom(backgroundColor: AppTheme.error.withValues(alpha: 0.1)),
                            ),
                          ],
                          const SizedBox(width: 16),
                          Container(width: 1.5, height: 24, color: AppTheme.divider),
                          const SizedBox(width: 16),

                          // STATUS DROPDOWN
                          PopupMenuButton<dynamic>(
                            onSelected: (v) => setState(() {
                              if (v == 'ALL') {
                                _filterStatus = null;
                              } else {
                                _filterStatus = v as ReportStatus;
                              }
                            }),
                            offset: const Offset(0, 50),
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.05),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppTheme.divider.withValues(alpha: 0.3)),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'ALL', 
                                height: 40,
                                child: _buildMenuRow(Icons.all_inclusive_rounded, 'All Status', AppTheme.textMid, isSelected: _filterStatus == null),
                              ),
                              PopupMenuItem(
                                value: ReportStatus.pending, 
                                height: 40,
                                child: _buildMenuRow(Icons.history_rounded, 'Pending Logs', AppTheme.accent, isSelected: _filterStatus == ReportStatus.pending),
                              ),
                              PopupMenuItem(
                                value: ReportStatus.approved, 
                                height: 40,
                                child: _buildMenuRow(Icons.check_circle_outline_rounded, 'Approved', AppTheme.success, isSelected: _filterStatus == ReportStatus.approved),
                              ),
                              PopupMenuItem(
                                value: ReportStatus.rejected, 
                                height: 40,
                                child: _buildMenuRow(Icons.cancel_outlined, 'Rejected', AppTheme.error, isSelected: _filterStatus == ReportStatus.rejected),
                              ),
                            ],
                            child: _StatusChip(
                              label: _filterStatus == null ? 'All Status' : _filterStatus!.name.toUpperCase(),
                              isSelected: _filterStatus != null,
                              icon: Icons.filter_list_rounded,
                              isDropdown: true,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ROLE DROPDOWN
                          PopupMenuButton<String>(
                            onSelected: (v) => setState(() => _filterRole = v),
                            offset: const Offset(0, 50),
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.05),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppTheme.divider.withValues(alpha: 0.3)),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'ALL', 
                                height: 40,
                                child: _buildMenuRow(Icons.groups_rounded, 'All Roles', AppTheme.textMid, isSelected: _filterRole == null || _filterRole == 'ALL'),
                              ),
                              PopupMenuItem(
                                value: 'STAFF', 
                                height: 40,
                                child: _buildMenuRow(Icons.badge_rounded, 'Staff Members', AppTheme.primary, isSelected: _filterRole == 'STAFF'),
                              ),
                              PopupMenuItem(
                                value: 'INTERN', 
                                height: 40,
                                child: _buildMenuRow(Icons.school_rounded, 'Interns', AppTheme.accent, isSelected: _filterRole == 'INTERN'),
                              ),
                            ],
                            child: _StatusChip(
                              label: (_filterRole == null || _filterRole == 'ALL') ? 'All Roles' : _filterRole!,
                              isSelected: _filterRole != null && _filterRole != 'ALL',
                              icon: Icons.person_search_rounded,
                              isDropdown: true,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: reportProvider.isLoading 
          ? const SkeletonList()
          : filteredReports.isEmpty
            ? EmptyStateWidget(
                title: 'No Logs Found',
                message: 'Adjust your filters or search to find reports.',
                icon: Icons.assignment_late_rounded,
                onAction: () => setState(() {
                  _filterStatus = null;
                  _filterRole = null;
                  _searchController.clear();
                  _searchQuery = '';
                }),
                actionLabel: 'Clear All Filters',
              )
            : AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: _buildReportCard(filteredReports[index], reportProvider, theme),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildReportCard(WorkReport report, ReportProvider provider, ThemeData theme) {
    final statusStr = report.status.toString().split('.').last;
    final statusColor = statusStr == 'approved' ? AppTheme.success : (statusStr == 'rejected' ? AppTheme.error : AppTheme.accent);
    
    // Determine Role (Safe lookup)
    final isEmployee = context.read<EmployeeProvider>().employees.any((e) => e.id == report.staffId);
    final isIntern = !isEmployee && context.read<InternProvider>().interns.any((i) => i.id == report.staffId);
    final roleLabel = isEmployee ? 'STAFF' : (isIntern ? 'INTERN' : 'OTHER');
    final roleColor = isEmployee ? AppTheme.primary : AppTheme.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BentoCard(
        isKinetic: true,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(report.staffName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(DateFormat('MMM dd, yyyy').format(report.date), style: theme.textTheme.bodySmall),
                  ],
                ),
                StatusBadge(label: statusStr.toUpperCase(), color: statusColor),
              ],
            ),
            const SizedBox(height: 16),
            Text(report.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: report.tasks.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(6)),
                child: Text('#$t', style: const TextStyle(fontSize: 10, color: AppTheme.textMid, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            if (report.status == ReportStatus.pending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleStatusUpdate(provider, report.id, ReportStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleStatusUpdate(provider, report.id, ReportStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('APPROVE'),
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

  Future<void> _handleStatusUpdate(ReportProvider provider, String id, ReportStatus status) async {
    final result = await provider.updateReportStatus(id, status);
    result.when(
      onSuccess: (_) => Globals.showSnackBar('Report ${status.name} successfully'),
      onFailure: (e) => Globals.showSnackBar('Action failed: ${e.toString()}', isError: true),
    );
  }

  Widget _buildMenuRow(IconData icon, String label, Color color, {bool isSelected = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isSelected ? color : AppTheme.textLight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textDark,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        if (isSelected)
          Icon(Icons.check_rounded, size: 18, color: AppTheme.success),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;
  final bool isDropdown;

  const _StatusChip({
    required this.label, 
    required this.isSelected, 
    required this.onTap,
    this.color,
    this.icon,
    this.isDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    
    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? activeColor : AppTheme.divider,
          width: 1.5,
        ),
        boxShadow: isSelected ? [BoxShadow(color: activeColor.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textLight),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textMid,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (isDropdown) ...[
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isSelected ? Colors.white : AppTheme.textLight),
          ],
        ],
      ),
    );

    if (isDropdown) return chip;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: chip,
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverHeaderDelegate({required this.child});
  @override
  double get minExtent => 145;
  @override
  double get maxExtent => 145;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) => true;
}
