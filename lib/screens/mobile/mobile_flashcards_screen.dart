// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notes_service.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/floating_bottom_navbar.dart';

// ─── Bento tile accent colours ─────────────────────────────────────────────
const List<Color> _kAccents = [
  Color(0xFF588157),
  Color(0xFF3A5A40),
  Color(0xFFB56576),
  Color(0xFFD4A373),
  Color(0xFF81B622),
  Color(0xFF5A6658),
];

class MobileFlashcardsScreen extends StatefulWidget {
  final int initialNavIndex;
  final Function(int) onNavTap;

  const MobileFlashcardsScreen({
    super.key,
    required this.initialNavIndex,
    required this.onNavTap,
  });

  @override
  State<MobileFlashcardsScreen> createState() => _MobileFlashcardsScreenState();
}

class _MobileFlashcardsScreenState extends State<MobileFlashcardsScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;

  // Grouped: parentTopic → list of notes
  Map<String, List<StudyNote>> _grouped = {};

  // Focused subject state
  String? _focusedSubject;
  late AnimationController _overlayAnimCtrl;
  late Animation<double> _overlayAnim;
  CardSwiperController? _swiperCtrl;

  // Flip state for the currently displayed note
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();

    _overlayAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _overlayAnim = CurvedAnimation(
      parent: _overlayAnimCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _flipAnim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _overlayAnimCtrl.dispose();
    _flipCtrl.dispose();
    _swiperCtrl?.dispose();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notes = await NotesService.getNotes();
      if (mounted) {
        setState(() {
          _grouped = _groupByParent(notes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Group notes by parentTopic
  Map<String, List<StudyNote>> _groupByParent(List<StudyNote> notes) {
    final map = <String, List<StudyNote>>{};
    for (final n in notes) {
      (map[n.parentTopic] ??= []).add(n);
    }
    return map;
  }

  void _openSubject(String subject) {
    setState(() {
      _focusedSubject = subject;
      _isFlipped = false;
      _swiperCtrl?.dispose();
      _swiperCtrl = CardSwiperController();
    });
    _flipCtrl.reset();
    _overlayAnimCtrl.forward();
  }

  Future<void> _closeSubject() async {
    await _overlayAnimCtrl.reverse();
    if (mounted) {
      setState(() {
        _focusedSubject = null;
        _isFlipped = false;
      });
    }
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Parallax background
          ParallaxBackground(
            scrollController: _scrollController,
            overscrollAllowance: screenHeight * 0.15,
            screenHeight: screenHeight,
          ),

          // Main scrollable content
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Focus overlay sits above everything except the navbar
          if (_focusedSubject != null) _buildFocusOverlay(),

          // Navbar always on top
          FloatingBottomNavbar(
            currentIndex: widget.initialNavIndex,
            onTap: widget.onNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Cards',
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a subject to study',
            style:
                TextStyle(color: AppTheme.descriptionTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Body states ────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SpinKitCubeGrid(color: AppTheme.secondaryColor, size: 46.0),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.highlightColor, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Could not load study cards.',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.descriptionTextColor, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _NeumorphicChip(label: 'Try Again', onTap: _fetchNotes),
            ],
          ),
        ),
      );
    }

    if (_grouped.isEmpty) {
      return const Center(
        child: Text(
          'No flashcards yet.\nAsk the Chatbot to create notes!',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppTheme.descriptionTextColor, fontSize: 16, height: 1.5),
        ),
      );
    }

    return _buildBentoGrid();
  }

  // ── Bento Grid ──────────────────────────────────────────────────────────────

  Widget _buildBentoGrid() {
    final subjects = _grouped.keys.toList();
    final List<Widget> rows = [];
    final padding = const EdgeInsets.symmetric(horizontal: 18);

    int i = 0;
    int accentIdx = 0;
    while (i < subjects.length) {
      final remaining = subjects.length - i;
      if (remaining == 1) {
        rows.add(
          Padding(
            padding: padding,
            child: _buildBentoTile(
              subject: subjects[i],
              accent: _kAccents[accentIdx % _kAccents.length],
              fullWidth: true,
            ),
          ),
        );
        i++;
        accentIdx++;
      } else {
        rows.add(
          Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildBentoTile(
                    subject: subjects[i],
                    accent: _kAccents[accentIdx % _kAccents.length],
                    fullWidth: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildBentoTile(
                    subject: subjects[i + 1],
                    accent: _kAccents[(accentIdx + 1) % _kAccents.length],
                    fullWidth: false,
                  ),
                ),
              ],
            ),
          ),
        );
        i += 2;
        accentIdx += 2;
      }
      rows.add(const SizedBox(height: 14));
    }

    return CustomRefreshIndicator(
      onRefresh: _fetchNotes,
      builder: (context, child, controller) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            if (!controller.isIdle)
              Positioned(
                top: 30.0 * controller.value,
                child: const SpinKitCubeGrid(
                  color: AppTheme.secondaryColor,
                  size: 30.0,
                ),
              ),
            Transform.translate(
              offset: Offset(0, 70.0 * controller.value),
              child: child,
            ),
          ],
        );
      },
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: rows,
      ),
    );
  }

  Widget _buildBentoTile({
    required String subject,
    required Color accent,
    required bool fullWidth,
  }) {
    final notes = _grouped[subject] ?? [];
    final count = notes.length;
    final tileHeight = fullWidth ? 148.0 : 165.0;

    return GestureDetector(
      onTap: () => _openSubject(subject),
      child: Container(
        height: tileHeight,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              offset: const Offset(5, 6),
              blurRadius: 14,
              spreadRadius: -2,
            ),
            const BoxShadow(
              color: AppTheme.buttonHighlightColor,
              offset: Offset(-4, -4),
              blurRadius: 10,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative blob top-right
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Bottom accent strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  color: accent.withValues(alpha: 0.5),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.style_rounded, color: accent, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '$count card${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: AppTheme.descriptionTextColor
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.touch_app_rounded,
                            color: accent.withValues(alpha: 0.55), size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Focus Overlay ──────────────────────────────────────────────────────────

  Widget _buildFocusOverlay() {
    final notes = _grouped[_focusedSubject] ?? [];

    return AnimatedBuilder(
      animation: _overlayAnim,
      builder: (context, child) => Opacity(
        opacity: _overlayAnim.value,
        child: child,
      ),
      child: GestureDetector(
        // Tapping the dim area (outside the swiper) dismisses
        onTap: _closeSubject,
        child: Container(
          // ── Light frosted overlay instead of dark ──
          color: AppTheme.backgroundColor.withValues(alpha: 0.82),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Subtle instruction badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 14,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(
                        'Tap card to flip  •  Swipe to navigate',
                        style: TextStyle(
                          color: AppTheme.descriptionTextColor
                              .withValues(alpha: 0.7),
                          fontSize: 11.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Card swiper - intercept taps so they don't dismiss overlay
                Expanded(
                    child: GestureDetector(
                  onTap: () {}, // absorb taps within swiper area
                  child: notes.isEmpty
                      ? const Center(
                          child: Text(
                            'No cards yet.',
                            style: TextStyle(
                              color: AppTheme.descriptionTextColor,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : CardSwiper(
                          controller: _swiperCtrl!,
                          cardsCount: notes.length,
                          isLoop: notes.length > 1,
                          numberOfCardsDisplayed: notes.length == 1 ? 1 : 2,
                          backCardOffset: const Offset(0, 28),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          onSwipe: (prev, curr, dir) {
                            if (_isFlipped) {
                              _flipCtrl.reset();
                              setState(() => _isFlipped = false);
                            }
                            return true;
                          },
                          cardBuilder: (ctx, index, pX, pY) =>
                              _buildFocusedFlipCard(notes[index]),
                        ),
                )),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Flip Card ──────────────────────────────────────────────────────────────

  Widget _buildFocusedFlipCard(StudyNote note) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, _) {
          final angle = _flipAnim.value;
          final isFrontVisible = angle < (pi / 2);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFrontVisible
                ? _buildCardFace(isFront: true, note: note)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardFace(isFront: false, note: note),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace({required bool isFront, required StudyNote note}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            offset: const Offset(0, 14),
            blurRadius: 28,
          ),
          const BoxShadow(
            color: AppTheme.buttonHighlightColor,
            offset: Offset(-4, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Top tinted strip
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: isFront
                    ? AppTheme.primaryColor.withValues(alpha: 0.5)
                    : AppTheme.secondaryColor.withValues(alpha: 0.5),
              ),
            ),
            // Subtle border
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color:
                        AppTheme.descriptionTextColor.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28.0),
              child: isFront ? _buildFront(note) : _buildBack(note),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFront(StudyNote note) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.style_rounded,
                color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            note.parentTopic.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.descriptionTextColor.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            note.topicTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: AppTheme.descriptionTextColor.withValues(alpha: 0.45),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'Tap to flip',
                style: TextStyle(
                  color: AppTheme.descriptionTextColor.withValues(alpha: 0.5),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(StudyNote note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            note.parentTopic.toUpperCase(),
            style: TextStyle(
              color: AppTheme.secondaryColor.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          note.topicTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swipe_rounded,
                color: AppTheme.descriptionTextColor.withValues(alpha: 0.4), size: 15),
            const SizedBox(width: 6),
            Text(
              'Swipe for next card',
              style: TextStyle(
                color: AppTheme.descriptionTextColor.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Small helper widget ───────────────────────────────────────────────────

class _NeumorphicChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NeumorphicChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              offset: const Offset(4, 4),
              blurRadius: 10,
            ),
            const BoxShadow(
              color: AppTheme.buttonHighlightColor,
              offset: Offset(-4, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
