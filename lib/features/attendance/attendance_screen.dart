import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../app/theme.dart';
import '../../app/globals.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/config/api_config.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;
  final Set<String> _syncingIds = {};

  @override
  void initState() {
    super.initState();
    debugPrint('🕒 [INIT] AttendanceScreen');
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeProvider>().fetchEmployees();
      context.read<InternProvider>().fetchInterns();
      context.read<AttendanceProvider>().fetchAttendance();
    });
  }

  @override
  void dispose() {
    debugPrint('🕒 [DISPOSE] AttendanceScreen');
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: auth.isAdmin ? _buildAdminView() : _buildStaffView(auth),
    );
  }

  bool _isCalendarView = true;

  // --- ADMIN VIEW (REGISTRY) ---
  Widget _buildAdminView() {
    final theme = Theme.of(context);
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    final attendanceList = attendanceProvider.getAttendanceForDate(_selectedDate);
    final attendanceMap = {for (var r in attendanceList) r.personId: r};

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _isCalendarView 
        ? _buildCalendarHub(theme, attendanceProvider)
        : _buildDailyRegistry(theme, employeeProvider, internProvider, attendanceProvider, attendanceMap),
    );
  }

  Widget _buildCalendarHub(ThemeData theme, AttendanceProvider provider) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attendance Hub', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text(DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(), 
                style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.today_rounded, color: AppTheme.primary, size: 20),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [  
            _buildSectionHeader('ORGANIZATIONAL CALENDAR', Icons.grid_view_rounded),
            const SizedBox(height: 16 ),
            BentoCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _buildAdminCalendar(theme),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('STATUS CLASSIFICATION', Icons.layers_rounded),
            const SizedBox(height: 16),
            _buildLegend(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMid, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildDailyRegistry(ThemeData theme, EmployeeProvider empP, InternProvider intP, AttendanceProvider attP, Map<String, Attendance> attMap) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            stretch: true,
            toolbarHeight: 80,
            backgroundColor: AppTheme.background.withValues(alpha: 0.8),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            leading: IconButton(
              onPressed: () => setState(() => _isCalendarView = true),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const Text('Daily Registry', style: TextStyle(color: AppTheme.textMid, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(child: _buildCategoryTabs(theme)),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildList(empP.employees.map((e) => _StaffItem(id: e.id, name: e.name, sub: e.designation, photo: e.photoUrl)).toList(), attMap, attP, theme),
            _buildList(intP.interns.map((i) => _StaffItem(id: i.id, name: i.name, sub: i.college, photo: i.photoUrl)).toList(), attMap, attP, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCalendar(ThemeData theme) {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1)),
              icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppTheme.primary),
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate), 
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark, fontSize: 16)
            ),
            IconButton(
              onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)),
              icon: const Icon(Icons.chevron_right_rounded, size: 28, color: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((d) => 
            Expanded(
              child: Center(
                child: Text(
                  d, 
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ).toList(),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, 
            mainAxisSpacing: 10, 
            crossAxisSpacing: 10,
            mainAxisExtent: 50,
          ),
          itemCount: daysInMonth + (firstDay - 1),
          itemBuilder: (context, index) {
            if (index < firstDay - 1) return const SizedBox();
            final day = index - (firstDay - 2);
            final date = DateTime(_selectedDate.year, _selectedDate.month, day);
            final isToday = DateUtils.isSameDay(date, DateTime.now());
            final isSelected = DateUtils.isSameDay(date, _selectedDate);

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedDate = date;
                  _isCalendarView = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : (isToday ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent),
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected ? null : Border.all(color: isToday ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day', 
                  style: TextStyle(
                    fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.bold,
                    color: isSelected ? Colors.white : (isToday ? AppTheme.primary : AppTheme.textDark),
                    fontSize: 15,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STAFF VIEW (CALENDAR) ---
  Widget _buildStaffView(AuthProvider auth) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final internProvider = context.watch<InternProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    
    if (employeeProvider.isLoading || internProvider.isLoading || attendanceProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
      );
    }

    final userEmail = auth.userEmail?.toLowerCase().trim();
    if (userEmail == null) return const _StaffCalendarView(staffId: 'anonymous');

    String? resolvedId;
    final empMatch = employeeProvider.employees.where((e) => e.email.toLowerCase().trim() == userEmail);
    if (empMatch.isNotEmpty) {
      resolvedId = empMatch.first.id;
    } else {
      final intMatch = internProvider.interns.where((i) => i.email.toLowerCase().trim() == userEmail);
      if (intMatch.isNotEmpty) {
        resolvedId = intMatch.first.id;
      }
    }

    final isSynchronized = resolvedId != null;
    
    return Column(
      children: [
        Expanded(child: _StaffCalendarView(staffId: resolvedId ?? 'anonymous')),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary, onPrimary: Colors.white, onSurface: AppTheme.textDark),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  Widget _buildCategoryTabs(ThemeData theme) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMid,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          tabs: const [Tab(text: 'EMPLOYEES'), Tab(text: 'INTERNS')],
        ),
      ),
    );
  }

  Widget _buildList(List<_StaffItem> items, Map<String, Attendance> records, AttendanceProvider provider, ThemeData theme) {
    if (items.isEmpty) return const EmptyStateWidget(title: 'No Personnel', message: 'The directory is empty.', icon: Icons.people_outline);
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final record = records[item.id] ?? Attendance(personId: item.id, date: _selectedDate, status: AttendanceStatus.absent);
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: FadeInAnimation(
              child: _StaffAttendanceCard(
                item: item,
                record: record,
                isSyncing: _syncingIds.contains(item.id),
                onStatusChange: (status) => _handleMarkAttendance(provider, Attendance(personId: item.id, date: _selectedDate, status: status)),
                theme: theme,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleMarkAttendance(AttendanceProvider provider, Attendance attendance) async {
    final id = attendance.personId;
    if (_syncingIds.contains(id)) return;

    final existingRecords = provider.getAttendanceForPerson(id);
    final hasRecord = existingRecords.any((r) => 
      r.date.year == attendance.date.year && 
      r.date.month == attendance.date.month && 
      r.date.day == attendance.date.day
    );

    if (hasRecord) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: BentoCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.history_rounded, color: AppTheme.warning, size: 36),
                ),
                const SizedBox(height: 24),
                const Text('Overwrite Record?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                const SizedBox(height: 12),
                Text(
                  'This user already has a record for this date. Change status to ${attendance.status.name.toUpperCase()}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _syncingIds.add(id));
    HapticFeedback.selectionClick();
    final result = await provider.markAttendance(attendance);
    if (mounted) {
      setState(() => _syncingIds.remove(id));
      if (result.isFailure) Globals.showSnackBar('Synchronization failed.', isError: true);
    }
  }

  Widget _buildLegend(ThemeData theme) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(label: 'PRESENT', color: AppTheme.success),
          _LegendItem(label: 'HALF-DAY', color: AppTheme.warning),
          _LegendItem(label: 'ABSENT', color: AppTheme.error),
        ],
      ),
    );
  }
}

