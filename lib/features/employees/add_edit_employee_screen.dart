import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/employee_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/employee.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../app/globals.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic>? employee;
  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _designationController;
  late TextEditingController _departmentController;
  late TextEditingController _salaryController;
  late TextEditingController _addressController;

  DateTime _joiningDate = DateTime.now();
  XFile? _imageFile;
  String? _existingPhotoUrl;
  bool _isEdit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📝 [INIT] AddEditEmployeeScreen');
    // Smart Detection: True only if we have an existing database ID
    _isEdit = widget.employee != null &&
        (widget.employee!['id'] != null || widget.employee!['_id'] != null);
    final emp =
        widget.employee != null ? Employee.fromMap(widget.employee!) : null;

    _nameController = TextEditingController(text: emp?.name);
    _emailController = TextEditingController(text: emp?.email);
    _phoneController = TextEditingController(text: emp?.phone);
    _designationController = TextEditingController(text: emp?.designation);
    _departmentController = TextEditingController(text: emp?.department);
    _salaryController = TextEditingController(
        text: emp?.salary.toString() == '0' ? '' : emp?.salary.toString());
    _addressController = TextEditingController(text: emp?.address);
    _joiningDate = emp?.joiningDate ?? DateTime.now();
    _existingPhotoUrl = emp?.photoUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Aggressive Professional Compression: 50% quality and 1024px limit for speed
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile != null) setState(() => _imageFile = pickedFile);
  }

  @override
  void dispose() {
    debugPrint('📝 [DISPOSE] AddEditEmployeeScreen');
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? finalPhotoUrl = _existingPhotoUrl;
    if (_imageFile != null) {
      debugPrint('📸 Uploading Photo...');
      finalPhotoUrl =
          await context.read<EmployeeProvider>().uploadImage(_imageFile!);
      if (finalPhotoUrl == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          Globals.showSnackBar('Photo upload failed', isError: true);
        }
        return;
      }
    }

    final employeeId = _isEdit ? (widget.employee!['id'] ?? widget.employee!['_id'])?.toString() : null;
    debugPrint('🛠️ Saving Employee. Edit Mode: $_isEdit, Resolved ID: $employeeId');

    final employee = Employee(
      id: employeeId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      designation: _designationController.text.trim(),
      department: _departmentController.text.trim(),
      joiningDate: _joiningDate,
      salary: double.tryParse(_salaryController.text) ?? 0,
      address: _addressController.text.trim(),
      photoUrl: finalPhotoUrl,
    );

    try {
      debugPrint('🚀 Dispatching Update/Create to Provider...');
      final response = _isEdit
          ? await context.read<EmployeeProvider>().updateEmployee(employee)
          : await context.read<EmployeeProvider>().addEmployee(employee);

      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('🏁 Save Complete. UI Refreshed.');
        
        response.when(
          onSuccess: (_) {
            debugPrint('✅ Success Path. Buffering Screen Exit...');
            context.read<AuthProvider>().fetchAllUsers();
            Globals.showSnackBar(_isEdit ? 'Staff Updated' : 'Staff Added');
            
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                debugPrint('🚀 Returning to Dashboard...');
                context.pop();
              }
            });
          },
          onFailure: (e) => Globals.showSnackBar(e.toString(), isError: true),
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Color(0xFF1E293B)),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  TextButton(
                    onPressed: _isLoading ? null : _save,
                    child: const Text('SAVE',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  centerTitle: false,
                  title: Text(
                    _isEdit ? 'Edit Profile' : 'New Staff Member',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5),
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
                        _buildRoleBadge('STAFF', AppTheme.primary),
                        const SizedBox(height: 16),
                        _buildPhotoSection(),
                        const SizedBox(height: 24),
                        _buildFormGroup('PERSONAL DETAILS', [
                          _buildField(
                              controller: _nameController,
                              label: 'Full Name',
                              icon: Icons.person_rounded,
                              validator: (v) => v!.isEmpty ? 'Required' : null),
                          _buildField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress),
                          _buildField(
                              controller: _phoneController,
                              label: 'Phone',
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone),
                        ]),
                        const SizedBox(height: 24),
                        _buildFormGroup('EMPLOYMENT', [
                          _buildField(
                              controller: _designationController,
                              label: 'Designation',
                              icon: Icons.badge_rounded),
                          _buildField(
                              controller: _departmentController,
                              label: 'Department',
                              icon: Icons.business_rounded),
                          _buildDatePicker(),
                          _buildField(
                              controller: _salaryController,
                              label: 'Salary (₹)',
                              icon: Icons.payments_rounded,
                              keyboardType: TextInputType.number),
                        ]),
                        const SizedBox(height: 24),
                        _buildFormGroup('LOCATION', [
                          _buildField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.location_on_rounded,
                              maxLines: 3),
                        ]),
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
            message: _isEdit ? 'Updating Profile...' : 'Adding Staff...',
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
          onPressed: _switchToIntern,
          icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.accent),
          label: const Text('SWITCH TO INTERN PROFILE',
              style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
        ),
        const SizedBox(height: 8),
        Text('This will move this profile to the Intern directory',
            style: TextStyle(
                fontSize: 10, color: AppTheme.textLight.withOpacity(0.5))),
      ],
    );
  }

  void _switchToIntern() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumConfirmationDialog(
        title: 'Switch to Intern?',
        message:
            'This will move ${_nameController.text} to the Intern directory. Some staff-specific data like Salary may be lost.',
        confirmLabel: 'Switch Now',
        confirmColor: AppTheme.accent,
        icon: Icons.school_rounded,
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
        await context
            .read<EmployeeProvider>()
            .deleteEmployee(widget.employee!['id']);
      }

      if (mounted) {
        Navigator.pop(context); // Close current
        context.push('/interns/add', extra: data);
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
            Icon(role == 'INTERN' ? Icons.school_rounded : Icons.work_rounded,
                size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              'SYSTEM ROLE: $role',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1),
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
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.1), width: 2)),
                child: PremiumImage(
                  imageUrl: _imageFile?.path ??
                      ApiConfig.getFullImageUrl(_existingPhotoUrl),
                  size: 100,
                  isCircle: true,
                ),
              ),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 16, color: Colors.white))),
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
        Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(title,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey.withOpacity(0.6),
                    letterSpacing: 1))),
        BentoCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: children)),
      ],
    );
  }

  Widget _buildField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType? keyboardType,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
          filled: true,
          fillColor: const Color(0xFFF1F5F9).withOpacity(0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppTheme.primary, width: 1.5)),
          labelStyle:
              TextStyle(fontSize: 13, color: Colors.blueGrey.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: _joiningDate,
            firstDate: DateTime(2010),
            lastDate: DateTime(2030));
        if (d != null) setState(() => _joiningDate = d);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppTheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JOINING DATE',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueGrey.withOpacity(0.6))),
                Text(DateFormat('dd MMM, yyyy').format(_joiningDate),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
