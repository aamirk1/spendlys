import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/models/myuser.dart';

class BenefitOnboardingScreen extends StatefulWidget {
  const BenefitOnboardingScreen({super.key});

  @override
  State<BenefitOnboardingScreen> createState() =>
      _BenefitOnboardingScreenState();
}

class _BenefitOnboardingScreenState extends State<BenefitOnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _headerController;
  late AnimationController _listController;
  late AnimationController _cardController;
  late AnimationController _pulseController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardScale;
  late Animation<double> _pulseAnim;

  late PaymentController _paymentController;

  @override
  void initState() {
    super.initState();
    _paymentController = Get.put(PaymentController());

    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );

    Future.delayed(
        const Duration(milliseconds: 50), () => _headerController.forward());
    Future.delayed(
        const Duration(milliseconds: 200), () => _listController.forward());
    Future.delayed(
        const Duration(milliseconds: 450), () => _cardController.forward());
  }

  @override
  void dispose() {
    _bgController.dispose();
    _headerController.dispose();
    _listController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgController, size: size),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adaptive height sizing for compact vs tall screens
                final isCompact = constraints.maxHeight < 640;

                final content = Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: isCompact ? 6 : 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar with branding badge and close button
                      _buildTopBar(),

                      // Hero Header (Crown badge + Title + Subtitle)
                      SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: _buildHeader(isCompact: isCompact),
                        ),
                      ),

                      // Benefits List (5 sleek compact feature items)
                      _buildBenefitsList(isCompact: isCompact),

                      // Subscription Pricing Card
                      ScaleTransition(
                        scale: _cardScale,
                        child: _buildSubscriptionCard(isCompact: isCompact),
                      ),

                      // Action Buttons (Upgrade Now CTA + Continue Free text)
                      _buildActionButtons(isCompact: isCompact),
                    ],
                  ),
                );

                // If screen is extremely short (e.g. landscape / split screen), protect against overflow
                if (constraints.maxHeight < 500) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: content,
                    ),
                  );
                }

                // Default for all standard mobile screens: 100% fit without scrolling
                return SizedBox(
                  height: constraints.maxHeight,
                  width: double.infinity,
                  child: content,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Sleek top bar with a Pro pill tag and dismiss button
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.35),
              width: 0.8,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                size: 13,
                color: Color(0xFFFFD700),
              ),
              SizedBox(width: 5),
              Text(
                "SPENDLY PRO",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFD700),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _completeOnboarding,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 17,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  /// Compact high-impact hero header
  Widget _buildHeader({required bool isCompact}) {
    final iconOuterSize = isCompact ? 46.0 : 52.0;
    final iconInnerSize = isCompact ? 38.0 : 42.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: iconOuterSize,
                height: iconOuterSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: iconInnerSize,
                height: iconInnerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9F00).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: isCompact ? 20 : 23,
                  color: const Color(0xFF141824),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isCompact ? 6 : 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFE066), Color(0xFFFF9F00)],
          ).createShader(bounds),
          child: Text(
            "Unlock Premium Access",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 20 : 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Get complete access to all exclusive tools & features",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isCompact ? 11 : 12,
            color: Colors.white.withOpacity(0.55),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Compact list of features designed to fit comfortably without vertical scrolling
  Widget _buildBenefitsList({required bool isCompact}) {
    final defaultGradients = [
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)], // Cyan -> Blue
      [const Color(0xFF25D366), const Color(0xFF128C7E)], // WhatsApp Emerald
      [const Color(0xFFA855F7), const Color(0xFF7C3AED)], // Purple -> Indigo
      [const Color(0xFF38BDF8), const Color(0xFF0284C7)], // Sky Blue
      [const Color(0xFFFF7A00), const Color(0xFFFF416C)], // Coral -> Pink
    ];

    return Obx(() {
      if (_paymentController.isLoading.value &&
          _paymentController.premiumFeatures.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: Color(0xFFFF9F00)),
          ),
        );
      }

      final features = _paymentController.premiumFeatures;
      final displayFeatures = features.isEmpty
          ? [
              _BenefitData(
                icon: Icons.receipt_long_rounded,
                title: "Share Invoices & Receipts",
                subtitle: "Direct PDF sharing with your clients",
                gradient: defaultGradients[0],
              ),
              _BenefitData(
                icon: Icons.chat_bubble_rounded,
                title: "WhatsApp Reminders",
                subtitle: "Automated payment follow-ups & alerts",
                gradient: defaultGradients[1],
              ),
              _BenefitData(
                icon: Icons.picture_as_pdf_rounded,
                title: "PDF & CSV Export Reports",
                subtitle: "Fast data export for taxes and accounting",
                gradient: defaultGradients[2],
              ),
              _BenefitData(
                icon: Icons.cloud_done_rounded,
                title: "Real-Time Cloud Backup",
                subtitle: "Never lose your data with automatic sync",
                gradient: defaultGradients[3],
              ),
              _BenefitData(
                icon: Icons.block_rounded,
                title: "100% Ad-Free Experience",
                subtitle: "Enjoy a clean interface without interruptions",
                gradient: defaultGradients[4],
              ),
            ]
          : features.asMap().entries.map((entry) {
              final idx = entry.key;
              final f = entry.value;
              return _BenefitData(
                icon: _getIconData(f.icon),
                title: f.title,
                subtitle: f.subtitle,
                gradient: defaultGradients[idx % defaultGradients.length],
              );
            }).toList();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(displayFeatures.length, (index) {
          final itemAnim = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _listController,
              curve: Interval(
                (index / displayFeatures.length) * 0.4,
                math.min((index / displayFeatures.length) * 0.4 + 0.6, 1.0),
                curve: Curves.easeOutCubic,
              ),
            ),
          );

          return _AnimatedBenefitItem(
            animation: itemAnim,
            data: displayFeatures[index],
            index: index,
            isCompact: isCompact,
          );
        }),
      );
    });
  }

  /// Streamlined and punchy Lifetime subscription card
  Widget _buildSubscriptionCard({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE066),
            Color(0xFFFF9F00),
            Color(0x55FF6B6B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F00).withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCompact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14243C), Color(0xFF0C1626)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "BEST VALUE • LIFETIME",
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF141824),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Lifetime Access",
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "One-time payment • No recurring fees",
                        style: TextStyle(
                          fontSize: isCompact ? 9 : 9.5,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                    ).createShader(bounds),
                    child: Text(
                      "₹${_paymentController.premiumAmount.value}",
                      style: TextStyle(
                        fontSize: isCompact ? 23 : 25,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                Text(
                  "one-time",
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Compact action buttons placed side-by-side in a single row
  Widget _buildActionButtons({required bool isCompact}) {
    final btnHeight = isCompact ? 44.0 : 48.0;

    return Row(
      children: [
        // Secondary Action: Free version
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _completeOnboarding,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: btnHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  "Continue Free",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Primary Action: Upgrade Now
        Expanded(
          flex: 3,
          child: Obx(() {
            final isLoading = _paymentController.isLoading.value;
            final amount = _paymentController.premiumAmount.value;

            return GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      _paymentController.initiateOrder(amount);
                    },
              child: Container(
                height: btnHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9F00).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF141824),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF141824),
                              size: 19,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "UPGRADE • ₹$amount",
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF141824),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _completeOnboarding() {
    final box = GetStorage();
    box.write("benefitOnboardingShown", true);
    bool isLoggedIn = box.read("isLoggedIn") ?? false;
    if (isLoggedIn) {
      Get.offAllNamed(RoutesName.homeView, arguments: MyUser.fromStorage());
    } else {
      Get.offAllNamed(RoutesName.loginView);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'auto_graph_rounded':
        return Icons.auto_graph_rounded;
      case 'receipt_long_rounded':
        return Icons.receipt_long_rounded;
      case 'chat_bubble_rounded':
        return Icons.chat_bubble_rounded;
      case 'picture_as_pdf_rounded':
        return Icons.picture_as_pdf_rounded;
      case 'cloud_done_rounded':
        return Icons.cloud_done_rounded;
      case 'block_rounded':
        return Icons.block_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      case 'workspace_premium_rounded':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.stars_rounded;
    }
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _AnimatedBackground({
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF070B14),
                Color(0xFF0D172A),
                Color(0xFF070B14),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50 + (t * 25),
                left: -60 + (t * 20),
                child: _Orb(
                  size: 200,
                  color: const Color(0xFFFF9F00).withOpacity(0.09),
                ),
              ),
              Positioned(
                bottom: -60 + (t * -20),
                right: -50 + (t * 15),
                child: _Orb(
                  size: 220,
                  color: const Color(0xFF00B2E7).withOpacity(0.08),
                ),
              ),
              Positioned(
                top: size.height * 0.45 + (t * 15),
                left: size.width * 0.25,
                child: _Orb(
                  size: 130,
                  color: const Color(0xFFA855F7).withOpacity(0.05),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _BenefitData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _BenefitData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _AnimatedBenefitItem extends StatelessWidget {
  final Animation<double> animation;
  final _BenefitData data;
  final int index;
  final bool isCompact;

  const _AnimatedBenefitItem({
    required this.animation,
    required this.data,
    required this.index,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = isCompact ? 26.0 : 29.0;
    final iconGlyphSize = isCompact ? 14.0 : 16.0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(16 * (1 - animation.value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 5 : 6),
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: isCompact ? 4.5 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: Colors.white.withOpacity(0.035),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data.gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.gradient.first.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                color: Colors.white,
                size: iconGlyphSize,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 9.5 : 10.5,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: isCompact ? 16 : 18,
              height: isCompact ? 16 : 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withOpacity(0.12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.check,
                size: isCompact ? 10 : 11,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
