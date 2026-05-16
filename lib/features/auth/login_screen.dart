import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:learnyor_hrm/app/globals.dart';
import '../../core/providers/auth_provider.dart';
import '../../app/theme.dart';
import '../../core/widgets/premium_widgets.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _isSuccess = false;
  bool _isSlowConnection = false;
  UserRole _selectedRole = UserRole.employee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().warmup();
    });
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Globals.showSnackBar('Please enter email and password', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isSlowConnection = false;
    });

    final auth = context.read<AuthProvider>();
    Timer? slowTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _isLoading) {
        setState(() => _isSlowConnection = true);
        HapticFeedback.selectionClick();
      }
    });
    
    try {
      if (_isLogin) {
        await auth.login(_emailController.text.trim(), _passwordController.text);
        slowTimer.cancel();
        if (mounted) {
          setState(() { _isLoading = false; _isSuccess = true; });
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 1200));
          if (mounted) auth.finishLogin();
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'name': _nameController.text.trim(),
            'role': _selectedRole.name,
          }),
        );
        slowTimer.cancel();
        if (response.statusCode == 201) {
          await auth.login(
            _emailController.text.trim(), 
            _passwordController.text, 
            manualRole: _selectedRole,
          );
          if (mounted) {
            setState(() { _isLoading = false; _isSuccess = true; });
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) auth.finishLogin();
          }
        } else {
          final data = jsonDecode(response.body);
          throw Exception(data['error'] ?? 'Registration failed');
        }
      }
    } catch (e) {
      slowTimer.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
        HapticFeedback.vibrate();
        Globals.showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // IMMERSIVE BACKGROUND
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 800),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildLoginPanel(),
                        const SizedBox(height: 24),
                        _buildActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: -10)
            ],
          ),
          child: const Icon(Icons.token_rounded, size: 54, color: AppTheme.accent),
        ),
        const SizedBox(height: 32),
        const Text(
          'Learnyor CRM',
          style: TextStyle(
            color: Colors.white, 
            fontSize: 34, 
            fontWeight: FontWeight.w900, 
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Official Management Portal',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5), 
            fontSize: 14, 
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      blur: 20,
      opacity: 0.08,
      borderRadius: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isLogin) ...[
            _buildField(_nameController, 'Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildRoleSelector(),
            const SizedBox(height: 20),
          ],
          _buildField(_emailController, 'Enter Email', Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildField(_passwordController, 'Enter Password', Icons.lock_outline_rounded, obscure: true),
          const SizedBox(height: 40),
          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary)),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          child: Text(
            _isLogin ? 'New Member? Register' : 'Already have an account? Login',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 80),
                  const SizedBox(height: 24),
                  const Text('ACCESS GRANTED', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text('Initializing System...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('I AM JOINING AS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        Row(
          children: [
            _RoleButton(
              label: 'STAFF MEMBER', 
              icon: Icons.work_rounded, 
              isSelected: _selectedRole == UserRole.employee,
              onTap: () => setState(() => _selectedRole = UserRole.employee),
            ),
            const SizedBox(width: 12),
            _RoleButton(
              label: 'INTERN', 
              icon: Icons.school_rounded, 
              isSelected: _selectedRole == UserRole.intern,
              onTap: () => setState(() => _selectedRole = UserRole.intern),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label; final IconData icon; final bool isSelected; final VoidCallback onTap;
  const _RoleButton({required this.label, required this.icon, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.accent : Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white30, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white30, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
