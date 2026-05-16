import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/intern_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/intern.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../app/globals.dart';

class AddEditInternScreen extends StatefulWidget {
  final Map<String, dynamic>? intern;
  const AddEditInternScreen({super.key, this.intern});

  @override
  State<AddEditInternScreen> createState() => _AddEditInternScreenState();
}

class _AddEditInternScreenState extends State<AddEditInternScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _collegeController;
  late TextEditingController _departmentController;
  late TextEditingController _stipendController;
  late TextEditingController _mentorController;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));
  XFile? _imageFile;
  String? _existingPhotoUrl;
  bool _isEdit = false;
  bool _isLoading = false;
  bool _certificateIssued = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🎓 [INIT] AddEditInternScreen');
    if (widget.intern != null) {
      _isEdit = widget.intern!['id'] != null || widget.intern!['_id'] != null;
      _nameController = TextEditingController(text: widget.intern!['name'] ?? '');
      _emailController = TextEditingController(text: widget.intern!['email'] ?? '');
      _phoneController = TextEditingController(text: widget.intern!['phone'] ?? '');
      _collegeController = TextEditingController(text: widget.intern!['college'] ?? '');
      _departmentController = TextEditingController(text: widget.intern!['department'] ?? '');
      _mentorController = TextEditingController(text: widget.intern!['mentor'] ?? '');
      _stipendController = TextEditingController(text: (widget.intern!['stipend'] ?? 0).toString() == '0' ? '' : (widget.intern!['stipend'] ?? 0).toString());
      _startDate = DateTime.tryParse(widget.intern!['startDate'] ?? '') ?? DateTime.now();
      _endDate = DateTime.tryParse(widget.intern!['endDate'] ?? '') ?? DateTime.now();
      _existingPhotoUrl = widget.intern!['photoUrl'];
      _certificateIssued = widget.intern!['certificateIssued'] ?? false;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
      _collegeController = TextEditingController();
      _departmentController = TextEditingController();
      _stipendController = TextEditingController();
      _mentorController = TextEditingController();
    }
  }

  @override
  void dispose() {
    debugPrint('🎓 [DISPOSE] AddEditInternScreen');
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _stipendController.dispose();
    _mentorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Aggressive Professional Compression for speed
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile != null) setState(() => _imageFile = pickedFile);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? finalPhotoUrl = _existingPhotoUrl;
    if (_imageFile != null) {
      debugPrint('📸 Uploading Photo...');
      finalPhotoUrl =
          await context.read<InternProvider>().uploadImage(_imageFile!);
      if (finalPhotoUrl == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          Globals.showSnackBar('Photo upload failed', isError: true);
        }
        return;
      }
    }

    final internId = _isEdit ? (widget.intern!['id'] ?? widget.intern!['_id'])?.toString() : null;
    debugPrint('🛠️ Saving Intern. Edit Mode: $_isEdit, Resolved ID: $internId');

    final intern = Intern(
      id: internId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      college: _collegeController.text.trim(),
      department: _departmentController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      stipend: double.tryParse(_stipendController.text) ?? 0,
      mentor: _mentorController.text.trim(),
      photoUrl: finalPhotoUrl,
      certificateIssued: _certificateIssued,
    );

    try {
      debugPrint('🚀 Dispatching Update/Create to Provider...');
      final response = _isEdit 
          ? await context.read<InternProvider>().updateIntern(intern)
          : await context.read<InternProvider>().addIntern(intern);

      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('🏁 Save Complete. UI Refreshed.');
        
        response.when(
          onSuccess: (_) {
            debugPrint('✅ Success Path. Buffering Screen Exit...');
            // Background Sync: Trigger refresh but don't wait for it
            context.read<AuthProvider>().fetchAllUsers();
            Globals.showSnackBar(_isEdit ? 'Intern Updated' : 'Intern Registered');
            
            // Post-Frame Navigation: Ensure dialog is fully gone before popping screen
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                debugPrint('🚀 Returning to Dashboard...');
                context.pop();
              }
            });
          },
          onFailure: (e) {
            debugPrint('❌ Failure Path: $e');
            Globals.showSnackBar(e.toString(), isError: true);
          },
        );
      }
    } catch (e) {
      debugPrint('💥 System Error during save: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Globals.showSnackBar('System Error: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFFF8FAFC).withOpacity(0.8),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  TextButton(
                    onPressed: _isLoading ? null : _save,
                    child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  centerTitle: false,
                  title: Text(
                    _isEdit ? 'Edit Profile' : 'New Intern',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildRoleBadge('INTERN', AppTheme.secondary),
                        const SizedBox(height: 16),
                        _buildPhotoSection(),
                        const SizedBox(height: 24),
                        _buildFormGroup('PERSONAL DETAILS', [
                          _buildField(controller: _nameController, label: 'Full Name', icon: Icons.person_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
                          _buildField(controller: _emailController, label: 'Email', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                          _buildField(controller: _phoneController, label: 'Phone', icon: Icons.phone_rounded, keyboardType: TextInputType.phone),
                        ]),
                        const SizedBox(height: 24),
                        _buildFormGroup('ACADEMIC & INTERNSHIP', [
                          _buildField(controller: _collegeController, label: 'College/University', icon: Icons.school_rounded),
                          _buildField(controller: _departmentController, label: 'Department', icon: Icons.business_rounded),
                          _buildField(controller: _mentorController, label: 'Assigned Mentor', icon: Icons.person_search_rounded),
                          _buildDateRangePicker(),
                          _buildField(controller: _stipendController, label: 'Stipend (₹)', icon: Icons.payments_rounded, keyboardType: TextInputType.number),
                        ]),
                        const SizedBox(height: 24),
                        _buildStatusSection(),
                        const SizedBox(height: 32),
                        _buildSwitchRoleAction(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          PremiumLoadingOverlay(
            isLoading: _isLoading,
            message: _isEdit ? 'Updating Profile...' : 'Onboarding Intern...',
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRoleAction() {
    return Column(
      children: [
        const Divider(height: 32, color: AppTheme.divider),
        TextButton.icon(
          onPressed: _switchToEmployee,
          icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
          label: const Text('SWITCH TO EMPLOYEE PROFILE', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        const SizedBox(height: 8),
        Text('This will move this profile to the Employee directory', style: TextStyle(fontSize: 10, color: AppTheme.textLight.withOpacity(0.5))),
      ],
    );
  }

  void _switchToEmployee() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Switch to Employee?',
        message: 'This will move ${_nameController.text} to the Employee directory.',
        confirmLabel: 'Switch Now',
        confirmColor: AppTheme.primary,
        icon: Icons.work_rounded,
      ),
    );

    if (confirmed == true && mounted) {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _departmentController.text.trim(),
        'photoUrl': _existingPhotoUrl,
      };
      
      // If editing existing, delete old one
      if (_isEdit) {
        await context.read<InternProvider>().deleteIntern(widget.intern!['id']);
      }
      
      if (mounted) {
        Navigator.pop(context); // Close current
        context.push('/employees/add', extra: data);
      }
    }
  }

  Widget _buildRoleBadge(String role, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(role == 'INTERN' ? Icons.school_rounded : Icons.work_rounded, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              'SYSTEM ROLE: $role',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 2)),
                child: PremiumImage(
                  imageUrl: _imageFile?.path ?? ApiConfig.getFullImageUrl(_existingPhotoUrl),
                  size: 100,
                  isCircle: true,
                ),
              ),
              Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey.withOpacity(0.6), letterSpacing: 1))),
        BentoCard(padding: const EdgeInsets.all(20), child: Column(children: children)),
      ],
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
          filled: true,
          fillColor: const Color(0xFFF1F5F9).withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          labelStyle: TextStyle(fontSize: 13, color: Colors.blueGrey.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDateTile('START DATE', _startDate, (d) => setState(() => _startDate = d))),
            const SizedBox(width: 12),
            Expanded(child: _buildDateTile('END DATE', _endDate, (d) => setState(() => _endDate = d))),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateTile(String label, DateTime date, Function(DateTime) onChange) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onChange(d);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.blueGrey.withOpacity(0.6))),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 8, bottom: 12), child: Text('CERTIFICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey.withOpacity(0.6), letterSpacing: 1))),
        BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SwitchListTile(
            title: const Text('Certificate Issued', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            subtitle: Text('Mark if internship tenure is completed', style: TextStyle(fontSize: 12, color: Colors.blueGrey.withOpacity(0.6))),
            value: _certificateIssued,
            onChanged: (v) => setState(() => _certificateIssued = v),
            activeThumbColor: AppTheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
