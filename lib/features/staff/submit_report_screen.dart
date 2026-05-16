import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../app/globals.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/report_provider.dart';
import '../../core/models/report.dart';
import '../../core/widgets/premium_widgets.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _descriptionController = TextEditingController();
  final _taskController = TextEditingController();
  final _hoursController = TextEditingController(text: '8');
  final List<String> _tasks = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📝 [INIT] SubmitReportScreen');
  }

  @override
  void dispose() {
    debugPrint('📝 [DISPOSE] SubmitReportScreen');
    _descriptionController.dispose();
    _taskController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isNotEmpty) {
      debugPrint('➕ [ACTION] Adding Task: $text');
      setState(() {
        _tasks.add(text);
        _taskController.clear();
      });
    }
  }

  Future<void> _handleSubmit() async {
    debugPrint('🚀 [ACTION] Initiating Report Submission');
    if (_descriptionController.text.trim().isEmpty) {
      debugPrint('⚠️ [VALIDATION] Report Description Empty');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe your work')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    final auth = context.read<AuthProvider>();
    final report = WorkReport(
      id: const Uuid().v4(),
      staffId: auth.userEmail ?? 'anonymous',
      staffName: auth.userName ?? 'Staff Member',
      date: DateTime.now(),
      description: _descriptionController.text.trim(),
      tasks: _tasks,
      hoursWorked: int.tryParse(_hoursController.text) ?? 0,
      status: ReportStatus.pending,
    );

    debugPrint('📡 [NET] Dispatching Report: ${report.id} for ${report.staffName}');
    final result = await context.read<ReportProvider>().submitReport(report);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      result.when(
        onSuccess: (_) {
          debugPrint('✅ [SUCCESS] Report Persistent on Server');
          Navigator.pop(context);
          Globals.showSnackBar('Report submitted successfully!');
        },
        onFailure: (e) {
          debugPrint('❌ [ERROR] Submission Failed: ${e.toString()}');
          Globals.showSnackBar('Submission failed: ${e.toString()}', isError: true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Work Log Submission', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('CORE DETAILS', Icons.assessment_rounded),
            const SizedBox(height: 16),
            BentoCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hours Worked',
                      prefixIcon: Icon(Icons.timer_rounded),
                      hintText: 'e.g. 8',
                    ).applyDefaults(theme.inputDecorationTheme),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Daily Description',
                      hintText: 'Briefly summarize your day...',
                      alignLabelWithHint: true,
                    ).applyDefaults(theme.inputDecorationTheme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('SPECIFIC ACHIEVEMENTS', Icons.fact_check_rounded),
            const SizedBox(height: 16),
            BentoCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          decoration: const InputDecoration(
                            hintText: 'Add a professional task...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ).applyDefaults(theme.inputDecorationTheme),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _addTask,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  if (_tasks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ..._tasks.map((task) => _buildTaskItem(task)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('SUBMIT DAILY LOG', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMid, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildTaskItem(String task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(task, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          ),
          IconButton(
            onPressed: () => setState(() => _tasks.remove(task)),
            icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.error),
            style: IconButton.styleFrom(backgroundColor: AppTheme.error.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}
