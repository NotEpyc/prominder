import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/timetable_service.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/floating_bottom_navbar.dart';
import '../../widgets/global_loader.dart';

class MobileTimetableScreen extends StatefulWidget {
  final int initialNavIndex;
  final Function(int) onNavTap;

  const MobileTimetableScreen({
    super.key,
    required this.initialNavIndex,
    required this.onNavTap,
  });

  @override
  State<MobileTimetableScreen> createState() => _MobileTimetableScreenState();
}

class _MobileTimetableScreenState extends State<MobileTimetableScreen> {
  bool _isLoading = true;
  List<TimetableEntry> _entries = [];
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await TimetableService.fetchEntries();
      entries.sort((a, b) => a.start.compareTo(b.start));
      if (mounted)
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  String _formatTime(DateTime t) {
    int h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Static background
          ParallaxBackground(
            scrollController: _scrollController,
            overscrollAllowance: screenHeight * 0.15,
            screenHeight: screenHeight,
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timetable',
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Your AI-generated study plan',
                            style: TextStyle(
                              color: AppTheme.descriptionTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Refresh button
                      GestureDetector(
                        onTap: _fetchEntries,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
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
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? const GlobalLoader(transparentBg: true)
                      : _error != null
                          ? _buildError()
                          : _entries.isEmpty
                              ? _buildEmpty()
                              : _buildList(),
                ),
              ],
            ),
          ),

          // Floating navbar
          FloatingBottomNavbar(
            currentIndex: widget.initialNavIndex,
            onTap: widget.onNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    // Group entries by date
    final Map<String, List<TimetableEntry>> grouped = {};
    for (final entry in _entries) {
      final key = _formatDate(entry.start);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final date = grouped.keys.elementAt(i);
        final dayEntries = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 12, left: 4),
              child: Text(
                date,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...dayEntries.map((e) => _buildEntryCard(e)),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(TimetableEntry entry) {
    final duration = entry.end.difference(entry.start).inMinutes;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Done indicator
            Container(
              width: 6,
              height: 48,
              decoration: BoxDecoration(
                color: entry.done ? AppTheme.lightGreen : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.topic.name,
                    style: TextStyle(
                      color: entry.done
                          ? AppTheme.descriptionTextColor
                          : AppTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: entry.done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: AppTheme.descriptionTextColor),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatTime(entry.start)} · ${duration}m',
                        style: const TextStyle(
                          color: AppTheme.descriptionTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _PriorityBadge(priority: entry.topic.priority),
                    ],
                  ),
                ],
              ),
            ),
            if (entry.done)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.lightGreen, size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: AppTheme.descriptionTextColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                  ),
                  const BoxShadow(
                    color: AppTheme.buttonHighlightColor,
                    offset: Offset(-6, -6),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: AppTheme.primaryColor, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Timetable Yet',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload your exam timetable image in the chatbot to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.descriptionTextColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppTheme.highlightColor, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.descriptionTextColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchEntries,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
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
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final int priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final labels = {1: 'Low', 2: 'Med', 3: 'High'};
    final colors = {
      1: AppTheme.lightGreen,
      2: AppTheme.accentColor,
      3: AppTheme.highlightColor,
    };
    final label = labels[priority] ?? 'P$priority';
    final color = colors[priority] ?? AppTheme.descriptionTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
