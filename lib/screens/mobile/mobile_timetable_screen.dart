// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/timetable_service.dart';
import '../../widgets/parallax_background.dart';
import '../../widgets/floating_bottom_navbar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class DateSession {
  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int iconCodePoint;
  final int colorValue;

  const DateSession({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.iconCodePoint,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);
  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);
  DateTime startDateTime(DateTime d) =>
      DateTime(d.year, d.month, d.day, startHour, startMinute);

  DateSession copyWith({
    String? name,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) =>
      DateSession(
        id: id,
        name: name ?? this.name,
        startHour: startHour ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour: endHour ?? this.endHour,
        endMinute: endMinute ?? this.endMinute,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      };

  factory DateSession.fromJson(Map<String, dynamic> j) => DateSession(
        id: j['id'] as String,
        name: j['name'] as String,
        startHour: j['startHour'] as int,
        startMinute: j['startMinute'] as int,
        endHour: j['endHour'] as int,
        endMinute: j['endMinute'] as int,
        iconCodePoint: j['iconCodePoint'] as int,
        colorValue: j['colorValue'] as int,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekday-aware session templates  (1=Mon … 7=Sun)
// Logical rules: no College on Sat/Sun, workout only Mon/Wed/Fri,
// sports only Tue/Thu, walk only Sun, etc.
// ─────────────────────────────────────────────────────────────────────────────

// colour palette shortcuts
const int _cForest = 0xFF3A5A40;
const int _cMoss = 0xFF588157;
const int _cGold = 0xFFD4A373;
const int _cRose = 0xFFB56576;
const int _cLime = 0xFF81B622;
const int _cSage = 0xFF9EAF9C;

List<DateSession> _templateForWeekday(int weekday) {
  switch (weekday) {
    case 1: // Monday
      return [
        DateSession(
            id: 'workout',
            name: 'Morning Workout',
            startHour: 6,
            startMinute: 30,
            endHour: 7,
            endMinute: 30,
            iconCodePoint: Icons.fitness_center_rounded.codePoint,
            colorValue: _cRose),
        DateSession(
            id: 'college',
            name: 'College',
            startHour: 9,
            startMinute: 0,
            endHour: 14,
            endMinute: 0,
            iconCodePoint: Icons.school_rounded.codePoint,
            colorValue: _cForest),
        DateSession(
            id: 'lunch',
            name: 'Lunch Break',
            startHour: 14,
            startMinute: 0,
            endHour: 14,
            endMinute: 45,
            iconCodePoint: Icons.lunch_dining_rounded.codePoint,
            colorValue: _cGold),
        DateSession(
            id: 'study',
            name: 'Evening Study',
            startHour: 17,
            startMinute: 0,
            endHour: 19,
            endMinute: 0,
            iconCodePoint: Icons.menu_book_rounded.codePoint,
            colorValue: _cMoss),
        DateSession(
            id: 'walk',
            name: 'Evening Walk',
            startHour: 19,
            startMinute: 30,
            endHour: 20,
            endMinute: 15,
            iconCodePoint: Icons.directions_walk_rounded.codePoint,
            colorValue: _cSage),
      ];
    case 2: // Tuesday
      return [
        DateSession(
            id: 'college',
            name: 'College',
            startHour: 9,
            startMinute: 0,
            endHour: 14,
            endMinute: 0,
            iconCodePoint: Icons.school_rounded.codePoint,
            colorValue: _cForest),
        DateSession(
            id: 'lunch',
            name: 'Lunch Break',
            startHour: 14,
            startMinute: 0,
            endHour: 14,
            endMinute: 45,
            iconCodePoint: Icons.lunch_dining_rounded.codePoint,
            colorValue: _cGold),
        DateSession(
            id: 'library',
            name: 'Library Study',
            startHour: 15,
            startMinute: 0,
            endHour: 17,
            endMinute: 0,
            iconCodePoint: Icons.local_library_rounded.codePoint,
            colorValue: _cMoss),
        DateSession(
            id: 'sports',
            name: 'Sports Practice',
            startHour: 17,
            startMinute: 30,
            endHour: 19,
            endMinute: 0,
            iconCodePoint: Icons.sports_soccer_rounded.codePoint,
            colorValue: _cLime),
        DateSession(
            id: 'study',
            name: 'Night Study',
            startHour: 20,
            startMinute: 0,
            endHour: 21,
            endMinute: 30,
            iconCodePoint: Icons.menu_book_rounded.codePoint,
            colorValue: _cMoss),
      ];
    case 3: // Wednesday
      return [
        DateSession(
            id: 'workout',
            name: 'Morning Workout',
            startHour: 6,
            startMinute: 30,
            endHour: 7,
            endMinute: 30,
            iconCodePoint: Icons.fitness_center_rounded.codePoint,
            colorValue: _cRose),
        DateSession(
            id: 'college',
            name: 'College',
            startHour: 9,
            startMinute: 0,
            endHour: 14,
            endMinute: 0,
            iconCodePoint: Icons.school_rounded.codePoint,
            colorValue: _cForest),
        DateSession(
            id: 'lunch',
            name: 'Lunch Break',
            startHour: 14,
            startMinute: 0,
            endHour: 14,
            endMinute: 45,
            iconCodePoint: Icons.lunch_dining_rounded.codePoint,
            colorValue: _cGold),
        DateSession(
            id: 'study',
            name: 'Evening Study',
            startHour: 17,
            startMinute: 0,
            endHour: 19,
            endMinute: 0,
            iconCodePoint: Icons.menu_book_rounded.codePoint,
            colorValue: _cMoss),
      ];
    case 4: // Thursday
      return [
        DateSession(
            id: 'college',
            name: 'College',
            startHour: 9,
            startMinute: 0,
            endHour: 14,
            endMinute: 0,
            iconCodePoint: Icons.school_rounded.codePoint,
            colorValue: _cForest),
        DateSession(
            id: 'lunch',
            name: 'Lunch Break',
            startHour: 14,
            startMinute: 0,
            endHour: 14,
            endMinute: 45,
            iconCodePoint: Icons.lunch_dining_rounded.codePoint,
            colorValue: _cGold),
        DateSession(
            id: 'group',
            name: 'Group Study',
            startHour: 15,
            startMinute: 0,
            endHour: 17,
            endMinute: 0,
            iconCodePoint: Icons.groups_rounded.codePoint,
            colorValue: _cSage),
        DateSession(
            id: 'sports',
            name: 'Sports Practice',
            startHour: 17,
            startMinute: 30,
            endHour: 19,
            endMinute: 0,
            iconCodePoint: Icons.sports_soccer_rounded.codePoint,
            colorValue: _cLime),
        DateSession(
            id: 'study',
            name: 'Night Study',
            startHour: 19,
            startMinute: 30,
            endHour: 21,
            endMinute: 0,
            iconCodePoint: Icons.menu_book_rounded.codePoint,
            colorValue: _cMoss),
      ];
    case 5: // Friday
      return [
        DateSession(
            id: 'workout',
            name: 'Morning Workout',
            startHour: 6,
            startMinute: 30,
            endHour: 7,
            endMinute: 30,
            iconCodePoint: Icons.fitness_center_rounded.codePoint,
            colorValue: _cRose),
        DateSession(
            id: 'college',
            name: 'College',
            startHour: 9,
            startMinute: 0,
            endHour: 14,
            endMinute: 0,
            iconCodePoint: Icons.school_rounded.codePoint,
            colorValue: _cForest),
        DateSession(
            id: 'lunch',
            name: 'Lunch Break',
            startHour: 14,
            startMinute: 0,
            endHour: 14,
            endMinute: 45,
            iconCodePoint: Icons.lunch_dining_rounded.codePoint,
            colorValue: _cGold),
        DateSession(
            id: 'social',
            name: 'Social / Hangout',
            startHour: 16,
            startMinute: 0,
            endHour: 18,
            endMinute: 0,
            iconCodePoint: Icons.people_rounded.codePoint,
            colorValue: _cRose),
        DateSession(
            id: 'study',
            name: 'Night Study',
            startHour: 20,
            startMinute: 0,
            endHour: 22,
            endMinute: 0,
            iconCodePoint: Icons.menu_book_rounded.codePoint,
            colorValue: _cMoss),
      ];
    case 6: // Saturday
      return [
        DateSession(
            id: 'run',
            name: 'Morning Run',
            startHour: 7,
            startMinute: 0,
            endHour: 7,
            endMinute: 45,
            iconCodePoint: Icons.directions_run_rounded.codePoint,
            colorValue: _cLime),
        DateSession(
            id: 'grocery',
            name: 'Grocery & Errands',
            startHour: 10,
            startMinute: 0,
            endHour: 11,
            endMinute: 30,
            iconCodePoint: Icons.shopping_cart_rounded.codePoint,
            colorValue: _cGold),
        DateSession(
            id: 'self_study',
            name: 'Self Study',
            startHour: 14,
            startMinute: 0,
            endHour: 17,
            endMinute: 0,
            iconCodePoint: Icons.menu_book_rounded.codePoint,
            colorValue: _cMoss),
        DateSession(
            id: 'leisure',
            name: 'Leisure / Reading',
            startHour: 18,
            startMinute: 0,
            endHour: 19,
            endMinute: 30,
            iconCodePoint: Icons.auto_stories_rounded.codePoint,
            colorValue: _cSage),
      ];
    case 7: // Sunday
    default:
      return [
        DateSession(
            id: 'walk',
            name: 'Morning Walk',
            startHour: 7,
            startMinute: 0,
            endHour: 8,
            endMinute: 0,
            iconCodePoint: Icons.directions_walk_rounded.codePoint,
            colorValue: _cSage),
        DateSession(
            id: 'meal_prep',
            name: 'Meal Prep',
            startHour: 10,
            startMinute: 0,
            endHour: 11,
            endMinute: 30,
            iconCodePoint: Icons.restaurant_rounded.codePoint,
            colorValue: _cGold),
        DateSession(
            id: 'rest',
            name: 'Rest & Recharge',
            startHour: 14,
            startMinute: 0,
            endHour: 16,
            endMinute: 0,
            iconCodePoint: Icons.self_improvement_rounded.codePoint,
            colorValue: _cRose),
        DateSession(
            id: 'prep',
            name: 'Week Prep Study',
            startHour: 17,
            startMinute: 0,
            endHour: 19,
            endMinute: 0,
            iconCodePoint: Icons.event_note_rounded.codePoint,
            colorValue: _cMoss),
      ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-date session persistence
// ─────────────────────────────────────────────────────────────────────────────

String _dateKey(DateTime d) =>
    'dsessions_${d.year}_${d.month.toString().padLeft(2, '0')}_${d.day.toString().padLeft(2, '0')}';

Future<List<DateSession>> _loadOrGenerate(DateTime date) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_dateKey(date));
  if (raw != null) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DateSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }
  final sessions = _templateForWeekday(date.weekday);
  await prefs.setString(
      _dateKey(date), jsonEncode(sessions.map((s) => s.toJson()).toList()));
  return sessions;
}

Future<void> _persistSessions(DateTime date, List<DateSession> sessions) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      _dateKey(date), jsonEncode(sessions.map((s) => s.toJson()).toList()));
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified schedule item (merges hardcoded + API)
// ─────────────────────────────────────────────────────────────────────────────

sealed class _ScheduleItem {
  DateTime get sortKey;
}

class _HardcodedItem extends _ScheduleItem {
  final DateSession session;
  final int sessionIndex;
  final DateTime forDay;
  _HardcodedItem(this.session, this.sessionIndex, this.forDay);
  @override
  DateTime get sortKey => session.startDateTime(forDay);
}

class _ApiItem extends _ScheduleItem {
  final TimetableEntry entry;
  _ApiItem(this.entry);
  @override
  DateTime get sortKey => entry.start;
}

// Short description per session id — shown as subtitle in card
String _sessionDesc(String id) {
  const map = {
    'workout': 'Strength & cardio training',
    'college': 'Lectures, labs & tutorials',
    'lunch': 'Meal break & rest',
    'study': 'Focused revision & notes',
    'walk': 'Light activity & fresh air',
    'library': 'Quiet study at the library',
    'sports': 'Practice & drills',
    'group': 'Collaborative study with peers',
    'social': 'Relax, connect & unwind',
    'run': 'Morning cardio run',
    'grocery': 'Errands & weekly shopping',
    'self_study': 'Independent revision',
    'leisure': 'Reading & relaxation',
    'meal_prep': 'Cook & prep for the week',
    'rest': 'Mindfulness & recharge',
    'prep': 'Plan & prep for the week',
  };
  return map[id] ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

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

class _MobileTimetableScreenState extends State<MobileTimetableScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<TimetableEntry> _entries = [];
  String? _error;

  final ScrollController _scrollController = ScrollController();

  DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  // +1 = swiping to next month (slides in from right), -1 = previous (from left)
  int _calendarSlideDir = 1;

  List<DateSession> _selectedSessions = [];

  late AnimationController _listAnimCtrl;

  @override
  void initState() {
    super.initState();
    _listAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fetchEntries();
    _loadSessions(_selectedDate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _listAnimCtrl.dispose();
    super.dispose();
  }

  // The timetable's position in the bottom nav (0-indexed).
  // Update this if the nav order ever changes.
  static const int _kNavIndex = 2;

  /// Called whenever the parent rebuilds this widget with new props —
  /// i.e. on every tab switch in the IndexedStack.
  /// When [initialNavIndex] transitions to [_kNavIndex] the user has just
  /// swiped/tapped back to the timetable → reset calendar to today.
  @override
  void didUpdateWidget(MobileTimetableScreen old) {
    super.didUpdateWidget(old);
    if (old.initialNavIndex != _kNavIndex &&
        widget.initialNavIndex == _kNavIndex) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      setState(() {
        _calendarMonth = DateTime(now.year, now.month);
        _selectedDate = today;
        _calendarSlideDir = 1;
      });
      _loadSessions(today);
    }
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadSessions(DateTime date) async {
    final sessions = await _loadOrGenerate(date);
    if (mounted) setState(() => _selectedSessions = sessions);
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final entries = await TimetableService.fetchEntries();
      entries.sort((a, b) => a.start.compareTo(b.start));
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
        _listAnimCtrl.forward(from: 0);
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

  // ── Date selection ─────────────────────────────────────────────────────────

  void _selectDate(DateTime day) {
    final norm = DateTime(day.year, day.month, day.day);
    setState(() {
      _selectedDate = norm;
      _selectedSessions = [];
    });
    _scrollController.jumpTo(0);
    _listAnimCtrl.forward(from: 0);
    _loadSessions(norm);
  }

  // ── Calendar helpers ───────────────────────────────────────────────────────

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isSel(DateTime d) =>
      d.year == _selectedDate.year &&
      d.month == _selectedDate.month &&
      d.day == _selectedDate.day;

  bool _hasApiEntry(DateTime d) => _entries.any((e) =>
      e.start.year == d.year &&
      e.start.month == d.month &&
      e.start.day == d.day);

  // ── Timeline data ──────────────────────────────────────────────────────────

  List<_ScheduleItem> get _todayItems {
    final items = <_ScheduleItem>[];
    for (int i = 0; i < _selectedSessions.length; i++) {
      items.add(_HardcodedItem(_selectedSessions[i], i, _selectedDate));
    }
    for (final e in _entries) {
      final d = DateTime(e.start.year, e.start.month, e.start.day);
      if (d == _selectedDate) {
        items.add(_ApiItem(e));
      }
    }
    items.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return items;
  }

  // ── Edit a session for the selected date ───────────────────────────────────

  void _showEditSheet(int sessionIndex) {
    final session = _selectedSessions[sessionIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSessionSheet(
        initialName: session.name,
        initialStart: session.startTime,
        initialEnd: session.endTime,
        onSave: (newName, newStart, newEnd) async {
          final updated = List<DateSession>.from(_selectedSessions);
          updated[sessionIndex] = session.copyWith(
            name: newName,
            startHour: newStart.hour,
            startMinute: newStart.minute,
            endHour: newEnd.hour,
            endMinute: newEnd.minute,
          );
          await _persistSessions(_selectedDate, updated);
          if (mounted) setState(() => _selectedSessions = updated);
        },
      ),
    );
  }

  // ── Formatting ─────────────────────────────────────────────────────────────

  String _fmt(int h, int m) {
    final p = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${m.toString().padLeft(2, '0')} $p';
  }

  String _fmtDt(DateTime t) => _fmt(t.hour, t.minute);

  String _monthName(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m - 1];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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
                _buildCalendarSection(),
                _buildDivider(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          FloatingBottomNavbar(
            currentIndex: widget.initialNavIndex,
            onTap: widget.onNavTap,
          ),
        ],
      ),
    );
  }

  // ── Calendar ───────────────────────────────────────────────────────────────

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header lives OUTSIDE the card (title + nav arrows, always static)
          _buildCalendarHeader(),
          const SizedBox(height: 10),
          // ── Neumorphic card shell (static, never moves) ──────────────────
          // ClipRRect hard-clips the sliding content to the card radius so
          // the outer Container's box shadows are never clipped.
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  offset: const Offset(6, 6),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
                const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-6, -6),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedSize(
                // Smoothly animates height when switching between months
                // that have different numbers of weeks (5-row vs 6-row).
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 340),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    // Entering child: key == _calendarMonth → slides in.
                    // Exiting child: old key → animation reverses 1→0 so
                    //   begin/end flip → slides out the opposite direction.
                    final isEntering =
                        child.key == ValueKey(_calendarMonth);
                    final dir =
                        isEntering ? _calendarSlideDir : -_calendarSlideDir;
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(dir.toDouble(), 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  // KeyedSubtree wraps BOTH day-labels AND the grid so the
                  // entire card interior slides as one cohesive piece.
                  child: KeyedSubtree(
                    key: ValueKey(_calendarMonth),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDayLabels(),
                          const SizedBox(height: 8),
                          _buildCalendarGrid(),
                        ],
                      ),
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

  Widget _buildCalendarHeader() {
    return Row(
      children: [
        Text(
          '${_monthName(_calendarMonth.month)} ${_calendarMonth.year}',
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _NavBtn(
          isLeft: true,
          onTap: () => setState(() {
            _calendarSlideDir = -1; // entering from left
            _calendarMonth =
                DateTime(_calendarMonth.year, _calendarMonth.month - 1);
          }),
        ),
        const SizedBox(width: 6),
        _NavBtn(
          isLeft: false,
          onTap: () => setState(() {
            _calendarSlideDir = 1; // entering from right
            _calendarMonth =
                DateTime(_calendarMonth.year, _calendarMonth.month + 1);
          }),
        ),
      ],
    );
  }

  Widget _buildDayLabels() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: labels
          .map((l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      color:
                          AppTheme.descriptionTextColor.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final dim = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final offset =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday - 1;

    final cells = <Widget>[
      for (int i = 0; i < offset; i++) const SizedBox.shrink(),
      for (int d = 1; d <= dim; d++)
        _buildDayCell(DateTime(_calendarMonth.year, _calendarMonth.month, d)),
    ];

    // Pad to complete final row
    final rem = cells.length % 7;
    if (rem != 0) {
      for (int i = 0; i < 7 - rem; i++) {
        cells.add(const SizedBox.shrink());
      }
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children:
            cells.sublist(i, i + 7).map((c) => Expanded(child: c)).toList(),
      ));
      if (i + 7 < cells.length) rows.add(const SizedBox(height: 5));
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // ← fix for overflow
      children: rows,
    );
  }

  Widget _buildDayCell(DateTime day) {
    final sel = _isSel(day);
    final today = _isToday(day);
    final hasEntry = _hasApiEntry(day);

    // ── Colour logic ──────────────────────────────────────────────────────────
    // selected  → primary forest green  (overrides everything)
    // today     → soft gold accent tint  (distinct from selected)
    // hasEntry  → raised outward (standard neumorphic)
    // no entry  → pressed inward (inverted neumorphic)

    final Color bgColor;
    if (sel) {
      bgColor = AppTheme.primaryColor;
    } else if (today) {
      bgColor = AppTheme.accentColor.withValues(alpha: 0.18);
    } else if (hasEntry) {
      bgColor = AppTheme.backgroundColor;
    } else {
      bgColor = const Color(0xFFE2E2D5); // slightly darker = sunken
    }

    final List<BoxShadow> shadows;
    if (sel) {
      // Glow outward in primary
      shadows = [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.38),
          offset: const Offset(0, 5),
          blurRadius: 12,
          spreadRadius: -1,
        ),
      ];
    } else if (today) {
      // Golden glow outward
      shadows = [
        BoxShadow(
          color: AppTheme.accentColor.withValues(alpha: 0.45),
          offset: const Offset(0, 5),
          blurRadius: 12,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(3, 3),
          blurRadius: 6,
        ),
        const BoxShadow(
          color: AppTheme.buttonHighlightColor,
          offset: Offset(-3, -3),
          blurRadius: 6,
        ),
      ];
    } else if (hasEntry) {
      // Raised outward – has a study session scheduled
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          offset: const Offset(3, 3),
          blurRadius: 7,
          spreadRadius: -1,
        ),
        const BoxShadow(
          color: AppTheme.buttonHighlightColor,
          offset: Offset(-3, -3),
          blurRadius: 7,
          spreadRadius: -1,
        ),
      ];
    } else {
      // Pressed inward – ZERO outer shadows, inner effect via gradient overlay
      shadows = [];
    }

    // ── Text colour ───────────────────────────────────────────────────────────
    final Color textCol;
    if (sel) {
      textCol = Colors.white;
    } else if (today) {
      textCol = AppTheme.accentColor.withValues(alpha: 0.9);
    } else if (hasEntry) {
      textCol = AppTheme.textColor;
    } else {
      textCol = AppTheme.descriptionTextColor.withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: () => _selectDate(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(2.5),
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(11),
          border: today && !sel
              ? Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.55),
                  width: 1.5)
              : null,
          boxShadow: shadows,
        ),
        // ClipRRect keeps the inner gradient from bleeding outside the cell
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // True inner shadow via PathFillType.evenOdd — exact same
              // technique used by the navbar's selected-icon indicator.
              // A large outer rect is drawn with a hole cut at the shadow
              // offset; evenOdd fill makes only the "frame" visible; blur
              // bleeds inward, never outside the ClipRRect.
              if (!sel && !today && !hasEntry)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CellInnerShadowPainter(
                      borderRadius: BorderRadius.circular(11),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          offset: const Offset(4, 4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                        const BoxShadow(
                          color: AppTheme.buttonHighlightColor,
                          offset: Offset(-4, -4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              // Day number on top
              Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textCol,
                    fontSize: 13,
                    fontWeight: (sel || today || hasEntry)
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: SpinKitCubeGrid(color: AppTheme.secondaryColor, size: 42.0),
      );
    }
    if (_error != null) return _buildError();
    return _buildTimeline();
  }

  Widget _buildTimeline() {
    final items = _todayItems;
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final isToday = _isToday(_selectedDate);
    final dayLabel = dayNames[_selectedDate.weekday - 1];

    return CustomRefreshIndicator(
      onRefresh: _fetchEntries,
      builder: (context, child, controller) => Stack(
        alignment: Alignment.topCenter,
        children: [
          if (!controller.isIdle)
            Positioned(
              top: 28.0 * controller.value,
              child: const SpinKitCubeGrid(
                  color: AppTheme.secondaryColor, size: 28.0),
            ),
          Transform.translate(
            offset: Offset(0, 65.0 * controller.value),
            child: child,
          ),
        ],
      ),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Day info header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? 'TODAY' : dayLabel.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.descriptionTextColor
                              .withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_selectedDate.day}',
                            style: const TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isToday
                                ? dayLabel
                                : _monthName(_selectedDate.month),
                            style: TextStyle(
                              color: AppTheme.descriptionTextColor
                                  .withValues(alpha: 0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} sessions',
                      style: TextStyle(
                        color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (items.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_available_rounded,
                        color: Color(0x449EAF9C), size: 52),
                    SizedBox(height: 14),
                    Text('No sessions on this day',
                        style: TextStyle(
                            color: AppTheme.descriptionTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 160),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final item = items[i];
                    final isFirst = i == 0;
                    final isLast = i == items.length - 1;
                    final key =
                        ValueKey('${_selectedDate.millisecondsSinceEpoch}_$i');

                    final isStudy = item is _ApiItem;

                    Widget card;
                    if (item is _HardcodedItem) {
                      card = _HardcodedCard(
                        session: item.session,
                        fmt: _fmt,
                        onEdit: () => _showEditSheet(item.sessionIndex),
                      );
                    } else {
                      final api = item as _ApiItem;
                      card = _ApiCard(
                        entry: api.entry,
                        fmtEntry: _fmtDt,
                      );
                    }

                    // Timeline row wrapper
                    return _AnimatedCard(
                      key: key,
                      index: i,
                      parentController: _listAnimCtrl,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Timeline indicator ─────────────────────────
                            SizedBox(
                              width: 26,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Vertical connecting line
                                  Positioned(
                                    top: isFirst ? 26.0 : 0,
                                    bottom: isLast ? null : 0,
                                    height: isLast ? 26.0 : null,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        width: 1.5,
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.18),
                                      ),
                                    ),
                                  ),
                                  // Dot
                                  Positioned(
                                    top: 24,
                                    child: Container(
                                      width: isStudy ? 11 : 9,
                                      height: isStudy ? 11 : 9,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isStudy
                                            ? AppTheme.primaryColor
                                            : AppTheme.backgroundColor,
                                        border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withValues(
                                                  alpha: isStudy ? 1.0 : 0.45),
                                          width: isStudy ? 0 : 2,
                                        ),
                                        boxShadow: isStudy
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.primaryColor
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // ── Card ───────────────────────────────────────
                            Expanded(child: card),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Error & divider ─────────────────────────────────────────────────────────

  Widget _buildDivider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 22),
        color: AppTheme.descriptionTextColor.withValues(alpha: 0.10),
      );

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
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.descriptionTextColor,
                    fontSize: 14,
                    height: 1.5)),
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
                        blurRadius: 8),
                    const BoxShadow(
                        color: AppTheme.buttonHighlightColor,
                        offset: Offset(-4, -4),
                        blurRadius: 8),
                  ],
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final int index;
  final AnimationController parentController;
  final Widget child;

  const _AnimatedCard({
    super.key,
    required this.index,
    required this.parentController,
    required this.child,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void didUpdateWidget(_AnimatedCard old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index ||
        old.parentController != widget.parentController) {
      _setupAnimations();
    }
  }

  void _setupAnimations() {
    final start = min(0.07 * widget.index, 0.55).toDouble();
    final end = min(start + 0.50, 1.0);
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.parentController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.parentController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hardcoded session card  — neutral neumorphic, reference-image style
// ─────────────────────────────────────────────────────────────────────────────

class _HardcodedCard extends StatelessWidget {
  final DateSession session;
  final String Function(int h, int m) fmt;
  final VoidCallback onEdit;

  const _HardcodedCard({
    required this.session,
    required this.fmt,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final desc = _sessionDesc(session.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            offset: const Offset(4, 4),
            blurRadius: 10,
            spreadRadius: -2,
          ),
          const BoxShadow(
            color: AppTheme.buttonHighlightColor,
            offset: Offset(-3, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        session.name,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fmt(session.startHour, session.startMinute),
                      style: TextStyle(
                        color: AppTheme.descriptionTextColor
                            .withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppTheme.descriptionTextColor
                          .withValues(alpha: 0.50),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Edit icon
          GestureDetector(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 1),
              child: Icon(
                Icons.edit_outlined,
                size: 15,
                color: AppTheme.descriptionTextColor.withValues(alpha: 0.30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API study session card  — highlighted in primaryColor (forest green)
// ─────────────────────────────────────────────────────────────────────────────

class _ApiCard extends StatelessWidget {
  final TimetableEntry entry;
  final String Function(DateTime) fmtEntry;

  const _ApiCard({
    required this.entry,
    required this.fmtEntry,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = entry.done;
    final duration = entry.end.difference(entry.start).inMinutes;
    // Done sessions fade to neutral; active sessions pop in primaryColor
    final bg = isDone ? AppTheme.backgroundColor : AppTheme.primaryColor;
    final textPrimary = isDone ? AppTheme.textColor : Colors.white;
    final textSub = isDone
        ? AppTheme.descriptionTextColor.withValues(alpha: 0.50)
        : Colors.white.withValues(alpha: 0.68);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDone
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
                const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-3, -3),
                  blurRadius: 8,
                ),
              ]
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + time row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        entry.topic.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationColor: textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fmtEntry(entry.start),
                      style: TextStyle(
                        color: textSub,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Subtitle row
                Row(
                  children: [
                    Text(
                      'Study Session · ${duration}m',
                      style: TextStyle(
                        color: textSub,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _PriorityBadge(
                      priority: entry.topic.priority,
                      onDark: !isDone,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Done checkmark
          if (isDone)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppTheme.lightGreen,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Study',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Edit session bottom sheet  ← proper StatefulWidget, fixes TextEditingController bug
// ─────────────────────────────────────────────────────────────────────────────

class _EditSessionSheet extends StatefulWidget {
  final String initialName;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final Future<void> Function(String name, TimeOfDay start, TimeOfDay end)
      onSave;

  const _EditSessionSheet({
    required this.initialName,
    required this.initialStart,
    required this.initialEnd,
    required this.onSave,
  });

  @override
  State<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends State<_EditSessionSheet> {
  late final TextEditingController _nameCtrl;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _startTime = widget.initialStart;
    _endTime = widget.initialEnd;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmtTOD(TimeOfDay t) {
    final p = t.hour >= 12 ? 'PM' : 'AM';
    int h = t.hour % 12;
    if (h == 0) h = 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} $p';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppTheme.descriptionTextColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Edit Session',
              style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          // Name
          _Label('Session Name'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.primaryColor.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          // Time pickers
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Start Time'),
                    const SizedBox(height: 6),
                    _TimeTile(
                      label: _fmtTOD(_startTime),
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: _startTime);
                        if (t != null) setState(() => _startTime = t);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('End Time'),
                    const SizedBox(height: 6),
                    _TimeTile(
                      label: _fmtTOD(_endTime),
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: _endTime);
                        if (t != null) setState(() => _endTime = t);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Save button
          GestureDetector(
            onTap: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    final name = _nameCtrl.text.trim().isNotEmpty
                        ? _nameCtrl.text.trim()
                        : widget.initialName;
                    await widget.onSave(name, _startTime, _endTime);
                    if (mounted) Navigator.pop(context);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _saving
                    ? AppTheme.primaryColor.withValues(alpha: 0.6)
                    : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.28),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Text(
                _saving ? 'Saving…' : 'Save Changes',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final int priority;
  final bool onDark;
  const _PriorityBadge({required this.priority, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final labels = {1: 'Low', 2: 'Med', 3: 'High'};
    // On a dark (green) background show lighter, semi-transparent tints
    final colors = onDark
        ? {1: Colors.white, 2: Colors.white, 3: Colors.white}
        : {
            1: AppTheme.lightGreen,
            2: AppTheme.accentColor,
            3: AppTheme.highlightColor,
          };
    final label = labels[priority] ?? 'P$priority';
    final color = colors[priority] ?? AppTheme.descriptionTextColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: onDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final bool isLeft;
  final VoidCallback onTap;
  const _NavBtn({required this.isLeft, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.11),
                  offset: const Offset(3, 3),
                  blurRadius: 7),
              const BoxShadow(
                  color: AppTheme.buttonHighlightColor,
                  offset: Offset(-3, -3),
                  blurRadius: 7),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: isLeft ? pi : 0,
              child: Image.asset(
                'assets/icons/right_arrow.png',
                width: 18,
                height: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            color: AppTheme.descriptionTextColor.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600),
      );
}

class _TimeTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Icon(Icons.access_time_rounded,
                  size: 15,
                  color: AppTheme.primaryColor.withValues(alpha: 0.45)),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────────
// Cell inner-shadow painter  — same PathFillType.evenOdd algorithm
// as the navbar's _InnerShadowPainter, adapted for RRect (rounded square).
// ─────────────────────────────────────────────────────────────────────────────────
//
// How it works (identical to navbar's technique):
//
//   1. clip canvas to the rounded-rect shape
//   2. for each BoxShadow:
//        a. build a path = huge outer rect  +  hole (the RRect shifted by
//           the shadow offset and inflated by spreadRadius)
//        b. PathFillType.evenOdd makes only the "frame" between outer rect
//           and hole filled
//        c. blur on that frame bleeds INWARD into the hole → inner shadow
//
//          frame              hole (shifted)
//      ┌──────────────┐
//      │ ░░░ ........ │
//      │ ░░░ . hole  │     blur(frame) → bleeds into hole
//      │ ........... │
//      └──────────────┘

class _CellInnerShadowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  const _CellInnerShadowPainter({
    required this.borderRadius,
    required this.shadows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // ── 1. Clip canvas to the rounded-square boundary ──────────────────
    canvas.clipPath(Path()..addRRect(rrect));

    // ── 2. Draw each shadow as an evenOdd "frame" ──────────────────────
    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      // Hole = same shape shifted by the shadow offset + spread inflation.
      // Because we clip to the rrect, only the inward-bleeding blur is visible.
      final holeRRect = borderRadius.toRRect(
        rect.shift(shadow.offset).inflate(shadow.spreadRadius),
      );

      final path = Path()
        ..addRect(rect.inflate(shadow.blurRadius * 5)) // huge outer frame
        ..addRRect(holeRRect) // hole via evenOdd
        ..fillType = PathFillType.evenOdd;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CellInnerShadowPainter old) =>
      old.borderRadius != borderRadius || old.shadows != shadows;
}
