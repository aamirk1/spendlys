import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';

class RadialMenuOverlay extends StatefulWidget {
  final MyUser myUser;

  const RadialMenuOverlay({super.key, required this.myUser});

  @override
  State<RadialMenuOverlay> createState() => _RadialMenuOverlayState();
}

class _RadialMenuOverlayState extends State<RadialMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final double _menuRadius = 120.0;
  final double _buttonSize = 56.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closeMenu() {
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final double cx = size.width / 2;
    // Position center higher to leave space for bottom bar and the bottom labels
    final double cy = size.height - 180 - bottomPadding;

    final List<RadialMenuItem> menuItems = [
      RadialMenuItem(
        label: 'income'.tr,
        icon: Icons.file_download_outlined,
        color: Colors.green,
        angle: 7 * math.pi / 6, // 210 degrees (left-top)
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) {
              Navigator.of(context).pop();
              Get.toNamed(RoutesName.incomeExpenseHome,
                  arguments: {'initialIndex': 0});
            }
          });
        },
      ),
      RadialMenuItem(
        label: 'expense'.tr,
        icon: CupertinoIcons.arrow_up,
        color: Colors.redAccent,
        angle: 5 * math.pi / 6, // 150 degrees (left-bottom)
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) {
              Navigator.of(context).pop();
              Get.toNamed(RoutesName.incomeExpenseHome,
                  arguments: {'initialIndex': 1});
            }
          });
        },
      ),
      RadialMenuItem(
        label: 'create_invoice'.tr,
        icon: Icons.receipt_long_outlined,
        color: Colors.orange,
        angle: -math.pi / 2, // -90 degrees (top)
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) {
              Navigator.of(context).pop();
              Get.toNamed(RoutesName.createInvoice);
            }
          });
        },
      ),
      RadialMenuItem(
        label: 'Group Splits',
        icon: CupertinoIcons.person_3_fill,
        color: Colors.deepPurple,
        angle: -math.pi / 6, // -30 degrees (right-top)
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) {
              Navigator.of(context).pop();
              Get.toNamed(RoutesName.groupSplitList);
            }
          });
        },
      ),
      RadialMenuItem(
        label: 'lent_borrowed'.tr,
        icon: Icons.handshake_outlined,
        color: Colors.blueAccent,
        angle: math.pi / 6, // 30 degrees (right-bottom)
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) {
              Navigator.of(context).pop();
              Get.toNamed(RoutesName.addLoanScreen, arguments: widget.myUser);
            }
          });
        },
      ),
      RadialMenuItem(
        label: 'create_quotation'.tr,
        icon: Icons.request_quote_outlined,
        color: Colors.cyan,
        angle: math.pi / 2, // 90 degrees (bottom)
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) {
              Navigator.of(context).pop();
              Get.toNamed(RoutesName.createQuotation);
            }
          });
        },
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closeMenu();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double animVal = _controller.value;
            final double scaleVal = _scaleAnimation.value;

            return Stack(
              children: [
                // Backdrop glassmorphism blur and tap-to-dismiss background
                GestureDetector(
                  onTap: _closeMenu,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 5.0 * animVal,
                      sigmaY: 5.0 * animVal,
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0.7 * animVal),
                    ),
                  ),
                ),

                // Dotted and solid concentric circles passing through button centers
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: RadialMenuPainter(
                        animationValue: animVal,
                        radius: _menuRadius,
                        cx: cx,
                        cy: cy,
                      ),
                    ),
                  ),
                ),

                // Outer Radial Buttons and their badges
                ...menuItems.expand((item) {
                  final double r = _menuRadius * scaleVal;
                  final double x = r * math.cos(item.angle);
                  final double y = r * math.sin(item.angle);

                  final double buttonLeft = cx + x - (_buttonSize / 2);
                  final double buttonTop = cy + y - (_buttonSize / 2);

                  Widget badgeChild = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.transparent),
                    ),
                  );

                  const double spacing = 6.0;
                  final double opacity =
                      math.max(0.0, math.min(1.0, (scaleVal - 0.3) / 0.7));

                  return [
                    // 1. The Button Positioned
                    Positioned(
                      left: buttonLeft,
                      top: buttonTop,
                      child: Transform.scale(
                        scale: scaleVal,
                        child: GestureDetector(
                          onTap: item.onTap,
                          child: Container(
                            width: _buttonSize,
                            height: _buttonSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.color,
                              boxShadow: [
                                BoxShadow(
                                  color: item.color.withOpacity(0.4 * animVal),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. The Label Badge Positioned directly below the button
                    if (scaleVal > 0.3)
                      Positioned(
                        left: cx + x,
                        top: cy + y + (_buttonSize / 2) + spacing,
                        child: Opacity(
                          opacity: opacity,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0.0),
                            child: badgeChild,
                          ),
                        ),
                      ),
                  ];
                }),

                // Center close button positioned at the middle (overlapping the FAB position)
                Positioned(
                  left: cx - 30,
                  top: cy - 30,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * math.pi,
                    child: Transform.scale(
                      scale: scaleVal,
                      child: GestureDetector(
                        onTap: _closeMenu,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [cs.tertiary, cs.secondary, cs.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3 * animVal),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RadialMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final double angle;
  final VoidCallback onTap;

  RadialMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.angle,
    required this.onTap,
  });
}

class RadialMenuPainter extends CustomPainter {
  final double animationValue;
  final double radius;
  final double cx;
  final double cy;

  RadialMenuPainter({
    required this.animationValue,
    required this.radius,
    required this.cx,
    required this.cy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(cx, cy);

    final outerPaint = Paint()
      ..color = Colors.purple.withOpacity(0.15 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final currentRadius = radius * animationValue;
    canvas.drawCircle(center, currentRadius, outerPaint);

    final innerPaint = Paint()
      ..color = Colors.purple.withOpacity(0.2 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final innerRadius = radius * 0.6 * animationValue;
    _drawDashedCircle(canvas, center, innerRadius, innerPaint);
  }

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, Paint paint) {
    if (radius <= 0) return;
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    final double circumference = 2 * math.pi * radius;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashWidth + dashSpace)) / radius;
      final double sweepAngle = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RadialMenuPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.radius != radius ||
        oldDelegate.cx != cx ||
        oldDelegate.cy != cy;
  }
}
