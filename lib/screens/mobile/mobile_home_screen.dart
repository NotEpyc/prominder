import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/floating_bottom_navbar.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Extra space added to the top and rendered above the screen.
    // This allows the user to see the "top part" of the image when they 
    // overscroll (pull down) the list.
    final overscrollAllowance = screenHeight * 0.15;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // The responsive parallax mirrored background
          ParallaxBackground(
            scrollOffset: _scrollOffset,
            overscrollAllowance: overscrollAllowance,
            screenHeight: screenHeight,
          ),

          // Content area (empty for now per request to remove bento cards)
          Positioned.fill(
            child: ListView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(height: screenHeight * 1.5), // So the parallax is still scrollable
              ],
            ),
          ),

          // Floating Neumorphic Bottom Navbar
          FloatingBottomNavbar(
            currentIndex: _currentNavIndex,
            onTap: (index) {
              setState(() {
                _currentNavIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}
