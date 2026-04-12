import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/splash_controller.dart';
import 'package:spendly/utils/colors.dart';

class DailyBachatSplashScreen extends StatefulWidget {
  DailyBachatSplashScreen({super.key});

  @override
  State<DailyBachatSplashScreen> createState() =>
      _DailyBachatSplashScreenState();
}

class _DailyBachatSplashScreenState extends State<DailyBachatSplashScreen>
    with TickerProviderStateMixin {
  // Background orb oscillation
  late final AnimationController _bgController;

  // Logo pulse (same as sign-in)
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Logo + text entry
  late final AnimationController _entryController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineFade;

  // Progress bar
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    Get.put(SplashController());

    // Slow background oscillation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Gentle pulse (identical to sign-in)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Entry animations
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.65, 1.0, curve: Curves.easeOut)),
    );

    // Progress bar fills over splash duration (~2.5 s)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    // Start entry animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Dark gradient background ────────────────────────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: const [
                    Color(0xFF0A0E27),
                    Color(0xFF0D1B3E),
                    Color(0xFF0A1628),
                  ],
                  stops: [0.0, 0.5 + _bgController.value * 0.2, 1.0],
                ),
              ),
            ),
          ),

          // ── Animated orbs ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, __) => Stack(
              children: [
                _orb(
                  dx: size.width * 0.85 +
                      math.sin(_bgController.value * math.pi * 2) * 30,
                  dy: size.height * 0.12 +
                      math.cos(_bgController.value * math.pi * 2) * 20,
                  radius: 170,
                  color: AppColors.primary.withOpacity(0.15),
                ),
                _orb(
                  dx: size.width * 0.1 +
                      math.cos(_bgController.value * math.pi * 2) * 25,
                  dy: size.height * 0.75 +
                      math.sin(_bgController.value * math.pi * 2) * 18,
                  radius: 140,
                  color: AppColors.secondary.withOpacity(0.1),
                ),
                _orb(
                  dx: size.width * 0.5,
                  dy: size.height * 0.5 +
                      math.sin(_bgController.value * math.pi) * 20,
                  radius: 90,
                  color: AppColors.tertiary.withOpacity(0.07),
                ),
              ],
            ),
          ),

          // ── Floating particles ──────────────────────────────────────
          ...List.generate(
              8, (i) => _SplashParticle(index: i, ctrl: _bgController)),

          // ── Central content ─────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing logo — identical treatment to sign-in screen
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.55),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logos/logo.png',
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // App name
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                          AppColors.tertiary,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'DailyBachat',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // masked by shader
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: const Text(
                    'Smart Money Management',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white38,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 52),

                // Slim animated progress bar
                FadeTransition(
                  opacity: _textFade,
                  child: SizedBox(
                    width: 140,
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 3,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(
          {required double dx,
          required double dy,
          required double radius,
          required Color color}) =>
      Positioned(
        left: dx - radius,
        top: dy - radius,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
}

// ── Reusable floating particle ─────────────────────────────────────────────
class _SplashParticle extends StatefulWidget {
  final int index;
  final AnimationController ctrl;

  const _SplashParticle({required this.index, required this.ctrl});

  @override
  State<_SplashParticle> createState() => _SplashParticleState();
}

class _SplashParticleState extends State<_SplashParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late double _x, _y, _size;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.index * 17 + 3);
    _x = rng.nextDouble();
    _y = rng.nextDouble();
    _size = rng.nextDouble() * 4 + 2;
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      Colors.white,
    ];
    _color = colors[widget.index % colors.length].withOpacity(0.28);
    _c = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5 + rng.nextInt(5)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final offset = math.sin(_c.value * math.pi * 2 + widget.index) * 18;
        return Positioned(
          left: _x * size.width,
          top: _y * size.height + offset,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              boxShadow: [
                BoxShadow(color: _color.withOpacity(0.5), blurRadius: 6)
              ],
            ),
          ),
        );
      },
    );
  }
}
