import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Neumorphic alert type
enum NeumorphicAlertType { error, success, info }

/// Shows a neumorphic bottom-sheet style popup card.
/// Call this instead of SnackBar anywhere in the app.
Future<void> showNeumorphicAlert(
  BuildContext context, {
  required String title,
  required String message,
  NeumorphicAlertType type = NeumorphicAlertType.error,
  String buttonLabel = 'Got it',
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
    ),
    builder: (_) => _NeumorphicAlertSheet(
      title: title,
      message: message,
      type: type,
      buttonLabel: buttonLabel,
    ),
  );
}

class _NeumorphicAlertSheet extends StatelessWidget {
  final String title;
  final String message;
  final NeumorphicAlertType type;
  final String buttonLabel;

  const _NeumorphicAlertSheet({
    required this.title,
    required this.message,
    required this.type,
    required this.buttonLabel,
  });

  Color get _iconColor {
    switch (type) {
      case NeumorphicAlertType.error:
        return const Color(0xFFE05252);
      case NeumorphicAlertType.success:
        return const Color(0xFF52B788);
      case NeumorphicAlertType.info:
        return AppTheme.primaryColor;
    }
  }

  IconData get _icon {
    switch (type) {
      case NeumorphicAlertType.error:
        return Icons.cancel_outlined;
      case NeumorphicAlertType.success:
        return Icons.check_circle_outline;
      case NeumorphicAlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(0, -6),
            blurRadius: 24,
          ),
          const BoxShadow(
            color: AppTheme.buttonHighlightColor,
            offset: Offset(0, -1),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Neumorphic inset drag handle
          _NeumorphicHandle(),

          const SizedBox(height: 28),

          // Neumorphic icon circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
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
            child: Icon(
              _icon,
              color: _iconColor,
              size: 36,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 12),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.descriptionTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Neumorphic dismiss button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
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
              alignment: Alignment.center,
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
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

/// A small pill-shaped inset (pressed) neumorphic drag handle
class _NeumorphicHandle extends StatelessWidget {
  const _NeumorphicHandle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandlePainter(),
      child: const SizedBox(width: 56, height: 8),
    );
  }
}

class _HandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Base fill — same as card background
    final basePaint = Paint()..color = AppTheme.backgroundColor;
    canvas.drawRRect(rRect, basePaint);

    // Inner shadow algorithm identical to NeumorphicTextField
    canvas.clipRRect(rRect);

    final shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        offset: const Offset(1.5, 1.5),
        blurRadius: 2.0,
      ),
      BoxShadow(
        color: AppTheme.buttonHighlightColor.withValues(alpha: 0.9),
        offset: const Offset(-1.5, -1.5),
        blurRadius: 2.0,
      ),
    ];

    for (var shadow in shadows) {
      final shadowPaint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      final holeRect = rRect.shift(shadow.offset).inflate(shadow.spreadRadius);

      final shadowPath = Path()
        ..addRect(rect.inflate(shadow.blurRadius * 5))
        ..addRRect(holeRect);

      canvas.drawPath(shadowPath..fillType = PathFillType.evenOdd, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(_HandlePainter oldDelegate) => false;
}
