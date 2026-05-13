import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    return auth.isAdmin ? _buildAdminView() : _buildStaffView(auth);
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedSwitcher(
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
      ),
    );
  }

  Widget _buildCalendarHub(ThemeData theme, AttendanceProvider provider) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 150, // Increased height for premium feel
        title:  const Text('Attendance Hub', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            icon: const Icon(Icons.today_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [  
            const SizedBox(height: 16),
           
            const SizedBox(height: 18 ),
            BentoCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40), // More vertical padding for expansion
              child: _buildAdminCalendar(theme),
            ),
            const SizedBox(height: 40),
            _buildLegend(theme),
          ],
        ),
      ),
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
            toolbarHeight: 80, // Increased for modern elite feel
            backgroundColor: AppTheme.background.withValues(alpha: 0.7),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(_selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      'Management Registry',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textLight, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _isCalendarView = true),
                icon: const Icon(Icons.close_rounded, size: 22),
              ),
              const SizedBox(width: 8),
            ],
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
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate), 
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary)
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1)),
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1)),
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Weekday headers - Responsive Flex
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => 
            Expanded(
              child: Center(
                child: Text(
                  d, 
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textLight, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, 
            mainAxisSpacing: 8, 
            crossAxisSpacing: 8,
            mainAxisExtent: 44, // Compact height
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
                HapticFeedback.mediumImpact();
                setState(() {
                  _selectedDate = date;
                  _isCalendarView = false;
                });
              },
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : (isToday ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2) : Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                    boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day', 
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected || isToday ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected ? Colors.white : (isToday ? AppTheme.primary : AppTheme.textDark),
                      fontSize: 14,
                    ),
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
    
    // Show premium loading if directory is warming up
    if (employeeProvider.isLoading || internProvider.isLoading || attendanceProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Synchronizing Identity...', style: TextStyle(color: AppTheme.textLight, fontSize: 12, letterSpacing: 0.5)),
            ],
          ),
        ),
      );
    }

    final userEmail = auth.userEmail?.toLowerCase().trim();
    
    // Find the actual record ID (UUID) for this user
    String? staffId;
    try {
      if (userEmail != null) {
        if (auth.role == UserRole.employee) {
          staffId = employeeProvider.employees.firstWhere((e) => e.email.toLowerCase().trim() == userEmail).id;
        } else if (auth.role == UserRole.intern) {
          staffId = internProvider.interns.firstWhere((i) => i.email.toLowerCase().trim() == userEmail).id;
        }
      }
    } catch (_) {
      staffId = null;
    }

    return _StaffCalendarView(staffId: staffId ?? 'anonymous');
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
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(height: 68),
      child: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Container(
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0),
            tabs: const [Tab(text: 'Staff Members'), Tab(text: 'Interns')],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<_StaffItem> items, Map<String, Attendance> records, AttendanceProvider provider, ThemeData theme) {
    if (items.isEmpty) return const EmptyStateWidget(title: 'No Staff', message: 'No records found.', icon: Icons.people_outline);
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final record = records[item.id] ?? Attendance(personId: item.id, date: _selectedDate, status: AttendanceStatus.absent);
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 100),
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

    // Check if record already exists to show confirmation
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Update Attendance?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Text(
                  'This person already has an attendance record for this day. Are you sure you want to change it to ${attendance.status.name}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMid, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CONFIRM'),
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
      if (result.isFailure) Globals.showSnackBar('Sync failed. Please try again.', isError: true);
    }
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(label: 'Present', color: const Color.fromARGB(255, 99, 241, 156)),
        const SizedBox(width: 16),
        _LegendItem(label: 'Half-Day', color: AppTheme.warning),
        const SizedBox(width: 16),
        _LegendItem(label: 'Absent', color: AppTheme.error),
      ],
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
        title: Text('My Attendance', style: theme.appBarTheme.titleTextStyle),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCalendarHeader(monthName, theme),
            const SizedBox(height: 24),
            BentoCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildWeekdayRow(theme),
                  const Divider(height: 32),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemCount: daysInMonth + (firstDay - 1),
                    itemBuilder: (context, index) {
                      if (index < firstDay - 1) return const SizedBox();
                      final day = index - (firstDay - 2);
                      final date = DateTime(_viewDate.year, _viewDate.month, day);
                      final record = myRecords.firstWhere(
                        (r) => DateUtils.isSameDay(r.date.toLocal(), date), 
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
    );
  }

  Widget _buildCalendarHeader(String month, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(month.toUpperCase(), style: theme.textTheme.labelLarge),
        Row(
          children: [
            IconButton(onPressed: () => setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month - 1)), icon: const Icon(Icons.chevron_left_rounded)),
            IconButton(onPressed: () => setState(() => _viewDate = DateTime(_viewDate.year, _viewDate.month + 1)), icon: const Icon(Icons.chevron_right_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayRow(ThemeData theme) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: days.map((d) => Text(d, style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, color: AppTheme.textLight))).toList());
  }

  Widget _buildCalendarDay(int day, Attendance record, ThemeData theme) {
    Color color = Colors.transparent;
    Color textColor = AppTheme.textDark;
    bool hasRecord = record.personId.isNotEmpty;

    if (hasRecord) {
      color = record.status == AttendanceStatus.present ? AppTheme.success : (record.status == AttendanceStatus.halfDay ? AppTheme.warning : AppTheme.error.withValues(alpha: 0.1));
      textColor = record.status == AttendanceStatus.absent ? AppTheme.error : Colors.white;
    }

    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: hasRecord ? null : Border.all(color: AppTheme.border.withValues(alpha: 0.5))),
      alignment: Alignment.center,
      child: Text('$day', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(label: 'Present', color: AppTheme.success),
        const SizedBox(width: 16),
        _LegendItem(label: 'Half-Day', color: AppTheme.warning),
        const SizedBox(width: 16),
        _LegendItem(label: 'Absent', color: AppTheme.error),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label; final Color color;
  const _LegendItem({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMid, fontWeight: FontWeight.bold))]);
  }
}

class _StaffAttendanceCard extends StatelessWidget {
  final _StaffItem item; final Attendance record; final bool isSyncing; final Function(AttendanceStatus) onStatusChange; final ThemeData theme;
  const _StaffAttendanceCard({required this.item, required this.record, required this.isSyncing, required this.onStatusChange, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            PremiumImage(imageUrl: ApiConfig.getFullImageUrl(item.photo), size: 54, isCircle: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), Text(item.sub, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight))]),
            ),
            const SizedBox(width: 8),
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
      decoration: BoxDecoration(color: AppTheme.primarySubtle, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _StatusButton(label: 'P', isSelected: current == AttendanceStatus.present, color: AppTheme.success, onTap: () => onSelect(AttendanceStatus.present)),
          _StatusButton(label: 'H', isSelected: current == AttendanceStatus.halfDay, color: AppTheme.warning, onTap: () => onSelect(AttendanceStatus.halfDay)),
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
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: isSelected ? color : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : AppTheme.textLight.withValues(alpha: 0.5))),
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
  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}