class _StaffCalendarView extends StatefulWidget {
  final String staffId;
  const _StaffCalendarView({required this.staffId});

  @override
  State<_StaffCalendarView> createState() => _StaffCalendarViewState();
}

class _StaffCalendarViewState extends State<_StaffCalendarView> {
  DateTime _viewDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AttendanceProvider>();
    final myRecords = provider.getAttendanceForPerson(widget.staffId);
    
    final daysInMonth = DateUtils.getDaysInMonth(_viewDate.year, _viewDate.month);
    final firstDay = DateTime(_viewDate.year, _viewDate.month, 1).weekday;
    final monthName = DateFormat('MMMM yyyy').format(_viewDate);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textDark),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Presence', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text(monthName.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month - 1)),
                    icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(DateFormat('MMMM').format(_viewDate).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 12, letterSpacing: 1)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month + 1)),
                    icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              BentoCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Text(d, style: const TextStyle(fontSize: 10, color: AppTheme.textMid, fontWeight: FontWeight.w900))).toList()),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 12, crossAxisSpacing: 12),
                      itemCount: daysInMonth + (firstDay - 1),
                      itemBuilder: (context, index) {
                        if (index < firstDay - 1) return const SizedBox();
                        final day = index - (firstDay - 2);
                        final date = DateTime(_viewDate.year, _viewDate.month, day);
                        final record = myRecords.firstWhere(
                          (r) => r.date.year == date.year && r.date.month == date.month && r.date.day == date.day, 
                          orElse: () => Attendance(personId: '', date: date, status: AttendanceStatus.absent)
                        );
                        
                        return _buildCalendarDay(day, record, theme);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildLegend(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDay(int day, Attendance record, ThemeData theme) {
    Color color = Colors.transparent;
    Color textColor = AppTheme.textDark;
    bool hasRecord = record.personId.isNotEmpty;

    if (hasRecord) {
      color = record.status == AttendanceStatus.present ? AppTheme.success : (record.status == AttendanceStatus.halfDay ? AppTheme.warning : AppTheme.error.withValues(alpha: 0.1));
      textColor = record.status == AttendanceStatus.absent ? AppTheme.error : Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(14), 
        border: hasRecord ? null : Border.all(color: AppTheme.border.withValues(alpha: 0.5), width: 1.5),
        boxShadow: hasRecord && record.status != AttendanceStatus.absent ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
      ),
      alignment: Alignment.center,
      child: Text('$day', style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 14)),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(label: 'PRESENT', color: AppTheme.success),
          _LegendItem(label: 'HALF-DAY', color: AppTheme.warning),
          _LegendItem(label: 'ABSENT', color: AppTheme.error),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label; final Color color;
  const _LegendItem({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))])),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMid, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }
}

