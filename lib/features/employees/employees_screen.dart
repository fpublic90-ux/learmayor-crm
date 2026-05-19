import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/providers/employee_provider.dart';
import '../../core/models/employee.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';

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
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EmployeeProvider>().fetchEmployees().then((_) {
          if (mounted) setState(() => _isInitialLoad = false);
        });
      }
    });
    debugPrint('👥 [INIT] EmployeesScreen');
  }

  @override
  void dispose() {
    debugPrint('👥 [DISPOSE] EmployeesScreen');
    super.dispose();
  }

  List<String> _extractDepartments(List<Employee> employees) {
    final Set<String> deptSet = {'All'};
    for (var e in employees) {
      if (e.department.isNotEmpty) {
        deptSet.add(e.department);
      }
    }
    return deptSet.toList();
  }

  List<Employee> _getProcessedEmployees(List<Employee> allEmployees) {
    final filtered = allEmployees.where((emp) {
      final matchesSearch = _searchQuery.isEmpty ||
          emp.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.designation.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept =
          _selectedDepartment == 'All' || emp.department == _selectedDepartment;
      return matchesSearch && matchesDept;
    }).toList();

    if (filtered.length > 1) {
      filtered.sort((a, b) {
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
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('👥 [BUILD] EmployeesScreen');
    final theme = Theme.of(context);
    final provider = context.watch<EmployeeProvider>();
    
    final departments = _extractDepartments(provider.employees);
    final filteredEmployees = _getProcessedEmployees(provider.employees);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            centerTitle: true,
            expandedHeight: 100,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.background.withValues(alpha: 0.85),
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _showSortDialog,
                icon: Icon(Icons.tune_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: true,
              title: Text(
                'Staff Directory',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search staff by name or role...',
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ).applyDefaults(theme.inputDecorationTheme),
                    ),
                    const SizedBox(height: 12),
                    // Dropdown widget implementation matching layout configurations
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDepartment,
                      dropdownColor: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(Icons.expand_more_rounded, color: AppTheme.primary),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.filter_list_rounded),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ).applyDefaults(theme.inputDecorationTheme),
                      items: departments.map((String dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedDepartment = v);
                        }
                      },
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
                        message: 'Try modifying your search constraints or filter.',
                        icon: Icons.people_outline_rounded,
                        onAction: () => context.push('/employees/add'),
                        actionLabel: 'Add Staff',
                      )
                    : (_isInitialLoad
                        ? AnimationLimiter(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredEmployees.length,
                              itemBuilder: (context, index) {
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 500),
                                  child: SlideAnimation(
                                    verticalOffset: 40.0,
                                    child: FadeInAnimation(
                                      child: _buildEmployeeCard(
                                        context,
                                        filteredEmployees[index],
                                        theme,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredEmployees.length,
                            itemBuilder: (context, index) {
                              return _buildEmployeeCard(
                                context,
                                filteredEmployees[index],
                                theme,
                              );
                            },
                          )),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/employees/add'),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Employee emp, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(emp.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => _showDeleteDialog(context, emp),
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.error,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      emp.designation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        emp.department.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 9,
                          color: AppTheme.accent,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textLight.withValues(alpha: 0.5),
              ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort Staff By', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 24),
                _buildSortOption('Name', EmployeeSortType.name, theme, setModalState),
                _buildSortOption('Designation', EmployeeSortType.designation, theme, setModalState),
                _buildSortOption('Salary', EmployeeSortType.salary, theme, setModalState),
                _buildSortOption('Joining Date', EmployeeSortType.date, theme, setModalState),
                Divider(height: 40, color: AppTheme.divider),
                SwitchListTile(
                  title: Text('Ascending Order', style: theme.textTheme.titleSmall),
                  activeThumbColor: AppTheme.accent,
                  value: _isAscending,
                  onChanged: (v) {
                    setModalState(() => _isAscending = v);
                    setState(() => _isAscending = v);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortOption(
    String label,
    EmployeeSortType type,
    ThemeData theme,
    StateSetter setModalState,
  ) {
    final isSelected = _sortType == type;
    return ListTile(
      onTap: () {
        setModalState(() => _sortType = type);
        setState(() => _sortType = type);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: isSelected ? AppTheme.accent : AppTheme.textLight,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.textDark : AppTheme.textMid,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Remove Staff?',
        message: 'Are you sure you want to remove ${employee.name} from the directory? This action cannot be undone.',
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

  // Balanced bounding extents to account for the single-line DropdownFormField geometry heights.
  @override
  double get minExtent => 132.0;
  @override
  double get maxExtent => 132.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverSearchDelegate oldDelegate) => true;
}
