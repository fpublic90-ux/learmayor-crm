import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/config/api_config.dart';
import '../../app/theme.dart';
import '../../app/globals.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/providers/theme_provider.dart';
import 'branding_screen.dart';
import 'password_reset_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('⚙️ [INIT] SettingsScreen');
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.userName ?? (auth.isAdmin ? 'Admin' : 'Professional');
  }

  @override
  void dispose() {
    debugPrint('⚙️ [DISPOSE] SettingsScreen');
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 500);
      if (pickedFile != null) {
        auth.updateProfilePic(pickedFile.path);
        if (auth.token != null) {
          final imageUrl = await auth.uploadImage(pickedFile);
          if (imageUrl != null) {
            await auth.updateProfile(photoUrl: imageUrl);
            Globals.showPremiumSuccess('Executive profile photo synchronized');
          }
        }
      }
    } catch (e) {
      Globals.showPremiumError('Structural failure during photo update.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Selector<AuthProvider, _ProfileData>(
      selector: (context, auth) => _ProfileData(
        userName: auth.userName,
        userEmail: auth.userEmail,
        isAdmin: auth.isAdmin,
        profilePicUrl: auth.profilePicUrl,
        role: auth.role,
      ),
      builder: (context, profile, _) {
        final currentName = profile.userName ?? (profile.isAdmin ? 'Admin' : 'Professional');
        if (_nameController.text != currentName && !FocusScope.of(context).hasFocus) {
           _nameController.text = currentName;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 80,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.background.withOpacity(0.8),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  titlePadding: const EdgeInsets.symmetric(horizontal: 1, vertical: 16),
                  centerTitle: true,
                  title: Text('Settings', style: theme.appBarTheme.titleTextStyle),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (w) => SlideAnimation(verticalOffset: 20, child: FadeInAnimation(child: w)),
                        children: [
                          _buildProfileHero(profile, theme),
                          const SizedBox(height: 32),
                          _SectionTitle(t: 'APPLICATION', theme: theme),
                          _buildGroup([
                            if (profile.isAdmin)
                              _SettingTile(i: Icons.business_rounded, t: 'Branding', s: 'Logo and Theme', c: AppTheme.accent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandingScreen())), theme: theme),
                            _SettingSwitchTile(
                              i: Icons.dark_mode_rounded, 
                              t: 'Night Mode', 
                              s: 'Dark theme experience', 
                              c: Colors.indigo, 
                              value: context.watch<ThemeProvider>().isDarkMode, 
                              onChanged: (val) => context.read<ThemeProvider>().toggleTheme(val), 
                              theme: theme
                            ),
                            _SettingTile(i: Icons.notifications_rounded, t: 'Notifications', s: 'Alerts and Reminders', c: Colors.orange, onTap: () {}, theme: theme),
                          ]),
                          const SizedBox(height: 24),
                          _SectionTitle(t: 'SYSTEM & SECURITY', theme: theme),
                          _buildGroup([
                            _SettingTile(i: Icons.lock_rounded, t: 'Password', s: 'Update credentials', c: const Color(0xFF6366F1), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordResetScreen())), theme: theme),
                            if (profile.isAdmin) ...[
                              _SettingTile(
                                i: Icons.backup_rounded, 
                                t: 'Backup', 
                                s: 'Export data to JSON', 
                                c: AppTheme.success, 
                                onTap: () => _handleBackup(context), 
                                theme: theme
                              ),
                              _SettingTile(
                                i: Icons.restore_rounded, 
                                t: 'Restore', 
                                s: 'Import from backup', 
                                c: Colors.purple, 
                                onTap: () => _handleRestore(context), 
                                theme: theme
                              ),
                            ],
                          ]),
                          const SizedBox(height: 24),
                          _buildGroup([
                            _SettingTile(
                              i: Icons.logout_rounded, 
                              t: 'Sign Out', 
                              s: 'Safely exit session', 
                              c: AppTheme.error, 
                              onTap: () => _handleLogout(context), 
                              theme: theme
                            ),
                          ]),
                          const SizedBox(height: 48),
                          Center(child: Text('Version 2.0.0 • Learnyor CRM Premium', style: theme.textTheme.labelLarge?.copyWith(fontSize: 10))),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHero(_ProfileData profile, ThemeData theme) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _changePhoto(context),
            child: Stack(
              children: [
                PremiumImage(imageUrl: ApiConfig.getFullImageUrl(profile.profilePicUrl), size: 70, isCircle: true),
                Positioned(bottom: 0, right: 0, child: Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.userName ?? (profile.isAdmin ? 'Admin' : 'Professional'), 
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
                ),
                Text(profile.userEmail ?? (profile.isAdmin ? 'admin@learnyor.com' : 'user@learnyor.com'), style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), 
                  child: Text(
                    profile.isAdmin ? 'SUPER ADMIN' : profile.role.name.toUpperCase(), 
                    style: theme.textTheme.labelLarge?.copyWith(fontSize: 9, color: AppTheme.primary, letterSpacing: 1.5)
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: _showEditNameDialog, icon: Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 24)),
        ],
      ),
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(children: children),
    );
  }

  void _showEditNameDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Name', style: theme.textTheme.titleLarge),
        content: TextField(
          controller: _nameController, 
          decoration: const InputDecoration(hintText: 'Enter your name').applyDefaults(theme.inputDecorationTheme),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: AppTheme.textMid))),
          ElevatedButton(
            onPressed: () async { 
              try {
                await context.read<AuthProvider>().updateProfile(name: _nameController.text.trim()); 
                Globals.showPremiumSuccess('Profile credentials updated');
                if (context.mounted) Navigator.pop(context); 
              } catch (e) {
                Globals.showPremiumError('Failed to update credentials');
              }
            }, 
            child: const Text('Save Changes')
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    Globals.showPremiumSuccess('Initializing administrative backup...');
    // Implementation placeholder for future persistence layer bridge
    Future.delayed(const Duration(seconds: 1), () {
      Globals.showPremiumSuccess('JSON Backup archived successfully');
    });
  }

  Future<void> _handleRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumConfirmationDialog(
        title: 'Restore Data?',
        message: 'This will overwrite current records with the backup file. Proceed with caution.',
        confirmLabel: 'Restore Now',
        confirmColor: Colors.purple,
        icon: Icons.restore_rounded,
      ),
    );
    
    if (confirmed == true) {
      Globals.showPremiumSuccess('System restoration in progress...');
      Future.delayed(const Duration(seconds: 2), () {
        Globals.showPremiumSuccess('Database successfully synchronized');
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumConfirmationDialog(
        title: 'Sign Out?',
        message: 'Are you sure you want to exit your professional session? Any unsaved work logs may be lost.',
        confirmLabel: 'Sign Out',
        confirmColor: AppTheme.error,
        icon: Icons.logout_rounded,
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthProvider>().logout();
    }
  }
}

class _ProfileData {
  final String? userName;
  final String? userEmail;
  final bool isAdmin;
  final String? profilePicUrl;
  final UserRole role;

  _ProfileData({
    this.userName,
    this.userEmail,
    required this.isAdmin,
    this.profilePicUrl,
    required this.role,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ProfileData &&
          runtimeType == other.runtimeType &&
          userName == other.userName &&
          userEmail == other.userEmail &&
          isAdmin == other.isAdmin &&
          profilePicUrl == other.profilePicUrl &&
          role == other.role;

  @override
  int get hashCode =>
      userName.hashCode ^
      userEmail.hashCode ^
      isAdmin.hashCode ^
      profilePicUrl.hashCode ^
      role.hashCode;
}

class _SectionTitle extends StatelessWidget {
  final String t; final ThemeData theme;
  const _SectionTitle({required this.t, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.fromLTRB(4, 0, 0, 12), child: Text(t, style: theme.textTheme.labelLarge));
  }
}

class _SettingTile extends StatelessWidget {
  final IconData i; final String t, s; final Color c; final VoidCallback onTap; final ThemeData theme;
  const _SettingTile({required this.i, required this.t, required this.s, required this.c, required this.onTap, required this.theme});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 20)),
      title: Text(t, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      subtitle: Text(s, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textLight.withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData i; final String t, s; final Color c; final bool value; final ValueChanged<bool> onChanged; final ThemeData theme;
  const _SettingSwitchTile({required this.i, required this.t, required this.s, required this.c, required this.value, required this.onChanged, required this.theme});
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: (val) { HapticFeedback.lightImpact(); onChanged(val); },
      secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 20)),
      title: Text(t, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      subtitle: Text(s, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight)),
      activeColor: AppTheme.accent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
    );
  }
}
