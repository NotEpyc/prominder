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

  // Cover-card flip animation (plays once when user taps the subject cover)
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  // false = showing cover (subject name); true = in study mode (swipe notes)
  bool _deckOpened = false;

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
      _deckOpened = false; // always start from cover
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
        _deckOpened = false;
      });
    }
  }

  void _toggleFlip() {
    if (_deckOpened) return; // already in study mode
    // Flip the cover card forward, then switch to study mode once hidden
    _flipCtrl.forward().then((_) {
      if (mounted) {
        setState(() => _deckOpened = true);
        _flipCtrl.reset(); // tidy up for next open
      }
    });
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
    return const SizedBox(height: 20);
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
    while (i < subjects.length) {
      final remaining = subjects.length - i;
      if (remaining == 1) {
        rows.add(
          Padding(
            padding: padding,
            child: _buildBentoTile(
              subject: subjects[i],
              fullWidth: true,
            ),
          ),
        );
        i++;
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
                    fullWidth: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildBentoTile(
                    subject: subjects[i + 1],
                    fullWidth: false,
                  ),
                ),
              ],
            ),
          ),
        );
        i += 2;
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
    required bool fullWidth,
  }) {
    final notes = _grouped[subject] ?? [];
    final count = notes.length;
    final tileHeight = fullWidth ? 138.0 : 158.0;

    return GestureDetector(
      onTap: () => _openSubject(subject),
      child: Container(
        height: tileHeight,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
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
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Soft decorative circle — top right
              Positioned(
                top: -22,
                right: -22,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Left accent bar
              Positioned(
                left: 0,
                top: 18,
                bottom: 18,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: icon + count pill ──────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: AppTheme.primaryColor
                                .withValues(alpha: 0.80),
                            size: 17,
                          ),
                        ),
                        const Spacer(),
                        // Count pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // ── Subject name ─────────────────────────────────────────
                    Text(
                      subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    // ── Bottom row: note count label + arrow ─────────────────
                    Row(
                      children: [
                        Text(
                          '$count note${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: AppTheme.descriptionTextColor
                                .withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppTheme.primaryColor
                              .withValues(alpha: 0.40),
                        ),
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
        onTap: _closeSubject, // tap dim area to dismiss
        child: Container(
          color: AppTheme.backgroundColor.withValues(alpha: 0.82),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Hint badge — changes once deck is opened
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(_deckOpened),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _deckOpened
                              ? Icons.swipe_rounded
                              : Icons.touch_app_rounded,
                          size: 14,
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _deckOpened
                              ? 'Swipe to navigate notes'
                              : 'Tap card to start studying',
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
                ),

                const SizedBox(height: 12),

                // Card swiper area — absorb taps so they don’t dismiss overlay
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
                            numberOfCardsDisplayed:
                                notes.length == 1 ? 1 : 2,
                            backCardOffset: const Offset(0, 28),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            onSwipe: (prev, curr, dir) {
                              // Block swiping until the cover has been flipped
                              if (!_deckOpened) return false;
                              return true;
                            },
                            cardBuilder: (ctx, index, pX, pY) {
                              if (!_deckOpened) {
                                // All slots show the same cover card;
                                // swiping is blocked so index is always 0.
                                return _buildFocusedFlipCard(
                                    notes[index.clamp(0, notes.length - 1)]);
                              }
                              // Study mode: each card shows its note content
                              return _buildNoteCard(notes[index]);
                            },
                          ),
                  ),
                ),

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

  /// Cover card FRONT — shows only the subject name.
  /// Shown before the deck is opened (before first flip).
  Widget _buildFront(StudyNote note) {
    final notes = _grouped[_focusedSubject ?? ''] ?? [];
    final count = notes.length;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: AppTheme.primaryColor, size: 30),
          ),
          const SizedBox(height: 20),
          Text(
            'STUDY DECK',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryColor.withValues(alpha: 0.55),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            note.parentTopic,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count note${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: AppTheme.descriptionTextColor.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: AppTheme.descriptionTextColor.withValues(alpha: 0.4),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'Tap to start studying',
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

  // ── Note card (study mode) — shown after deck is opened ——————————————

  Widget _buildNoteCard(StudyNote note) {
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
            // Top accent strip (primary green)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            // Subtle border
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppTheme.descriptionTextColor.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Note content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subject breadcrumb
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.parentTopic.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor.withValues(alpha: 0.7),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Note title
                    Text(
                      note.topicTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Swipe hint
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swipe_rounded,
                            color: AppTheme.descriptionTextColor
                                .withValues(alpha: 0.38),
                            size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'Swipe for next',
                          style: TextStyle(
                            color: AppTheme.descriptionTextColor
                                .withValues(alpha: 0.42),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
