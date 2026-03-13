import 'package:flutter/material.dart';

/// A reusable widget that renders a trailing parallax background
/// with adaptively mirrored geometric layers.
class ParallaxBackground extends StatelessWidget {
  final double scrollOffset;
  final double overscrollAllowance;
  final double screenHeight;

  const ParallaxBackground({
    super.key,
    required this.scrollOffset,
    required this.overscrollAllowance,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Determine a safe maximum height the background layers need to cover.
    // If we assume a safe max scroll offset of ~4000px, 
    // at a 0.5 parallax factor, the background moves up by 2000px.
    // So the total required layer height is screenHeight + 2000.
    final requiredHeight = screenHeight + 2000 + overscrollAllowance;

    return Stack(
      children: List.generate(6, (index) {
        final imageNumber = index + 1;
        
        // ALL layers must move at the exact same physical speed (targetY) so seams align perfectly.
        const parallaxFactor = 0.5;
        
        // Start shifted up by overscroll allowance.
        double targetY = -overscrollAllowance - (scrollOffset * parallaxFactor);
        
        // Hard clamp so if the user overscrolls to the top, it doesn't reveal the raw background.
        targetY = targetY > 0 ? 0 : targetY;

        // "Train bogies" delay effect: lower layers snap instantly, higher layers trail slower.
        final trailingDurationMs = 100 + (index * 250);

        return AnimatedPositioned(
          duration: Duration(milliseconds: trailingDurationMs),
          curve: Curves.easeOutQuad,
          top: targetY,
          left: -20, // Optional slight horizontal bleed
          right: -20,
          child: _AdaptiveMirroredImage(
            imagePath: 'assets/images/home/$imageNumber.png',
            requiredHeight: requiredHeight,
          ),
        );
      }),
    );
  }
}

class _AdaptiveMirroredImage extends StatelessWidget {
  final String imagePath;
  final double requiredHeight;

  const _AdaptiveMirroredImage({
    required this.imagePath,
    required this.requiredHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // We are using `BoxFit.fitWidth`, meaning the image exactly fits the width.
        // We roughly estimate the geometric image height based on the device width.
        // Assuming a standard aspect ratio around 1:1 to 4:3, using maxWidth is a safe bet.
        final estimatedImageHeight = constraints.maxWidth;
        
        // Calculate the exact number of copies needed to seamlessly cover the parallax travel.
        // We clamp to a maximum of 8 so we aren't generating infinite off-screen widgets.
        final copiesNeeded = (requiredHeight / (estimatedImageHeight > 0 ? estimatedImageHeight : 1)).ceil().clamp(1, 8);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(copiesNeeded, (repIndex) {
            return Transform.scale(
              scaleY: repIndex.isEven ? 1 : -1,
              child: Image.asset(
                imagePath,
                fit: BoxFit.fitWidth,
                // Ensure the textures properly stitch together at their respective top/bottom edges
                alignment: repIndex.isEven
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
              ),
            );
          }),
        );
      },
    );
  }
}
