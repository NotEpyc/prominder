import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class NeumorphicTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const NeumorphicTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base flat background
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        // Authentic Inner shadows (Inset)
        Positioned.fill(
          child: CustomPaint(
            painter: _InnerShadowPainter(
              borderRadius: 28,
              shadows: [
                // Top-Left Inset (Dark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(2, 2),
                  blurRadius: 3,
                  spreadRadius: 1, // Minimize spread into the center
                ),
                // Bottom-Right Inset (Light)
                BoxShadow(
                  color: Colors.white,
                  offset: const Offset(-2, -2),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        // Text input overlay
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            textAlignVertical: TextAlignVertical.center,
            obscuringCharacter: '●', // Uses a perfectly symmetrical dot 
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: obscureText ? 2.0 : 0.0,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppTheme.descriptionTextColor.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0, // Maintain zero letter spacing for placeholder
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: suffixIcon,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final double borderRadius;
  final List<BoxShadow> shadows;

  _InnerShadowPainter({
    required this.borderRadius,
    required this.shadows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Clip rendering strictly strictly boundary of the textfield
    canvas.clipRRect(rrect);

    for (var shadow in shadows) {
      final shadowPaint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      final holeRect = rrect.shift(shadow.offset).inflate(shadow.spreadRadius);

      final shadowPath = Path()
        ..addRect(rect.inflate(shadow.blurRadius * 5)) // Much larger bounds to avoid cutting shadow
        ..addRRect(holeRect); // Cutout the shape offset in shadow direction

      // Using evenOdd fills the gap. Since it's blurred, the blur bleeds inwards into our clipped rrect.
      canvas.drawPath(shadowPath..fillType = PathFillType.evenOdd, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) => true;
}
