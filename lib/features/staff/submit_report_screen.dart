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
        title: const Text('Daily Report'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WHAT DID YOU ACHIEVE TODAY?', style: theme.textTheme.labelLarge),
            const SizedBox(height: 16),
            BentoCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hours Worked',
                      prefixIcon: const Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ).applyDefaults(theme.inputDecorationTheme),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe your accomplishments...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ).applyDefaults(theme.inputDecorationTheme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('TASKS COMPLETED', style: theme.textTheme.labelLarge),
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
                          decoration: InputDecoration(
                            hintText: 'Add a specific task...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ).applyDefaults(theme.inputDecorationTheme),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _addTask,
                        icon: const Icon(Icons.add_rounded),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.accent),
                      ),
                    ],
                  ),
                  if (_tasks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tasks.map((task) => Chip(
                        label: Text(task, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setState(() => _tasks.remove(task)),
                        deleteIconColor: AppTheme.error,
                        backgroundColor: AppTheme.divider,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
