import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/neumorphic_alert.dart';
import '../../widgets/neumorphic_text_field.dart';

import '../../core/services/auth_service.dart';

class MobileSettingsScreen extends StatefulWidget {
  const MobileSettingsScreen({super.key});

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.fetchProfile();
      if (mounted) setState(() => _userProfile = profile);
    } catch (_) {}
  }

  void _showComingSoon(BuildContext context, String title) {
    showNeumorphicAlert(
      context,
      title: title,
      message: 'This feature will be available in a future update.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          ParallaxBackground(
            scrollController: ScrollController(),
            overscrollAllowance: screenHeight * 0.15,
            screenHeight: screenHeight,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                              spreadRadius: -1.0,
                            ),
                            const BoxShadow(
                              color: AppTheme.buttonHighlightColor,
                              offset: Offset(-4, -4),
                              blurRadius: 8,
                              spreadRadius: -1.0,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Transform.rotate(
                            angle: 3.14159, // 180 degrees in radians
                            child: Image.asset(
                              'assets/icons/right_arrow.png',
                              width: 22,
                              height: 22,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      _buildSectionTitle('Account'),
                      _buildSettingsTile(
                        context,
                        iconWidget: Image.asset('assets/icons/user.png', width: 24, height: 24),
                        title: 'Edit Profile',
                        subtitle: 'Change your name',
                        onTap: () => _showEditProfileDialog(context),
                      ),
                      _buildSettingsTile(
                        context,
                        iconWidget: Image.asset('assets/icons/lock.png', width: 24, height: 24),
                        title: 'Change Password',
                        subtitle: 'Update your security credentials',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('Preferences'),
                      _buildSettingsTile(
                        context,
                        iconWidget: Image.asset('assets/icons/notification.png', width: 24, height: 24),
                        title: 'Notifications',
                        subtitle: 'Manage alerts and reminders',
                        onTap: () => _showComingSoon(context, 'Notifications'),
                      ),
                      _buildSettingsTile(
                        context,
                        iconWidget: Image.asset('assets/icons/theme.png', width: 24, height: 24),
                        title: 'Theme',
                        subtitle: 'System default',
                        onTap: () => _showComingSoon(context, 'Theme'),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('More'),
                      _buildSettingsTile(
                        context,
                        iconWidget: Image.asset('assets/icons/privacy.png', width: 24, height: 24),
                        title: 'Privacy Policy',
                        onTap: () => _showComingSoon(context, 'Privacy Policy'),
                      ),
                      _buildSettingsTile(
                        context,
                        iconWidget: Image.asset('assets/icons/support.png', width: 24, height: 24),
                        title: 'Help & Support',
                        onTap: () => _showComingSoon(context, 'Help & Support'),
                      ),
                      
                      const SizedBox(height: 40),
                      const Center(
                        child: Text(
                          'Prominder v1.0.0',
                          style: TextStyle(
                            color: AppTheme.descriptionTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.descriptionTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required Widget iconWidget, required String title, String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(50), // Pill shaped
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          const BoxShadow(
            color: AppTheme.buttonHighlightColor,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppTheme.descriptionTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.descriptionTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    if (_userProfile == null) return;

    final firstNameCtrl = TextEditingController(text: _userProfile!.firstName);
    final lastNameCtrl = TextEditingController(text: _userProfile!.lastName);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Edit Profile', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphicTextField(
                    hintText: 'First Name',
                    controller: firstNameCtrl,
                  ),
                  const SizedBox(height: 20),
                  NeumorphicTextField(
                    hintText: 'Last Name',
                    controller: lastNameCtrl,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.descriptionTextColor)),
                ),
                TextButton(
                  onPressed: isSaving ? null : () async {
                    setDialogState(() => isSaving = true);
                    try {
                      await AuthService.updateProfile(
                        firstName: firstNameCtrl.text.trim(),
                        lastName: lastNameCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _loadProfile(); // reload locally
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
                      }
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        showNeumorphicAlert(context, title: 'Error', message: e.toString());
                      }
                    }
                  },
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    if (_userProfile == null) return;
    bool isRequesting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Change Password', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
              content: Text(
                'We will send a password reset link to your email:\n\n${_userProfile!.email}\n\nDo you want to proceed?',
                style: const TextStyle(color: AppTheme.descriptionTextColor, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.descriptionTextColor)),
                ),
                TextButton(
                  onPressed: isRequesting ? null : () async {
                    setDialogState(() => isRequesting = true);
                    try {
                      await AuthService.requestPasswordReset(_userProfile!.email);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        showNeumorphicAlert(context, title: 'Email Sent', message: 'A password reset link has been sent to your email.');
                      }
                    } catch (e) {
                      setDialogState(() => isRequesting = false);
                      if (context.mounted) {
                        showNeumorphicAlert(context, title: 'Error', message: e.toString());
                      }
                    }
                  },
                  child: isRequesting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2))
                      : const Text('Send Reset Link', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}

