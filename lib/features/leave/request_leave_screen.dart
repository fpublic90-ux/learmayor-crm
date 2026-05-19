import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/globals.dart';
import '../../app/theme.dart';
import '../../core/models/leave_request.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/widgets/premium_widgets.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() =>
      _RequestLeaveScreenState();
}

class _RequestLeaveScreenState
    extends State<RequestLeaveScreen> {
  final _reasonController = TextEditingController();

  Set<DateTime> _selectedDates = {};

  DateTime _viewDate = DateTime.now();

  LeaveType _selectedType = LeaveType.fullDay;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedDates.isEmpty) {
      Globals.showPremiumError(
        'Please select at least one date',
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    final provider =
        context.read<LeaveProvider>();

    final sortedDates =
        _selectedDates.toList()..sort();

    List<DateTimeRange> ranges = [];

    DateTime? rangeStart;
    DateTime? rangeEnd;

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];

      if (rangeStart == null) {
        rangeStart = date;
        rangeEnd = date;
      } else {
        if (date
                .difference(rangeEnd!)
                .inDays ==
            1) {
          rangeEnd = date;
        } else {
          ranges.add(
            DateTimeRange(
              start: rangeStart,
              end: rangeEnd!,
            ),
          );

          rangeStart = date;
          rangeEnd = date;
        }
      }
    }

    if (rangeStart != null &&
        rangeEnd != null) {
      ranges.add(
        DateTimeRange(
          start: rangeStart,
          end: rangeEnd,
        ),
      );
    }

    bool hasOverlap = false;

    for (final range in ranges) {
      hasOverlap = provider.leaveRequests.any(
        (r) {
          if (r.status ==
              LeaveStatus.rejected) {
            return false;
          }

          return (r.startDate.isBefore(
                      range.end) ||
                  r.startDate
                      .isAtSameMomentAs(
                          range.end)) &&
              (r.endDate.isAfter(
                      range.start) ||
                  r.endDate
                      .isAtSameMomentAs(
                          range.start));
        },
      );

      if (hasOverlap) break;
    }

    if (hasOverlap) {
      Globals.showPremiumError(
        'You already have leave requests for these dates',
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    bool allSuccess = true;

    for (final range in ranges) {
      final request = LeaveRequest(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(),

        staffId:
            auth.userEmail ?? 'anonymous',

        staffName:
            auth.userName ?? 'Staff',

        startDate: range.start,

        endDate: range.end,

        reason:
            _reasonController.text.trim(),

        type: _selectedType,
      );

      final result =
          await provider.submitLeaveRequest(
        request,
      );

      if (result.isFailure) {
        allSuccess = false;
      }
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (allSuccess) {
      Globals.showPremiumSuccess(
        'Leave request submitted successfully',
      );

      _reasonController.clear();

      setState(() {
        _selectedDates.clear();
      });
    } else {
      Globals.showPremiumError(
        'Some requests failed to submit',
      );
    }
  }

  Future<void> _handleCancel(
    LeaveRequest request,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (_) =>
          const PremiumConfirmationDialog(
        title: 'Cancel Leave Request?',
        message:
            'Are you sure you want to cancel this leave request?',
        confirmLabel: 'Cancel Request',
        confirmColor: AppTheme.error,
        icon: Icons.cancel_rounded,
      ),
    );

    if (confirmed == true && mounted) {
      final result = await context
          .read<LeaveProvider>()
          .cancelLeaveRequest(
            request.id,
          );

      result.when(
        onSuccess: (_) {
          Globals.showPremiumSuccess(
            'Leave request cancelled',
          );
        },

        onFailure: (e) {
          Globals.showPremiumError(
            e.toString(),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<LeaveProvider>();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          AppTheme.background,

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerFloat,

      floatingActionButton: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),

          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                22,
              ),

              gradient:
                  LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.accent,
                ],
              ),

              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset:
                      const Offset(0, 12),

                  color: AppTheme.primary
                      .withOpacity(0.3),
                ),
              ],
            ),

            child: PremiumButton(
              label: 'SUBMIT REQUEST',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ),
        ),
      ),

      body: CustomScrollView(
        physics:
            const BouncingScrollPhysics(),

        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            stretch: true,

            expandedHeight: 130,

            elevation: 0,

            backgroundColor:
                AppTheme.background
                    .withOpacity(0.94),

            leading: IconButton(
              onPressed: () {
                context.pop();
              },

              icon: Container(
                padding:
                    const EdgeInsets.all(
                  10,
                ),

                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: const Icon(
                  Icons
                      .arrow_back_ios_new_rounded,
                  size: 18,
                ),
              ),
            ),

            flexibleSpace:
                FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.fromLTRB(
                24,
                0,
                24,
                18,
              ),

              title: Column(
                mainAxisSize:
                    MainAxisSize.min,

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    'Request Leave',

                    style: theme
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(
                      height: 2),

                  Text(
                    '${provider.leaveRequests.length} requests',

                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                          AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              14,
              24,
              120,
            ),

            sliver: SliverList(
              delegate:
                  SliverChildListDelegate([
                _buildStats(),

                const SizedBox(
                    height: 30),

                _buildSectionTitle(
                  'SELECT DATES',
                ),

                const SizedBox(
                    height: 14),

                BentoCard(
                  borderRadius: 30,
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),

                  child:
                      _buildCalendar(theme),
                ),

                const SizedBox(
                    height: 32),

                _buildSectionTitle(
                  'LEAVE TYPE',
                ),

                const SizedBox(
                    height: 14),

                Row(
                  children: [
                    _buildTypeChip(
                      'Full Day',
                      LeaveType.fullDay,
                      Icons
                          .wb_sunny_rounded,
                    ),

                    const SizedBox(
                        width: 14),

                    _buildTypeChip(
                      'Half Day',
                      LeaveType.halfDay,
                      Icons
                          .timelapse_rounded,
                    ),
                  ],
                ),

                const SizedBox(
                    height: 32),

                _buildSectionTitle(
                  'REASON',
                ),

                const SizedBox(
                    height: 14),

                BentoCard(
                  borderRadius: 28,
                  padding:
                      EdgeInsets.zero,

                  child: TextField(
                    controller:
                        _reasonController,

                    maxLines: 5,

                    decoration:
                        InputDecoration(
                      border:
                          InputBorder.none,

                      contentPadding:
                          const EdgeInsets
                              .all(22),

                      hintText:
                          'Describe your reason for leave...',
                    ),
                  ),
                ),

                const SizedBox(
                    height: 40),

             

                const SizedBox(
                    height: 18),

                
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Selected',
            '${_selectedDates.length}',
            Icons.calendar_month_rounded,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _buildStatCard(
            'Type',
            _selectedType ==
                    LeaveType.fullDay
                ? 'Full Day'
                : 'Half Day',
            Icons.badge_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
  ) {
    return BentoCard(
      borderRadius: 28,

      padding:
          const EdgeInsets.all(18),

      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,

            decoration: BoxDecoration(
              gradient:
                  LinearGradient(
                colors: [
                  AppTheme.primary
                      .withOpacity(0.12),

                  AppTheme.accent
                      .withOpacity(0.08),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),

            child: Icon(
              icon,
              color: AppTheme.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                    height: 2),

                Text(
                  title,

                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        AppTheme.textLight,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Row(
      children: [
        Container(
          height: 8,
          width: 8,

          decoration:
              BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),

        SizedBox(width: 10),

        Text(
          title,

          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w900,
            color: AppTheme.textMid,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    String label,
    LeaveType type,
    IconData icon,
  ) {
    final isSelected =
        _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback
              .selectionClick();

          setState(() {
            _selectedType = type;
          });
        },

        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 250,
          ),

          padding:
              EdgeInsets.symmetric(
            vertical: 18,
          ),

          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.accent,
                    ],
                  )
                : null,

            color: isSelected
                ? null
                : AppTheme.surface,

            borderRadius:
                BorderRadius.circular(
              22,
            ),

            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.border,
            ),

            boxShadow: isSelected
                ? [
                    BoxShadow(
                      blurRadius: 20,
                      offset:
                          const Offset(
                        0,
                        8,
                      ),

                      color: AppTheme
                          .primary
                          .withOpacity(
                        0.25,
                      ),
                    )
                  ]
                : [],
          ),

          child: Column(
            children: [
              Icon(
                icon,

                color: isSelected
                    ? Colors.white
                    : AppTheme.primary,
              ),

              const SizedBox(
                  height: 10),

              Text(
                label,

                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,

                  color: isSelected
                      ? Colors.white
                      : AppTheme
                          .textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    LeaveProvider provider,
  ) {
    final myLeaves =
        provider.leaveRequests;

    if (myLeaves.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Requests Found',
        message:
            'Your leave request history will appear here.',
        icon: Icons.event_busy_rounded,
      );
    }

    return ListView.separated(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount: myLeaves.length,

      separatorBuilder: (_, __) =>
          const SizedBox(height: 14),

      itemBuilder: (_, index) {
        return _buildRequestCard(
          myLeaves[index],
        );
      },
    );
  }

  Widget _buildRequestCard(
    LeaveRequest request,
  ) {
    final isPending =
        request.status ==
            LeaveStatus.pending;

    final isApproved =
        request.status ==
            LeaveStatus.approved;

    final statusColor = isApproved
        ? AppTheme.success
        : isPending
            ? AppTheme.warning
            : AppTheme.error;

    return BentoCard(
      borderRadius: 30,

      padding:
          const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      '${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd').format(request.endDate)}',

                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),

                    const SizedBox(
                        height: 8),

                    Row(
                      children: [
                        StatusBadge(
                          label: request
                              .status.name,

                          color:
                              statusColor,
                        ),

                        const SizedBox(
                            width: 10),

                        Text(
                          '${request.durationInDays} days',

                          style:
                              TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w600,

                            color: AppTheme
                                .textMid,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isPending)
                IconButton(
                  onPressed: () =>
                      _handleCancel(
                    request,
                  ),

                  style:
                      IconButton.styleFrom(
                    backgroundColor:
                        AppTheme.error
                            .withOpacity(
                      0.08,
                    ),
                  ),

                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.error,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(
              16,
            ),

            decoration: BoxDecoration(
              color:
                  AppTheme.background,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: Text(
              request.reason.isEmpty
                  ? 'No reason provided'
                  : request.reason,

              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                fontWeight:
                    FontWeight.w500,
                color: AppTheme.textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    ThemeData theme,
  ) {
    final daysInMonth =
        DateUtils.getDaysInMonth(
      _viewDate.year,
      _viewDate.month,
    );

    final firstDay =
        DateTime(
          _viewDate.year,
          _viewDate.month,
          1,
        ).weekday;

    final today = DateTime.now();

    final normalizedToday =
        DateTime(
      today.year,
      today.month,
      today.day,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,

          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _viewDate = DateTime(
                    _viewDate.year,
                    _viewDate.month - 1,
                    1,
                  );
                });
              },

              icon: Icon(
                Icons
                    .chevron_left_rounded,
                color: AppTheme.primary,
              ),
            ),

            Text(
              DateFormat(
                'MMMM yyyy',
              ).format(_viewDate),

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w900,
                fontSize: 16,
              ),
            ),

            IconButton(
              onPressed: () {
                setState(() {
                  _viewDate = DateTime(
                    _viewDate.year,
                    _viewDate.month + 1,
                    1,
                  );
                });
              },

              icon: Icon(
                Icons
                    .chevron_right_rounded,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceAround,

          children: [
            'M',
            'T',
            'W',
            'T',
            'F',
            'S',
            'S'
          ]
              .map(
                (e) => Text(
                  e,

                  style:
                      TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppTheme.textMid,
                  ),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          itemCount:
              daysInMonth +
                  (firstDay - 1),

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),

          itemBuilder:
              (context, index) {
            if (index <
                firstDay - 1) {
              return const SizedBox();
            }

            final day =
                index -
                    (firstDay - 2);

            final date = DateTime(
              _viewDate.year,
              _viewDate.month,
              day,
            );

            final normalized =
                DateTime(
              date.year,
              date.month,
              date.day,
            );

            final isBeforeToday =
                normalized.isBefore(
              normalizedToday,
            );
            
            final provider = context.watch<LeaveProvider>();
            final isAlreadyRequested = provider.leaveRequests.any((r) {
              if (r.status == LeaveStatus.rejected) return false;
              final reqStart = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
              final reqEnd = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
              return (normalized.isAfter(reqStart) || normalized.isAtSameMomentAs(reqStart)) &&
                     (normalized.isBefore(reqEnd) || normalized.isAtSameMomentAs(reqEnd));
            });

            final isDisabled = isBeforeToday || isAlreadyRequested;

            final isSelected =
                _selectedDates.any(
              (d) =>
                  d.year ==
                      normalized.year &&
                  d.month ==
                      normalized.month &&
                  d.day ==
                      normalized.day,
            );

            final isToday =
                normalized ==
                    normalizedToday;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      HapticFeedback
                          .lightImpact();

                      setState(() {
                        if (isSelected) {
                          _selectedDates
                              .removeWhere(
                            (d) =>
                                d.year ==
                                    normalized
                                        .year &&
                                d.month ==
                                    normalized
                                        .month &&
                                d.day ==
                                    normalized
                                        .day,
                          );
                        } else {
                          _selectedDates
                              .add(
                            normalized,
                          );
                        }
                      });
                    },

              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 220,
                ),

                alignment:
                    Alignment.center,

                decoration:
                    BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppTheme
                                .primary,
                            AppTheme
                                .accent,
                          ],
                        )
                      : null,

                  color: isSelected
                      ? null
                      : isToday
                          ? AppTheme
                              .primary
                              .withOpacity(
                              0.08,
                            )
                          : AppTheme
                              .surface,

                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),

                  border: Border.all(
                    color: isToday
                        ? AppTheme
                            .primary
                        : isAlreadyRequested
                            ? AppTheme.error.withValues(alpha: 0.3)
                            : AppTheme
                                .border,
                  ),

                  boxShadow:
                      isSelected
                          ? [
                              BoxShadow(
                                blurRadius:
                                    18,

                                offset:
                                    const Offset(
                                  0,
                                  8   ,
                                ),

                                color:
                                    AppTheme
                                        .primary
                                        .withOpacity(
                                  0.25,
                                ),
                              ),
                            ]
                          : [],
                ),

                child: Text(
                  '$day',

                  style: TextStyle(
                    fontWeight:
                        FontWeight
                            .w800,

                    color:
                        isDisabled
                            ? AppTheme
                                .textLight
                                .withValues(
                                alpha: 0.4,
                              )
                            : isSelected
                                ? Colors
                                    .white
                                : isToday
                                    ? AppTheme
                                        .primary
                                    : AppTheme
                                        .textDark,
                  ),
                ),
              ),
            );
          },
        ),

        if (_selectedDates
            .isNotEmpty) ...[
          const SizedBox(height: 20),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),

            decoration: BoxDecoration(
              color: AppTheme.primary
                  .withOpacity(0.08),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),

            child: Text(
              '${_selectedDates.length} day(s) selected',

              style: TextStyle(
                color: AppTheme.primary,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}