import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/config/api_config.dart';
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
  final _hoursController = TextEditingController();
  final List<String> _tasks = [];
  final List<String> _attachments = [];
  bool _isSubmitting = false;
  bool _isUploadingFile = false;

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
      attachments: _attachments,
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
             const SizedBox(height: 32),
            _buildSectionHeader('SUPPORTING DOCUMENTS & IMAGES', Icons.attach_file_rounded),
            const SizedBox(height: 16),
            BentoCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isUploadingFile) ...[
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_attachments.isNotEmpty) ...[
                    ..._attachments.map((url) => _buildAttachmentItem(url)),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: PremiumButton(
                      onPressed: _isUploadingFile ? null : _pickAndUploadFile,
                      label: 'ATTACH FILES',
                      isOutline: true,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                onPressed: () {
                  if (!_isSubmitting) _handleSubmit();
                },
                label: 'SUBMIT DAILY LOG',
                isLoading: _isSubmitting,
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMid, letterSpacing: 1.2),
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
            decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(task, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          ),
          IconButton(
            onPressed: () => setState(() => _tasks.remove(task)),
            icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.error),
            style: IconButton.styleFrom(backgroundColor: AppTheme.error.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    final auth = context.read<AuthProvider>();

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg', 'webp'],
      );

      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingFile = true);
        
        for (final file in result.files) {
          final request = http.MultipartRequest(
            'POST', 
            Uri.parse('${ApiConfig.baseUrl}/api/upload-document')
          );
          
          if (auth.token != null) {
            request.headers['Authorization'] = 'Bearer ${auth.token}';
          }

          if (kIsWeb) {
            if (file.bytes != null) {
              request.files.add(
                http.MultipartFile.fromBytes(
                  'file', 
                  file.bytes!, 
                  filename: file.name
                )
              );
            }
          } else {
            if (file.path != null) {
              request.files.add(
                await http.MultipartFile.fromPath('file', file.path!)
              );
            }
          }

          final response = await request.send();
          if (response.statusCode == 200) {
            final respStr = await response.stream.bytesToString();
            final data = jsonDecode(respStr);
            final fileUrl = data['fileUrl'];
            if (fileUrl != null) {
              setState(() {
                _attachments.add(fileUrl);
              });
            }
          } else {
            Globals.showSnackBar('Failed to upload ${file.name}', isError: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading file: $e');
      Globals.showSnackBar('Error uploading file: $e', isError: true);
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final decoded = Uri.decodeComponent(uri.pathSegments.last);
      return decoded.split('/').last;
    } catch (_) {
      return 'Attachment';
    }
  }

  IconData _getFileIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp')) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Widget _buildAttachmentItem(String url) {
    final name = _getFileName(url);
    final icon = _getFileIcon(url);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _attachments.remove(url)),
            icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.error),
            style: IconButton.styleFrom(backgroundColor: AppTheme.error.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    // Check modern storage status
    var status = await Permission.storage.status;
    if (status.isGranted) return true;

    status = await Permission.storage.request();
    if (status.isGranted) return true;

    // Direct them to App settings if permanently denied
    if (status.isPermanentlyDenied) {
      _showSettingsDialog();
      return false;
    }

    return false;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Storage Permission Required',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark),
        ),
        content: Text(
          'To attach supporting documents and images, please enable storage access in your app settings.',
          style: TextStyle(color: AppTheme.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    );
  }
}
