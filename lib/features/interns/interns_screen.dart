import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../app/theme.dart';
import '../../core/providers/intern_provider.dart';
import '../../core/models/intern.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/config/api_config.dart';

enum InternSortType { name, date, stipend }

class InternsScreen extends StatefulWidget {
  const InternsScreen({super.key});

  @override
  State<InternsScreen> createState() => _InternsScreenState();
}

class _InternsScreenState extends State<InternsScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  InternSortType _sortType = InternSortType.date;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InternProvider>().fetchInterns();
      }
    });
    debugPrint('🎓 [INIT] InternsScreen');
  }

  @override
  void dispose() {
    debugPrint('🎓 [DISPOSE] InternsScreen');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { 
    debugPrint('🎓 [BUILD] InternsScreen');
    final theme = Theme.of(context);
    final provider = context.watch<InternProvider>();
    final allInterns = provider.interns;

    // Efficiently extract departments only if needed
    final Set<String> deptSet = {'All'};
    for (var i in allInterns) {
      if (i.department.isNotEmpty) deptSet.add(i.department);
    }
    final departments = deptSet.toList();

    // Combined Filter & Sort logic
    final filteredInterns = allInterns.where((intern) {
      final matchesSearch = _searchQuery.isEmpty ||
          intern.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          intern.college.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept = _selectedDepartment == 'All' ||
          intern.department == _selectedDepartment;
      return matchesSearch && matchesDept;
    }).toList();

    if (filteredInterns.length > 1) {
      filteredInterns.sort((a, b) {
        int comparison = 0;
        switch (_sortType) {
          case InternSortType.name:
            comparison = a.name.compareTo(b.name);
            break;
          case InternSortType.date:
            comparison = a.startDate.compareTo(b.startDate);
            break;
          case InternSortType.stipend:
            comparison = a.stipend.compareTo(b.stipend);
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
              expandedHeight: 70,
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
                  'Intern Directory',style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)  ,
                 
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
                          hintText: 'Search interns...',
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
                    await provider.fetchInterns();
                  },
                  color: AppTheme.accent,
                  child: filteredInterns.isEmpty
                      ? EmptyStateWidget(
                          title: 'No Interns Found',
                          message: 'Try a different search or department.',
                          icon: Icons.school_outlined,
                          onAction: () => context.push('/interns/add'),
                          actionLabel: 'Add Intern',
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredInterns.length,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 600),
                                child: SlideAnimation(
                                  verticalOffset: 30.0,
                                  child: FadeInAnimation(
                                    child: _InternCard(
                                        intern: filteredInterns[index],
                                        theme: theme),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/interns/add'),
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
            Text('Sort Interns By', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),
            _buildSortOption('Name', InternSortType.name, theme),
            _buildSortOption('Joining Date', InternSortType.date, theme),
            _buildSortOption('Stipend', InternSortType.stipend, theme),
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

  Widget _buildSortOption(String label, InternSortType type, ThemeData theme) {
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
}

class _InternCard extends StatelessWidget {
  final Intern intern;
  final ThemeData theme;
  const _InternCard({required this.intern, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(intern.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.2,
          children: [
            SlidableAction(
              onPressed: (_) => _showDeleteDialog(context, intern),
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.error,
              icon: Icons.delete_outline_rounded,
            ),
          ],
        ),
        child: BentoCard(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/interns/detail', extra: intern.id);
          },
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'intern_${intern.id}',
                child: PremiumImage(
                  imageUrl: ApiConfig.getFullImageUrl(intern.photoUrl),
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
                      intern.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      intern.college,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        intern.department.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 9,
                          color: AppTheme.accent,
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
}
  void _showDeleteDialog(BuildContext context, Intern intern) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Remove Intern?',
        message:
            'Are you sure you want to remove ${intern.name} from the program?',
        confirmLabel: 'Remove',
        confirmColor: AppTheme.error,
        icon: Icons.person_remove_rounded,
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<InternProvider>().deleteIntern(intern.id);
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
