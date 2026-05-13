import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/company_provider.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final company = context.read<CompanyProvider>();
    _nameController.text = company.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final auth = context.read<AuthProvider>();
        // 1. Upload to backend/cloudinary first
        // (Reusing the existing upload logic)
        final imageUrl = await context.read<AuthProvider>().uploadImage(pickedFile);
        if (imageUrl != null) {
          await context.read<CompanyProvider>().updateCompany(
            logoUrl: imageUrl,
            token: auth.token,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await context.read<CompanyProvider>().updateCompany(
        name: _nameController.text.trim(),
        token: auth.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company name updated!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(isDesktop),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ResponsiveWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('IDENTITY',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMid,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    BentoCard(
                      child: Column(
                        children: [
                          const Text('Company Logo',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _pickLogo,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: AppTheme.premiumShadow,
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: PremiumImage(
                                    imageUrl: company.logoUrl,
                                    size: 110,
                                    isCircle: false,
                                    borderRadius: 18,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                if (_isLoading)
                                  const CircularProgressIndicator(),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('PNG or JPG recommended',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textLight)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    BentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Company Name',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter company name',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: AppTheme.primary),
                                onPressed: _saveName,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                        'Note: These changes will be reflected globally across all screens and reports.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMid,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, isDesktop ? 60 : 24, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: ResponsiveWrapper(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon:
                  const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company Branding',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Customize the identity of your CRM',
                  style: TextStyle(color: AppTheme.textMid, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
