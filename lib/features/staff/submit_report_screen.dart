import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrintStack;
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
    debugPrint('============================================================');
    debugPrint('🚀 [SUBMIT REPORT] REPORT SUBMISSION FORM SUBMITTED');
    debugPrint('============================================================');
    
    final hoursText = _hoursController.text.trim();
    final descriptionText = _descriptionController.text.trim();
    
    debugPrint('📝 [SUBMIT REPORT] Form State Details:');
    debugPrint('   - Hours worked input: "$hoursText"');
    debugPrint('   - Description input: "$descriptionText"');
    debugPrint('   - Tasks count: ${_tasks.length}');
    for (int i = 0; i < _tasks.length; i++) {
      debugPrint('     [$i]: ${_tasks[i]}');
    }
    debugPrint('   - Attachments count: ${_attachments.length}');
    for (int i = 0; i < _attachments.length; i++) {
      debugPrint('     [$i]: ${_attachments[i]}');
    }

    if (descriptionText.isEmpty) {
      debugPrint('⚠️ [VALIDATION] Report Description is empty. Aborting submission.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe your work')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    final auth = context.read<AuthProvider>();
    
    final maskedToken = auth.token != null && auth.token!.length > 15 
        ? '${auth.token!.substring(0, 8)}...${auth.token!.substring(auth.token!.length - 8)}' 
        : '<no-token-or-short>';
        
    debugPrint('👤 [SUBMIT REPORT] User Authentication Info:');
    debugPrint('   - User Name: "${auth.userName}"');
    debugPrint('   - User Email: "${auth.userEmail}"');
    debugPrint('   - Token exists: ${auth.token != null}');
    debugPrint('   - Token masked: Bearer $maskedToken');

    final report = WorkReport(
      id: const Uuid().v4(),
      staffId: auth.userEmail ?? 'anonymous',
      staffName: auth.userName ?? 'Staff Member',
      date: DateTime.now(),
      description: descriptionText,
      tasks: _tasks,
      hoursWorked: int.tryParse(hoursText) ?? 0,
      status: ReportStatus.pending,
      attachments: _attachments,
    );

    debugPrint('📦 [SUBMIT REPORT] Serialization Map:');
    try {
      final map = report.toMap();
      debugPrint('   - Map structure: $map');
      final jsonStr = report.toJson();
      debugPrint('   - JSON string: $jsonStr');
    } catch (e) {
      debugPrint('⚠️ [SUBMIT REPORT] Could not serialize report: $e');
    }

    debugPrint('📡 [SUBMIT REPORT] Dispatching to ReportProvider.submitReport()...');
    final result = await context.read<ReportProvider>().submitReport(report);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      result.when(
        onSuccess: (_) {
          debugPrint('✅ [SUBMIT REPORT SUCCESS] Report successfully persisted on Server!');
          debugPrint('============================================================');
          Navigator.pop(context);
          Globals.showSnackBar('Report submitted successfully!');
        },
        onFailure: (e) {
          debugPrint('❌ [SUBMIT REPORT FAILURE] Submission failed:');
          debugPrint('   - Error details: ${e.toString()}');
          debugPrint('============================================================');
          Globals.showSnackBar('Submission failed: ${e.toString()}', isError: true);
        },
      );
    } else {
      debugPrint('⚠️ [SUBMIT REPORT] Screen unmounted after submission response. Handling silently.');
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
      debugPrint('📂 [FILE PICKER] Initiating File Selection');
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (!mounted) {
        debugPrint('⚠️ [FILE PICKER] Screen unmounted after picker closed');
        return;
      }

      if (result != null && result.files.isNotEmpty) {
        debugPrint('✅ [FILE PICKER] Selected ${result.files.length} file(s)');
        setState(() => _isUploadingFile = true);
        
        final allowedExts = ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg', 'webp'];
        for (int i = 0; i < result.files.length; i++) {
          final file = result.files[i];
          final ext = file.extension?.toLowerCase() ?? '';
          
          debugPrint('----------------------------------------');
          debugPrint('📄 [FILE PICKER] Processing File ${i + 1}/${result.files.length}:');
          debugPrint('   - Name: ${file.name}');
          debugPrint('   - Extension: "$ext"');
          debugPrint('   - Size: ${file.size} bytes');
          debugPrint('   - Local Path: ${file.path ?? "N/A (Web/No path)"}');
          debugPrint('   - Bytes available: ${file.bytes != null ? "${file.bytes!.length} bytes" : "null"}');
          debugPrint('----------------------------------------');

          if (ext.isNotEmpty && !allowedExts.contains(ext)) {
            debugPrint('❌ [VALIDATION] Extension "$ext" not allowed. Allowed: $allowedExts');
            Globals.showSnackBar('File format not allowed: ${file.name}', isError: true);
            continue;
          }

          final uploadUrl = '${ApiConfig.baseUrl}/api/upload-document';
          debugPrint('📡 [UPLOAD] Endpoint URL: $uploadUrl');
          final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
          
          if (auth.token != null) {
            final t = auth.token!;
            final maskedToken = t.length > 15 
                ? '${t.substring(0, 8)}...${t.substring(t.length - 8)}' 
                : '<short-token>';
            request.headers['Authorization'] = 'Bearer $t';
            debugPrint('   - Auth Token provided (Masked: Bearer $maskedToken)');
          } else {
            debugPrint('   - No Auth Token found in AuthProvider');
          }

          if (kIsWeb) {
            debugPrint('   - Running on WEB environment');
            if (file.bytes != null) {
              debugPrint('   - Adding file bytes to request (${file.bytes!.length} bytes)');
              request.files.add(
                http.MultipartFile.fromBytes(
                  'file', 
                  file.bytes!, 
                  filename: file.name
                )
              );
            } else {
              debugPrint('❌ [UPLOAD ERROR] File bytes are null on web for: ${file.name}');
            }
          } else {
            debugPrint('   - Running on NATIVE environment');
            if (file.path != null) {
              debugPrint('   - Adding file path to request: ${file.path}');
              request.files.add(
                await http.MultipartFile.fromPath('file', file.path!)
              );
            } else {
              debugPrint('❌ [UPLOAD ERROR] File path is null on native for: ${file.name}');
            }
          }

          debugPrint('📡 [UPLOAD] Sending request...');
          final response = await request.send();
          debugPrint('📡 [UPLOAD] Response Status Code: ${response.statusCode}');
          debugPrint('📡 [UPLOAD] Response Headers: ${response.headers}');

          final respStr = await response.stream.bytesToString();
          debugPrint('📡 [UPLOAD] Raw Response Body:');
          debugPrint(respStr);

          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(respStr);
              debugPrint('✅ [UPLOAD] Decoded JSON Data: $data');
              final fileUrl = data['fileUrl'];
              if (fileUrl != null) {
                debugPrint('✅ [UPLOAD] Extracted fileUrl: $fileUrl');
                setState(() {
                  _attachments.add(fileUrl);
                });
              } else {
                debugPrint('❌ [UPLOAD ERROR] "fileUrl" key is missing from JSON response: $data');
                Globals.showSnackBar('Upload format mismatch for ${file.name}', isError: true);
              }
            } catch (jsonErr) {
              debugPrint('❌ [UPLOAD ERROR] Failed to parse JSON response: $jsonErr');
              Globals.showSnackBar('Invalid response format for ${file.name}', isError: true);
            }
          } else {
            debugPrint('❌ [UPLOAD ERROR] Server returned error code: ${response.statusCode}');
            Globals.showSnackBar('Failed to upload ${file.name}', isError: true);
          }
        }
      } else {
        debugPrint('⚠️ [FILE PICKER] File picker cancelled or returned empty selection');
      }
    } catch (e, s) {
      debugPrint('❌ [FILE PICKER ERROR] Exception caught during file selection or upload:');
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      Globals.showSnackBar('Error uploading file: $e', isError: true);
    } finally {
      setState(() => _isUploadingFile = false);
      debugPrint('🏁 [FILE PICKER] Upload operation complete. Active attachments: $_attachments');
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


}
