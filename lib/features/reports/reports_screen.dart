import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app/globals.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/company_provider.dart';
import '../../core/providers/report_provider.dart';
import '../../core/services/pdf_service.dart';
import '../../core/models/employee.dart';
import '../../core/models/intern.dart';
import '../../core/models/report.dart';
import '../../app/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📊 [INIT] ReportsScreen');
  }

  @override
  void dispose() {
    debugPrint('📊 [DISPOSE] ReportsScreen');
    super.dispose();
  }

  Future<void> _handleExport({
    required String companyName,
    required List<Employee> employees,
    required List<Intern> interns,
    required int todayAttendance,
    required List<MapEntry<String, int>> departments,
  }) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();
    Globals.showSnackBar('Preparing executive summary...');

    try {
      await PdfService.generateExecutiveSummary(
        companyName: companyName,
        employees: employees,
        interns: interns,
        todayAttendance: todayAttendance,
        departments: departments,
      );
    } catch (e) {
      Globals.showSnackBar('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAdmin ? _buildAdminReports(context) : _buildStaffReports(context, auth);
  }

    // --- ADMIN VIEW: EXECUTIVE ANALYTICS ---
  Widget _buildAdminReports(BuildContext context) {
    final theme = Theme.of(context);
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final reportProvider = context.watch<ReportProvider>();

    if (employeeProvider.isLoading || internProvider.isLoading || reportProvider.isLoading) {
      return const Scaffold(backgroundColor: AppTheme.background, body: Center(child: CircularProgressIndicator()));
    }

    final employees = employeeProvider.employees;
    final interns = internProvider.interns;
    
    // Efficient Calculation: Single-pass analytics
    double totalSalary = 0;
    double totalStipend = 0;
    final Map<String, int> deptMap = {};

    for (final e in employees) {
      if (e.status == 'active') {
        totalSalary += e.salary;
        final d = e.department.trim().isEmpty ? 'Unassigned' : e.department;
        deptMap[d] = (deptMap[d] ?? 0) + 1;
      }
    }
    for (final i in interns) {
      if (i.status == 'ongoing') {
        totalStipend += i.stipend;
        final d = i.department.trim().isEmpty ? 'Unassigned' : i.department;
        deptMap[d] = (deptMap[d] ?? 0) + 1;
      }
    }

    final totalStaff = employees.length + interns.length;
    final todayAttendance = attendanceProvider.getAttendanceForDate(DateTime.now()).length;
    final currencyFormat = NumberFormat.compactCurrency(symbol: '₹', locale: 'en_IN');
    final sortedDepts = deptMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.background.withOpacity(0.8),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  centerTitle: false,
                  title: Text('Performance', style: theme.appBarTheme.titleTextStyle),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainChart(theme),
                      const SizedBox(height: 24),
                      _buildMetricsGrid(currencyFormat, totalSalary, totalStipend, todayAttendance, totalStaff, theme),
                      const SizedBox(height: 32),
                      _buildDepartmentSection(sortedDepts, totalStaff, theme),
                      const SizedBox(height: 32),
                      _buildWorkLogReview(reportProvider, theme, true),
                      const SizedBox(height: 32),
                      _buildExportCard(
                        context.read<CompanyProvider>().name ?? 'Learnyor CRM',
                        employees,
                        interns,
                        todayAttendance,
                        sortedDepts,
                        theme,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isExporting)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  // --- STAFF VIEW: PERSONAL PRODUCTIVITY ---
  Future<void> _handleStatusUpdate(BuildContext context, ReportProvider provider, String id, ReportStatus status) async {
    final result = await provider.updateReportStatus(id, status);
    result.when(
      onSuccess: (_) => Globals.showSnackBar('Report ${status.name}'),
      onFailure: (e) => Globals.showSnackBar('Update failed: ${e.toString()}', isError: true),
    );
  }

  Widget _buildStaffReports(BuildContext context, AuthProvider auth) {
    final theme = Theme.of(context);
    final reportProvider = context.watch<ReportProvider>();
    final myReports = reportProvider.getReportsByStaff(auth.userEmail ?? 'anonymous');
    final totalHours = myReports.fold<int>(0, (sum, r) => sum + r.hoursWorked);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('My Work Logs'), elevation: 0, backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonalStats(totalHours, myReports.length, theme),
            const SizedBox(height: 32),
            _buildWorkLogReview(reportProvider, theme, false, staffEmail: auth.userEmail),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalStats(int hours, int count, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _MetricTile(t: 'Total Hours', v: hours.toString(), i: Icons.timer_outlined, c: AppTheme.primary, theme: theme)),
        const SizedBox(width: 16),
        Expanded(child: _MetricTile(t: 'Submissions', v: count.toString(), i: Icons.description_outlined, c: AppTheme.accent, theme: theme)),
      ],
    );
  }

  Widget _buildWorkLogReview(ReportProvider reportProvider, ThemeData theme, bool isAdmin, {String? staffEmail}) {
    final reports = isAdmin ? reportProvider.reports : reportProvider.getReportsByStaff(staffEmail ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isAdmin ? 'STAFF WORK LOGS' : 'RECENT SUBMISSIONS', style: theme.textTheme.labelLarge),
            if (isAdmin)
              TextButton(
                onPressed: () => context.push('/reports/admin'),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (reports.isEmpty)
          BentoCard(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_edu_rounded, size: 48, color: AppTheme.textLight.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No logs found', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
                ],
              ),
            ),
          )
        else
          ...reports.map((report) => _buildReviewCard(report, reportProvider, theme, isAdmin)),
      ],
    );
  }

  Widget _buildReviewCard(WorkReport report, ReportProvider provider, ThemeData theme, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BentoCard(
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
                    Text(report.staffName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    Text(DateFormat('MMM dd, yyyy').format(report.date), style: theme.textTheme.bodySmall),
                  ],
                ),
                StatusBadge(
                  label: report.status.toString().split('.').last.toUpperCase(), 
                  color: report.status == ReportStatus.approved ? AppTheme.success : (report.status == ReportStatus.rejected ? AppTheme.error : AppTheme.accent)
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(report.description, style: theme.textTheme.bodyMedium),
            if (isAdmin && report.status == ReportStatus.pending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => provider.updateReportStatus(report.id, ReportStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => provider.updateReportStatus(report.id, ReportStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // --- ADMIN UI COMPONENTS (EXISTING) ---
  Widget _buildMainChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Active Engagement', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Real-time participation rate', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ]),
          const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
        ]),
        const SizedBox(height: 32),
        SizedBox(height: 120, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
          _Bar(height: 0.4, label: 'M', theme: theme),
          _Bar(height: 0.7, label: 'T', theme: theme),
          _Bar(height: 0.9, label: 'W', isHighlight: true, theme: theme),
          _Bar(height: 0.6, label: 'T', theme: theme),
          _Bar(height: 0.8, label: 'F', theme: theme),
          _Bar(height: 0.3, label: 'S', theme: theme),
        ])),
      ]),
    );
  }

  Widget _buildMetricsGrid(NumberFormat f, double sal, double sti, int today, int total, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.4,
      children: [
        _MetricTile(t: 'Salaries', v: f.format(sal), i: Icons.wallet_rounded, c: AppTheme.accent, theme: theme),
        _MetricTile(t: 'Stipends', v: f.format(sti), i: Icons.payments_rounded, c: const Color(0xFF6366F1), theme: theme),
        _MetricTile(t: 'Present', v: today.toString(), i: Icons.check_circle_rounded, c: AppTheme.success, theme: theme),
        _MetricTile(t: 'Absent', v: (total - today).toString(), i: Icons.cancel_rounded, c: AppTheme.error, theme: theme),
      ],
    );
  }

  Widget _buildDepartmentSection(List<MapEntry<String, int>> depts, int total, ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STAFF DISTRIBUTION', style: theme.textTheme.labelLarge),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.border), boxShadow: AppTheme.softShadow),
        child: depts.isEmpty ? const Center(child: Text('No data')) : Column(children: depts.map((e) => _DeptRow(n: e.key, c: e.value, t: total, theme: theme)).toList()),
      ),
    ]);
  }

  Widget _buildExportCard(String cName, List<Employee> e, List<Intern> i, int today, List<MapEntry<String, int>> d, ThemeData theme) {
    return BentoCard(
      onTap: _isExporting ? null : () => _handleExport(companyName: cName, employees: e, interns: i, todayAttendance: today, departments: d),
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.error, size: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Executive Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), Text('Export PDF Analysis', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight))])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textLight),
      ]),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String t, v; final IconData i; final Color c; final ThemeData theme;
  const _MetricTile({required this.t, required this.v, required this.i, required this.c, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(i, color: c, size: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text(t.toUpperCase(), style: theme.textTheme.labelLarge?.copyWith(fontSize: 9, letterSpacing: 1)),
        ]),
      ]),
    );
  }
}

class _DeptRow extends StatelessWidget {
  final String n; final int c, t; final ThemeData theme;
  const _DeptRow({required this.n, required this.c, required this.t, required this.theme});
  @override
  Widget build(BuildContext context) {
    final p = t == 0 ? 0.0 : c / t;
    return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(n, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark)), Text('$c', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.accent))]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: p, minHeight: 6, backgroundColor: AppTheme.divider, valueColor: const AlwaysStoppedAnimation(AppTheme.accent))),
    ]));
  }
}

class _Bar extends StatelessWidget {
  final double height; final String label; final bool isHighlight; final ThemeData theme;
  const _Bar({required this.height, required this.label, required this.theme, this.isHighlight = false});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(width: 18, height: 80 * height, decoration: BoxDecoration(color: isHighlight ? Colors.white : Colors.white30, borderRadius: BorderRadius.circular(6))),
      const SizedBox(height: 12),
      Text(label, style: theme.textTheme.labelLarge?.copyWith(color: isHighlight ? Colors.white : Colors.white60, fontSize: 9)),
    ]);
  }
}
