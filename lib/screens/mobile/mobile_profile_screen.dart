import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/global_loader.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/floating_bottom_navbar.dart';
import 'mobile_login_screen.dart';
import 'mobile_settings_screen.dart';

class MobileProfileScreen extends StatefulWidget {
  final int initialNavIndex;
  final ValueChanged<int> onNavTap;

  const MobileProfileScreen({
    super.key,
    required this.initialNavIndex,
    required this.onNavTap,
  });

  @override
  State<MobileProfileScreen> createState() => _MobileProfileScreenState();
}

class _MobileProfileScreenState extends State<MobileProfileScreen> {
  bool _isLoading = true;
  UserProfile? _userProfile;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    _fetchProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await AuthService.fetchProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final overscrollAllowance = screenHeight * 0.15;

    // PopScope to catch back button and navigate to home (index 0) if from profile
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onNavTap(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Stack(
          children: [
            // Layer 0: Parallax background (dynamic)
            ParallaxBackground(
              scrollOffset: _scrollOffset,
              overscrollAllowance: overscrollAllowance,
              screenHeight: screenHeight,
            ),
            
            if (_isLoading && _userProfile == null)
              const GlobalLoader()
            else
              SafeArea(
                child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: const TextStyle(color: AppTheme.highlightColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: NeumorphicButton(
                                onPressed: _fetchProfile,
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(color: AppTheme.buttonTextColor),
                                ),
                              ),
                            ),
                          ] else if (_userProfile != null) ...[
                            _buildProfileCard(context),
                            const SizedBox(height: 36),
                            _buildInspirationStats(),
                            const SizedBox(height: 36),
                            SizedBox(
                              width: double.infinity,
                              child: NeumorphicButton(
                                onPressed: _handleLogout,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout, color: AppTheme.buttonTextColor),
                                      SizedBox(width: 12),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.buttonTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100), // bottom nav spacing
                          ],
                        ],
                      ),
                    ),
            ),
            
            // Top-right Settings Button
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 24.0),
                  child: Container(
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
                      icon: const Icon(Icons.settings, color: AppTheme.primaryColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MobileSettingsScreen()),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Floating Navbar
            FloatingBottomNavbar(
              currentIndex: widget.initialNavIndex,
              onTap: widget.onNavTap,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthYear(DateTime d) {
    const months = ["january", "february", "march", "april", "may", "june",
                    "july", "august", "september", "october", "november", "december"];
    return "${months[d.month - 1]}, ${d.year}";
  }

  String _getTimeStr(DateTime d) {
    int h = d.hour;
    final ampm = h >= 12 ? 'pm' : 'am';
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    final hStr = h.toString().padLeft(2, '0');
    final mStr = d.minute.toString().padLeft(2, '0');
    return "$hStr:$mStr $ampm".toLowerCase();
  }

  String _getDayDate(DateTime d) {
    const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return "${days[d.weekday - 1]}, ${d.day}";
  }

  Widget _buildProfileCard(BuildContext context) {
    final now = DateTime.now();
    final monthYear = _getMonthYear(now);
    final timeStr = _getTimeStr(now);
    final dayDate = _getDayDate(now);

    final firstName = _userProfile?.firstName ?? 'User';
    final email = _userProfile?.email ?? 'user@example.com';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main Card Base
        Container(
          margin: const EdgeInsets.only(top: 50),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(8, 8),
                blurRadius: 16,
                spreadRadius: -1.0,
              ),
              const BoxShadow(
                color: AppTheme.buttonHighlightColor,
                offset: Offset(-8, -8),
                blurRadius: 16,
                spreadRadius: -1.0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // Inner content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 30),
                  child: Column(
                    children: [
                      // Date and Time Row (floating left and right of where the avatar is)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            monthYear,
                            style: const TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dayDate,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email.toLowerCase(),
                        style: const TextStyle(
                          color: AppTheme.descriptionTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          // Uses Playfair Display via highlight text style or similar elegant vibe
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hello ${firstName.toLowerCase()}, how are you today?',
                        style: const TextStyle(
                          color: AppTheme.descriptionTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // decorative element - left side stars
                Positioned(
                  left: 20,
                  top: 100,
                  child: Icon(Icons.auto_awesome, color: AppTheme.lightGreen.withValues(alpha: 0.3), size: 30),
                ),
                Positioned(
                  left: 50,
                  top: 140,
                  child: Icon(Icons.auto_awesome, color: AppTheme.lightGreen.withValues(alpha: 0.2), size: 20),
                ),

                // decorative element - right side stars
                Positioned(
                  right: 20,
                  top: 130,
                  child: Icon(Icons.auto_awesome, color: AppTheme.lightGreen.withValues(alpha: 0.3), size: 30),
                ),
                Positioned(
                  right: 40,
                  top: 180,
                  child: Icon(Icons.auto_awesome, color: AppTheme.lightGreen.withValues(alpha: 0.2), size: 20),
                ),
              ],
            ),
          ),
        ),

        // Floating Avatar
        Positioned(
          top: 0,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                  spreadRadius: -1.0,
                ),
                const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-6, -6),
                  blurRadius: 12,
                  spreadRadius: -1.0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightGreen,
                  border: Border.all(
                    color: AppTheme.backgroundColor,
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: AppTheme.backgroundColor,
                ),
                // Since there is an avatar illustration in image 1, we can use an image if we have one.
                // Using an Icon to make it reliable as placeholder.
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Adding the learning stats / points from the user's uploaded example Code inspiration
  Widget _buildInspirationStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(6, 6),
            blurRadius: 12,
            spreadRadius: -1.0,
          ),
          const BoxShadow(
            color: AppTheme.buttonHighlightColor,
            offset: Offset(-6, -6),
            blurRadius: 12,
            spreadRadius: -1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATISTICS',
            style: TextStyle(
              color: AppTheme.lightGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Queries Made',
                  value: '142',
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.military_tech_rounded,
                  label: 'Total Points',
                  value: '2,480',
                  color: AppTheme.highlightColor, // using app theme highlight for pop
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom progress/preference row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Inward shadow effect approximation via decoration
               color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learning Progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.descriptionTextColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quick Learner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.descriptionTextColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // using inner-like styling with a subtle box shadow
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.descriptionTextColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
