import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnyor_hrm/core/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
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
    final reportProvider = context.read<ReportProvider>();
    final isLoading = context.select<ReportProvider, bool>((p) => p.isLoading);
    final reports = context.select<ReportProvider, List<WorkReport>>((p) => p.reports);
    
    // Selective Watching: Only rebuild if these specific sets change
    final employeeEmails = context.select<EmployeeProvider, Set<String>>(
      (p) => p.employees.map((e) => e.email.toLowerCase().trim()).toSet()
    );
    final internEmails = context.select<InternProvider, Set<String>>(
      (p) => p.interns.map((i) => i.email.toLowerCase().trim()).toSet()
    );
    
    // Filter logic
    List<WorkReport> filteredReports = List.from(reports);
    
    // 1. Status Filter
    if (_filterStatus != null) {
      filteredReports = filteredReports.where((r) => r.status == _filterStatus).toList();
    }
    
    // 2. Role Filter
    if (_filterRole != null && _filterRole != 'ALL') {
      filteredReports = filteredReports.where((r) {
        final email = r.staffId.toLowerCase().trim();
        if (_filterRole == 'STAFF') return employeeEmails.contains(email);
        if (_filterRole == 'INTERN') return internEmails.contains(email);
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
          SliverAppBar(centerTitle: true,
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
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports',style: TextStyle(fontSize: 35),),
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
                              icon: Icon(Icons.close_rounded, size: 20, color: AppTheme.error),
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
                                child: _buildMenuRow(Icons.groups_rounded, 'everyone', AppTheme.textMid, isSelected: _filterRole == null || _filterRole == 'ALL'),
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
                              label: (_filterRole == null || _filterRole == 'ALL') ? 'everyone' : _filterRole!,
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
        body: isLoading 
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
                          child: _buildReportCard(context, filteredReports[index], reportProvider, theme),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, WorkReport report, ReportProvider provider, ThemeData theme) {
    final statusStr = report.status.toString().split('.').last;
    final statusColor = statusStr == 'approved' ? AppTheme.success : (statusStr == 'rejected' ? AppTheme.error : AppTheme.accent);
    
    final authorEmail = report.staffId.toLowerCase().trim();
    final employee = context.read<EmployeeProvider>().employees.where((e) => e.email.toLowerCase().trim() == authorEmail).firstOrNull;
    final intern = employee == null ? context.read<InternProvider>().interns.where((i) => i.email.toLowerCase().trim() == authorEmail).firstOrNull : null;
    
    final photoUrl = employee?.photoUrl ?? intern?.photoUrl;
    final isEmployee = employee != null;
    final isIntern = !isEmployee && intern != null;
    final roleLabel = isEmployee ? 'STAFF' : (isIntern ? 'INTERN' : 'NEW');
    final roleColor = isEmployee ? AppTheme.primary : AppTheme.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BentoCard(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/reports/detail', extra: report);
        },
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(report, photoUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.staffName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                      Text(DateFormat('EEEE, MMM dd').format(report.date), style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textLight)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text(roleLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 6),
                    Text('${report.hoursWorked}h Worked', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  ],
                ),
              ],
            ),
            Divider(height: 32, color: AppTheme.divider),
            Text(report.description, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textDark, height: 1.5)),
            if (report.tasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      "•",
      style: TextStyle(
        color: AppTheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1,
      ),
    ),
  ),

  const SizedBox(width: 10),

  Expanded(
    child: Text(
      t,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppTheme.textMid,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
],
                  ),
                )).toList(),
              ),
            ],
            if (report.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: AppTheme.divider),
              const SizedBox(height: 12),
              Text(
                'ATTACHMENTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMid,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.attachments.map((url) {
                  final name = _getFileName(url);
                  final icon = _getFileIcon(url);
                  return ActionChip(
                    avatar: Icon(icon, size: 16, color: AppTheme.primary),
                    label: Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
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
                            Globals.showSnackBar('Could not open attachment', isError: true);
                          }
                        } catch (e) {
                          Globals.showSnackBar('Could not open attachment', isError: true);
                        }
                      }
                    },
                    backgroundColor: AppTheme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppTheme.border),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(label: statusStr.toUpperCase(), color: statusColor),
                if (report.status == ReportStatus.pending) 
                  Row(
                    children: [
                      _buildActionButton('REJECT', AppTheme.error, () => _handleStatusUpdate(provider, report.id, ReportStatus.rejected), isOutline: true),
                      const SizedBox(width: 8),
                      _buildActionButton('APPROVE', AppTheme.success, () => _handleStatusUpdate(provider, report.id, ReportStatus.approved)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Widget _buildAvatar(WorkReport report, String? photoUrl) {
    return PremiumImage(
      imageUrl: ApiConfig.getFullImageUrl(photoUrl),
      size: 44,
      isCircle: true,
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

  Widget _buildActionButton(String label, Color color, VoidCallback onTap, {bool isOutline = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: isOutline ? Border.all(color: color.withValues(alpha: 0.5)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isOutline ? color : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
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
