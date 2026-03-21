import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/timetable_service.dart';

class DashboardContent extends StatefulWidget {
  /// Whether the search bar (owned by the parent) is currently active.
  final bool searchActive;

  /// Called when the user triggers a back-press while search is active.
  final VoidCallback? onDismissSearch;

  const DashboardContent({
    super.key,
    this.searchActive = false,
    this.onDismissSearch,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isLoading = true;
  List<TimetableEntry> _entries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await TimetableService.fetchEntries();
      // Sort to make sure upcoming events are first
      entries.sort((a, b) => a.start.compareTo(b.start));
      if (mounted) {
        setState(() {
          _entries = entries;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.searchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.searchActive) widget.onDismissSearch?.call();
      },
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            // Locked while search is active
            physics:
                widget.searchActive
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Reserve space for the floating search bar in the parent Stack
                const SizedBox(height: 12 + 50 + 28),
                _buildQuickStats(),
                const SizedBox(height: 28),
                _buildUpNextCard(),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildProgressRingCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildQuickActionsColumn()),
                  ],
                ),
                const SizedBox(height: 28),
                _buildAgendaPanel(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildRaisedCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tasks Done",
                  style: TextStyle(
                    color: AppTheme.descriptionTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "3/10",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildRaisedCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Study Time",
                  style: TextStyle(
                    color: AppTheme.descriptionTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "2h 15m",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    final int minute = time.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  Widget _buildUpNextCard() {
    if (_isLoading) {
      return _buildRaisedCard(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }
    
    // Find next pending task
    final pendingEntries = _entries.where((e) => !e.done).toList();
    
    if (pendingEntries.isEmpty) {
      return _buildRaisedCard(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            "Nothing's Up Next!",
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final upNext = pendingEntries.first;
    final startStr = _formatTime(upNext.start);
    final endStr = _formatTime(upNext.end);
    final duration = upNext.end.difference(upNext.start).inMinutes;

    return _buildRaisedCard(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "UP NEXT",
                style: TextStyle(
                  color: AppTheme.lightGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                upNext.topic.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppTheme.descriptionTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$startStr - $endStr (${duration}m)",
                    style: const TextStyle(
                      color: AppTheme.descriptionTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Start session logic
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                        spreadRadius: -0.5,
                      ),
                      const BoxShadow(
                        color: AppTheme.buttonHighlightColor,
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                        spreadRadius: -0.5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRingCard() {
    return _buildRaisedCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          const Text(
            "PROGRESS",
            style: TextStyle(
              color: AppTheme.lightGreen,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              // 1. Inward pressed outer track
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundColor,
                ),
                child: CustomPaint(
                  painter: _DashboardInnerShadowPainter(
                    shape: BoxShape.circle,
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                      const BoxShadow(
                        color: AppTheme.buttonHighlightColor,
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
              // 2. Thick smooth progress arc inside the track
              const SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: 0.45,
                  strokeWidth: 12, // Appears inside the pressed track
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
              // 3. Central raised knob (smaller than the track inner diameter)
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
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
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "45%",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircularAIAction(Icons.document_scanner_rounded, "OCR"),
        const SizedBox(height: 16),
        _buildCircularAIAction(Icons.bolt_rounded, "Plan"),
        const SizedBox(height: 16),
        _buildCircularAIAction(Icons.edit_calendar_rounded, "Move"),
      ],
    );
  }

  Widget _buildCircularAIAction(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
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
          child: Icon(icon, color: AppTheme.textColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.descriptionTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
          child: Text(
            "Today's Itinerary",
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          // Wrap inner shadow in a child that enforces bounds
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(
              painter: _DashboardInnerShadowPainter(
                borderRadius: 24,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                  const BoxShadow(
                    color: AppTheme.buttonHighlightColor,
                    offset: Offset(-4, -4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  children: _isLoading
                      ? [const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))]
                      : _error != null
                          ? [
                              Center(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: AppTheme.highlightColor),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ]
                          : _entries.isEmpty
                              ? [
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24.0),
                                      child: Text(
                                        "No tasks scheduled.",
                                        style: TextStyle(color: AppTheme.descriptionTextColor),
                                      ),
                                    ),
                                  )
                                ]
                              : _entries.expand((entry) {
                                  final isLast = entry == _entries.last;
                                  final timeStr = _formatTime(entry.start);
                                  return [
                                    _buildAgendaItem(entry.topic.name, timeStr, entry.done),
                                    if (!isLast)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Divider(
                                          color: AppTheme.lightGreen,
                                          height: 24,
                                          thickness: 0.5,
                                        ),
                                      ),
                                  ];
                                }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaItem(String title, String time, bool isDone) {
    return Row(
      children: [
        // Fake neumorphic radio/check button
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.backgroundColor,
            boxShadow: [
              if (!isDone)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: -0.5,
                ),
              if (!isDone)
                const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: -0.5,
                ),
            ],
          ),
          child:
              isDone
                  ? CustomPaint(
                    painter: _DashboardInnerShadowPainter(
                      shape: BoxShape.circle,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                        const BoxShadow(
                          color: AppTheme.buttonHighlightColor,
                          offset: Offset(-2, -2),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color:
                    isDone ? AppTheme.descriptionTextColor : AppTheme.textColor,
                fontSize: 16,
                fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: AppTheme.lightGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRaisedCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

// Local duplicate of the incredibly useful InnerShadowPainter
// so we don't have to break encapsulation from other widgets.
class _DashboardInnerShadowPainter extends CustomPainter {
  final BoxShape shape;
  final double borderRadius;
  final List<BoxShadow> shadows;

  _DashboardInnerShadowPainter({
    this.shape = BoxShape.rectangle,
    this.borderRadius = 0.0,
    required this.shadows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    Path boundsPath = Path();
    if (shape == BoxShape.circle) {
      boundsPath.addOval(rect);
    } else {
      boundsPath.addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      );
    }

    canvas.clipPath(boundsPath);

    for (var shadow in shadows) {
      final shadowPaint =
          Paint()
            ..color = shadow.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      final holeRect = rect.shift(shadow.offset).inflate(shadow.spreadRadius);

      final shadowPath = Path()..addRect(rect.inflate(shadow.blurRadius * 5));

      if (shape == BoxShape.circle) {
        shadowPath.addOval(holeRect);
      } else {
        shadowPath.addRRect(
          RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)),
        );
      }

      canvas.drawPath(shadowPath..fillType = PathFillType.evenOdd, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardInnerShadowPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shadows != shadows;
  }
}
