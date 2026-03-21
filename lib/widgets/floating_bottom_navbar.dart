import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class FloatingBottomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingBottomNavbar> createState() => _FloatingBottomNavbarState();
}

class _FloatingBottomNavbarState extends State<FloatingBottomNavbar>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  late AnimationController _buttonController;
  late AnimationController _itemsController;
  late Animation<double> _buttonRotation;
  late Animation<double> _itemsWidth;

  final List<NavItem> _navItems = [
    NavItem(icon: Icons.home_rounded, index: 0),
    NavItem(icon: Icons.bubble_chart_rounded, index: 1),
    NavItem(icon: Icons.calendar_month_rounded, index: 2),
    NavItem(icon: Icons.style_rounded, index: 3),
    NavItem(icon: Icons.person_rounded, index: 4),
  ];

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _itemsController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _buttonRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _itemsWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _itemsController,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  Future<void> _toggleMenu() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      await _buttonController.forward();
      await _itemsController.forward();
    } else {
      await _itemsController.reverse();
      await _buttonController.reverse();
    }
  }

  void _onItemTap(int index) {
    widget.onTap(index);
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    // Relative sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final navbarWidth = screenWidth * 0.9;
    const double navbarHeight = 80.0;
    const double bottomPadding = 32.0;
    const double iconSize = 24.0;
    const double menuButtonSize = 56.0;
    const double itemsContainerHeight = 60.0;

    return Positioned(
      bottom: bottomPadding,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: navbarWidth,
          height: navbarHeight,
          child: Stack(
            children: [
              // Items container
              AnimatedBuilder(
                animation: _itemsController,
                builder: (context, child) {
                  final itemsWidth =
                      (navbarWidth - menuButtonSize) * _itemsWidth.value;

                  if (_itemsController.value == 0) return const SizedBox();

                  return Positioned(
                    left: menuButtonSize * 0.75,
                    top: (navbarHeight - itemsContainerHeight) / 2,
                    height: itemsContainerHeight,
                    width: itemsWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(itemsContainerHeight / 2),
                          bottomRight: Radius.circular(
                            itemsContainerHeight / 2,
                          ),
                        ),
                        // Neumorphic shadow for the expanded container
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(4, 4),
                          ),
                          const BoxShadow(
                            color: AppTheme.buttonHighlightColor,
                            blurRadius: 15,
                            offset: Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(itemsContainerHeight / 2),
                          bottomRight: Radius.circular(
                            itemsContainerHeight / 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children:
                                _navItems.map((item) {
                                  final isSelected =
                                      widget.currentIndex == item.index;
                                  return Expanded(
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () => _onItemTap(item.index),
                                        behavior: HitTestBehavior.opaque,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOutCubic,
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? AppTheme.backgroundColor
                                                    : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: CustomPaint(
                                            painter:
                                                isSelected
                                                    ? _InnerShadowPainter(
                                                      shape: BoxShape.circle,
                                                      shadows: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.25,
                                                              ),
                                                          offset: const Offset(
                                                            4,
                                                            4,
                                                          ),
                                                          blurRadius: 3,
                                                          spreadRadius: 1,
                                                        ),
                                                        const BoxShadow(
                                                          color:
                                                              AppTheme
                                                                  .buttonHighlightColor,
                                                          offset: Offset(
                                                            -4,
                                                            -4,
                                                          ),
                                                          blurRadius: 3,
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    )
                                                    : null,
                                            child: Center(
                                              child: Icon(
                                                item.icon,
                                                color:
                                                    isSelected
                                                        ? AppTheme.primaryColor
                                                        : AppTheme
                                                            .descriptionTextColor,
                                                size: iconSize,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Button container
              AnimatedBuilder(
                animation: _buttonController,
                builder: (context, child) {
                  final buttonLeft =
                      (navbarWidth - menuButtonSize) /
                      2 *
                      (1 - _buttonController.value);

                  return Positioned(
                    left: buttonLeft,
                    top: (navbarHeight - menuButtonSize) / 2,
                    child: GestureDetector(
                      onTap: _toggleMenu,
                      child: Container(
                        width: menuButtonSize,
                        height: menuButtonSize,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          shape: BoxShape.circle,
                          // Neumorphic shadow for the toggle button
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(6, 6),
                            ),
                            const BoxShadow(
                              color: AppTheme.buttonHighlightColor,
                              blurRadius: 8,
                              offset: Offset(-6, -6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CustomPaint(
                              painter: _InnerShadowPainter(
                                isCross: _isExpanded,
                                isGrid: !_isExpanded,
                                fillColor: AppTheme.lightGreen,
                                rotationAngle:
                                    -_buttonRotation.value * 3.14159 * 2,
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    offset: const Offset(1.5, 1.5),
                                    blurRadius: 2,
                                    spreadRadius: 0.5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    offset: const Offset(-1.5, -1.5),
                                    blurRadius: 2,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final int index;

  NavItem({required this.icon, required this.index});
}

class _InnerShadowPainter extends CustomPainter {
  final BoxShape shape;
  final List<BoxShadow> shadows;
  final bool isCross;
  final bool isGrid;
  final Color? fillColor;
  final double rotationAngle;

  _InnerShadowPainter({
    this.shape = BoxShape.circle,
    required this.shadows,
    this.isCross = false,
    this.isGrid = false,
    this.fillColor,
    this.rotationAngle = 0.0,
  });

  Path _getCrossPath(Size size, double inflate) {
    double w = size.width + inflate * 2;
    double h = size.height + inflate * 2;
    double t = 4.0 + inflate * 2;
    if (w <= 0 || h <= 0 || t <= 0) return Path();

    final r1 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: w,
        height: t,
      ),
      Radius.circular(t / 2),
    );
    final r2 = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: t,
        height: h,
      ),
      Radius.circular(t / 2),
    );

    Path p1 = Path()..addRRect(r1);
    Path p2 = Path()..addRRect(r2);
    Path path = Path.combine(PathOperation.union, p1, p2);

    Matrix4 m =
        Matrix4.identity()
          ..translate(size.width / 2, size.height / 2)
          ..rotateZ(3.14159 / 4 + rotationAngle)
          ..translate(-size.width / 2, -size.height / 2);
    return path.transform(m.storage);
  }

  Path _getGridPath(Size size, double inflate) {
    Path path = Path();
    double sqSize = (size.width - 4.0) / 2.0;

    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 2; j++) {
        double x = i * (sqSize + 4.0);
        double y = j * (sqSize + 4.0);
        final rect = Rect.fromLTWH(
          x - inflate,
          y - inflate,
          sqSize + inflate * 2,
          sqSize + inflate * 2,
        );
        path.addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(2.0 + inflate)),
        );
      }
    }

    Matrix4 m =
        Matrix4.identity()
          ..translate(size.width / 2, size.height / 2)
          ..rotateZ(rotationAngle)
          ..translate(-size.width / 2, -size.height / 2);
    return path.transform(m.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    Path boundsPath = Path();
    if (isCross) {
      boundsPath = _getCrossPath(size, 0);
    } else if (isGrid) {
      boundsPath = _getGridPath(size, 0);
    } else if (shape == BoxShape.circle) {
      boundsPath.addOval(rect);
    }

    if (fillColor != null) {
      canvas.drawPath(boundsPath, Paint()..color = fillColor!);
    }

    canvas.clipPath(boundsPath);

    for (var shadow in shadows) {
      final shadowPaint =
          Paint()
            ..color = shadow.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      final holeRect = rect.shift(shadow.offset).inflate(shadow.spreadRadius);

      final shadowPath =
          Path()..addRect(
            rect.inflate(shadow.blurRadius * 5),
          ); // Much larger bounds to avoid cutting shadow

      if (isCross) {
        shadowPath.addPath(
          _getCrossPath(size, shadow.spreadRadius).shift(shadow.offset),
          Offset.zero,
        );
      } else if (isGrid) {
        shadowPath.addPath(
          _getGridPath(size, shadow.spreadRadius).shift(shadow.offset),
          Offset.zero,
        );
      } else if (shape == BoxShape.circle) {
        shadowPath.addOval(holeRect);
      }

      // Using evenOdd fills the gap. Since it's blurred, the blur bleeds inwards into our clipped bounds.
      canvas.drawPath(shadowPath..fillType = PathFillType.evenOdd, shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.shadows != shadows ||
        oldDelegate.isCross != isCross ||
        oldDelegate.isGrid != isGrid ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.rotationAngle != rotationAngle;
  }
}
