import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/floating_bottom_navbar.dart';
import '../../widgets/global_loader.dart';
import '../../widgets/fade_indexed_stack.dart';
import 'dashboard_content.dart';
import 'mobile_chatbot_screen.dart';
import 'mobile_timetable_screen.dart';
import 'mobile_profile_screen.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  // Scroll
  final ScrollController _scrollController = ScrollController();
  int _currentNavIndex = 0;

  // Search — owned here so the search bar can live above the overlay in the Stack
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchActive = false;
  bool _hasText = false;

  String? _pendingPrompt;
  bool _isScreenLoading = true;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChanged);
    _searchController.addListener(() {
      setState(() => _hasText = _searchController.text.trim().isNotEmpty);
    });
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    // Artificial delay to simulate fetching user data, agenda tasks before rendering the dashboard
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isScreenLoading = false);
    }
  }

  void _onFocusChanged() {
    setState(() => _searchActive = _searchFocusNode.hasFocus);
  }

  void _dismissSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _onSearchSubmitted(String val) {
    if (val.trim().isNotEmpty) {
      setState(() {
        _pendingPrompt = val.trim();
        _currentNavIndex = 1;
      });
      _searchController.clear();
      _searchFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.backgroundColor,
      child: FadeIndexedStack(
        duration: const Duration(milliseconds: 500),
        index: _currentNavIndex,
      children: [
        _buildDashboardScreen(context),
        MobileChatbotScreen(
          initialNavIndex: _currentNavIndex,
          initialPrompt: _pendingPrompt,
          onNavTap: (index) {
            if (index == 0) _pendingPrompt = null;
            setState(() => _currentNavIndex = index);
          },
        ),
        MobileTimetableScreen(
          initialNavIndex: _currentNavIndex,
          onNavTap: (index) => setState(() => _currentNavIndex = index),
        ),
        // Placeholder for Cards (3)
        MobileChatbotScreen(
          initialNavIndex: _currentNavIndex,
          initialPrompt: null,
          onNavTap: (index) => setState(() => _currentNavIndex = index),
        ),
        MobileProfileScreen(
          initialNavIndex: _currentNavIndex,
          onNavTap: (index) => setState(() => _currentNavIndex = index),
        ),
      ],
    ),
  );
}

  Widget _buildDashboardScreen(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final overscrollAllowance = screenHeight * 0.15;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Layer 0: Parallax background ──────────────────────────────────
          ParallaxBackground(
            scrollController: _scrollController,
            overscrollAllowance: overscrollAllowance,
            screenHeight: screenHeight,
          ),

          if (_isScreenLoading)
            const GlobalLoader()
          else ...[
            // ── Layer 1: Scrollable content (locked while search is active) ───
            Positioned.fill(
              child: ListView(
                controller: _scrollController,
                physics:
                    _searchActive
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                children: [
                  DashboardContent(
                    searchActive: _searchActive,
                    onDismissSearch: _dismissSearch,
                  ),
                ],
              ),
            ),

            // ── Layer 2: Floating navbar ──────────────────────────────────────
            FloatingBottomNavbar(
              currentIndex: _currentNavIndex,
              onTap: (index) => setState(() => _currentNavIndex = index),
            ),

            // ── Layer 3: Full-screen dim overlay ───────────────────────────
            // Placed BELOW the search bar so overlay never intercepts search taps
            if (_searchActive)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismissSearch,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.50),
                  ),
                ),
              ),

            // ── Layer 4: Search bar — always topmost ────────────────────────
            Positioned(
              top: statusBarHeight + 12,
              left: 24,
              right: 24,
              child: _buildSearchBar(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(
        painter: _SearchBarInnerShadowPainter(
          borderRadius: 24,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _searchActive ? 0.30 : 0.22,
              ),
              offset: const Offset(4, 4),
              blurRadius: 3,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: AppTheme.buttonHighlightColor.withValues(
                alpha: _searchActive ? 1.0 : 0.85,
              ),
              offset: const Offset(-4, -4),
              blurRadius: 3,
              spreadRadius: -1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onSubmitted: _onSearchSubmitted,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ask anything...',
                    hintStyle: TextStyle(
                      color: AppTheme.descriptionTextColor,
                      fontWeight: FontWeight.normal,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_hasText) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _onSearchSubmitted(_searchController.text),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Image.asset(
                      'assets/icons/right_arrow.png',
                      width: 26,
                      height: 26,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painters (moved here from DashboardContent since the search bar moved) ───

class _SearchBarInnerShadowPainter extends CustomPainter {
  final double borderRadius;
  final List<BoxShadow> shadows;

  _SearchBarInnerShadowPainter({
    required this.borderRadius,
    required this.shadows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final boundsPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
        );
    canvas.clipPath(boundsPath);

    for (var shadow in shadows) {
      final shadowPaint =
          Paint()
            ..color = shadow.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      final holeRect = rect.shift(shadow.offset).inflate(shadow.spreadRadius);
      final shadowPath = Path()..addRect(rect.inflate(shadow.blurRadius * 5));
      shadowPath.addRRect(
        RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)),
      );
      canvas.drawPath(shadowPath..fillType = PathFillType.evenOdd, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SearchBarInnerShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.shadows != shadows;
}