class _StaffAttendanceCard extends StatelessWidget {
  final _StaffItem item; final Attendance record; final bool isSyncing; final Function(AttendanceStatus) onStatusChange; final ThemeData theme;
  const _StaffAttendanceCard({required this.item, required this.record, required this.isSyncing, required this.onStatusChange, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BentoCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            PremiumImage(imageUrl: ApiConfig.getFullImageUrl(item.photo), size: 56, isCircle: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(item.sub, style: const TextStyle(color: AppTheme.textMid, fontSize: 11, fontWeight: FontWeight.bold)),
                ]
              ),
            ),
            const SizedBox(width: 12),
            _StatusSelector(current: record.status, onSelect: onStatusChange, isSyncing: isSyncing),
          ],
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final AttendanceStatus current; final Function(AttendanceStatus) onSelect; final bool isSyncing;
  const _StatusSelector({required this.current, required this.onSelect, required this.isSyncing});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _StatusButton(label: 'P', isSelected: current == AttendanceStatus.present, color: AppTheme.success, onTap: () => onSelect(AttendanceStatus.present)),
          const SizedBox(width: 4),
          _StatusButton(label: 'H', isSelected: current == AttendanceStatus.halfDay, color: AppTheme.warning, onTap: () => onSelect(AttendanceStatus.halfDay)),
          const SizedBox(width: 4),
          _StatusButton(label: 'A', isSelected: current == AttendanceStatus.absent, color: AppTheme.error, onTap: () => onSelect(AttendanceStatus.absent)),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label; final bool isSelected; final Color color; final VoidCallback onTap;
  const _StatusButton({required this.label, required this.isSelected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent, 
          borderRadius: BorderRadius.circular(12), 
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : AppTheme.textMid)),
      ),
    );
  }
}

class _StaffItem {
  final String id; final String name; final String sub; final String? photo;
  _StaffItem({required this.id, required this.name, required this.sub, this.photo});
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate({required this.child});
  @override double get minExtent => 84;
  @override double get maxExtent => 84;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}

