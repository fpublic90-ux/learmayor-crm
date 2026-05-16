import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/globals.dart';
import '../../core/models/leave_request.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/leave_provider.dart';
import '../../core/widgets/premium_widgets.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _reasonController = TextEditingController();
  DateTimeRange? _selectedRange;
  LeaveType _selectedType = LeaveType.fullDay;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 90)),
      initialDateRange: _selectedRange ?? DateTimeRange(start: tomorrow, end: tomorrow),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            onSurface: AppTheme.textDark,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedRange == null) {
      Globals.showSnackBar('Please select dates', isError: true);
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      Globals.showSnackBar('Please provide a reason', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    
    final auth = context.read<AuthProvider>();
    final provider = context.read<LeaveProvider>();

    final request = LeaveRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      staffId: auth.userEmail ?? 'anonymous',
      staffName: auth.userName ?? 'Staff',
      startDate: _selectedRange!.start,
      endDate: _selectedRange!.end,
      reason: _reasonController.text.trim(),
      type: _selectedType,
    );

    final result = await provider.submitLeaveRequest(request);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      result.when(
        onSuccess: (_) {
          Globals.showSnackBar('Leave request submitted successfully');
          context.pop();
        },
        onFailure: (e) => Globals.showSnackBar('Submission failed: ${e.toString()}', isError: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: GlassAppBar(
        title: 'Request Leave',
        showBackButton: true,
         onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SELECT DATES'),
            const SizedBox(height: 12),
            BentoCard(
              onTap: _pickDateRange,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, color: AppTheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedRange == null 
                            ? 'Tomorrow or Custom Dates' 
                            : '${DateFormat('MMM dd').format(_selectedRange!.start)} - ${DateFormat('MMM dd').format(_selectedRange!.end)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        Text(
                          _selectedRange == null ? 'Tap to choose' : '${_selectedRange!.duration.inDays + 1} day(s) selected',
                          style: const TextStyle(color: AppTheme.textMid, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('LEAVE TYPE'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeChip('Full Day', LeaveType.fullDay),
                const SizedBox(width: 12),
                _buildTypeChip('Half Day', LeaveType.halfDay),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('REASON FOR LEAVE'),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. Family emergency, personal work, etc.',
              ).applyDefaults(theme.inputDecorationTheme),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                label: 'SUBMIT REQUEST',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppTheme.textMid,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTypeChip(String label, LeaveType type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
