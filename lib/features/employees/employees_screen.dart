import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/providers/employee_provider.dart';
import '../../core/models/employee.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

enum EmployeeSortType { name, designation, salary, date }

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  EmployeeSortType _sortType = EmployeeSortType.date;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EmployeeProvider>().fetchEmployees();
      }
    });
    debugPrint('👥 [INIT] EmployeesScreen');
  }

  @override
  void dispose() {
    debugPrint('👥 [DISPOSE] EmployeesScreen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('👥 [BUILD] EmployeesScreen');
    final theme = Theme.of(context);
    final provider = context.watch<EmployeeProvider>();
    final allEmployees = provider.employees;

    // Efficiently extract departments only if needed
    final Set<String> deptSet = {'All'};
    for (var e in allEmployees) {
      if (e.department.isNotEmpty) deptSet.add(e.department);
    }
    final departments = deptSet.toList();

    // Combined Filter & Sort logic
    final filteredEmployees = allEmployees.where((emp) {
      final matchesSearch = _searchQuery.isEmpty ||
          emp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.designation.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept =
          _selectedDepartment == 'All' || emp.department == _selectedDepartment;
      return matchesSearch && matchesDept;
    }).toList();

    if (filteredEmployees.length > 1) {
      filteredEmployees.sort((a, b) {
        int comparison = 0;
        switch (_sortType) {
          case EmployeeSortType.name:
            comparison = a.name.compareTo(b.name);
            break;
          case EmployeeSortType.designation:
            comparison = a.designation.compareTo(b.designation);
            break;
          case EmployeeSortType.salary:
            comparison = a.salary.compareTo(b.salary);
            break;
          case EmployeeSortType.date:
            comparison = a.joiningDate.compareTo(b.joiningDate);
            break;
        }  
        return _isAscending ? comparison : -comparison;
      });
    }

    return Scaffold(
        backgroundColor: AppTheme.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              centerTitle: false,
              expandedHeight: 80,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.background.withValues(alpha: 0.8),
              elevation: 0,
              actions: [
                IconButton(
                  onPressed: _showSortDialog,
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: const FlexibleSpaceBar(
                stretchModes: [StretchMode.zoomBackground],
                titlePadding:
                    EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                centerTitle: true,
                title: Text(
                  'Staff Directory',style: TextStyle(fontSize: 20)
                 
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverSearchDelegate(
                child: Container(
                  color: AppTheme.background,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Search staff...',
                          prefixIcon: Icon(Icons.search_rounded),
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ).applyDefaults(theme.inputDecorationTheme),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: departments
                              .map((dept) => _buildDeptChip(dept, theme))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: provider.isLoading
              ? const SkeletonList()
              : RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.mediumImpact();
                    await provider.fetchEmployees();
                  },
                  color: AppTheme.accent,
                  child: filteredEmployees.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Staff Found',
                          message: 'Try a different search or department.',
                          icon: Icons.people_outline_rounded,
                          onAction: () => context.push('/employees/add'),
                          actionLabel: 'Add Staff',
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 600),
                                child: SlideAnimation(
                                  verticalOffset: 30.0,
                                  child: FadeInAnimation(
                                    child: _buildEmployeeCard(context,
                                        filteredEmployees[index], theme),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/employees/add'),
          backgroundColor: AppTheme.primary,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      );
  }

  Widget _buildDeptChip(String dept, ThemeData theme) {
    final isSelected = _selectedDepartment == dept;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDepartment = dept);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Text(
          dept,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textMid,
            fontWeight: FontWeight.bold,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(
      BuildContext context, Employee emp, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(emp.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (context) => _showDeleteDialog(context, emp),
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.error,
              icon: Icons.delete_outline_rounded,
            ),
          ],
        ),
        child: BentoCard(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/employees/detail', extra: emp.id);
          },
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'emp_${emp.id}',
                child: PremiumImage(
                  imageUrl: ApiConfig.getFullImageUrl(emp.photoUrl),
                  size: 60,
                  isCircle: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      emp.designation,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        emp.department.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 9,
                          color: AppTheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textLight.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort Staff By', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            _buildSortOption('Name', EmployeeSortType.name, theme),
            _buildSortOption('Designation', EmployeeSortType.designation, theme),
            _buildSortOption('Salary', EmployeeSortType.salary, theme),
            _buildSortOption('Joining Date', EmployeeSortType.date, theme),
            const Divider(height: 40, color: AppTheme.divider),
            SwitchListTile(
              title: Text('Ascending Order', style: theme.textTheme.titleSmall),
              activeThumbColor: AppTheme.accent,
              value: _isAscending,
              onChanged: (v) {
                setState(() => _isAscending = v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
      String label, EmployeeSortType type, ThemeData theme) {
    final isSelected = _sortType == type;
    return ListTile(
      onTap: () {
        setState(() => _sortType = type);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: isSelected ? AppTheme.accent : AppTheme.textLight,
      ),
      title: Text(label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.textDark : AppTheme.textMid,
          )),
    );
  }

  void _showDeleteDialog(BuildContext context, Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Remove Staff?',
        message:
            'Are you sure you want to remove ${employee.name} from the directory? This action cannot be undone.',
        confirmLabel: 'Remove',
        confirmColor: AppTheme.error,
        icon: Icons.delete_forever_rounded,
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<EmployeeProvider>().deleteEmployee(employee.id);
    }
  }
}

class _SliverSearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverSearchDelegate({required this.child});

  @override
  double get minExtent => 122;
  @override
  double get maxExtent => 122;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverSearchDelegate oldDelegate) => true;
}
