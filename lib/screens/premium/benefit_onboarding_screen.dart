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
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );

    Future.delayed(
        const Duration(milliseconds: 100), () => _headerController.forward());
    Future.delayed(
        const Duration(milliseconds: 350), () => _listController.forward());
    Future.delayed(
        const Duration(milliseconds: 700), () => _cardController.forward());
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
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _bgController, size: size),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              SlideTransition(
                                position: _headerSlide,
                                child: FadeTransition(
                                  opacity: _headerFade,
                                  child: _buildHeader(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildBenefitsList(),
                              const SizedBox(height: 16),
                            ],
                          ),
                          Column(
                            children: [
                              ScaleTransition(
                                scale: _cardScale,
                                child: _buildSubscriptionCard(),
                              ),
                              const SizedBox(height: 16),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnim,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFE066), Color(0xFFFF9F00), Color(0xFFFFE066)],
          ).createShader(bounds),
          child: const Text(
            "Go Premium",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Unlock the full power of Spendly and take control of your finances.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withOpacity(0.55),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    final defaultGradients = [
      [const Color(0xFF00B2E7), const Color(0xFF0077B6)],
      [const Color(0xFFE064F7), const Color(0xFF9B27AF)],
      [const Color(0xFF00E5CC), const Color(0xFF009688)],
      [const Color(0xFFFF8D6C), const Color(0xFFE64A19)],
    ];

    return Obx(() {
      if (_paymentController.isLoading.value &&
          _paymentController.premiumFeatures.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Color(0xFFFF9F00)),
          ),
        );
      }

      final features = _paymentController.premiumFeatures;
      final displayFeatures = features.isEmpty
          ? [
              _BenefitData(
                icon: Icons.auto_graph_rounded,
                title: "Share Invoices & Receipts",
                subtitle: "Share Invoices & Receipts with your clients.",
                gradient: defaultGradients[0],
              ),
              _BenefitData(
                icon: Icons.chat_bubble_rounded,
                title: "Send Reminders",
                subtitle: "Send Reminders to your clients via WhatsApp.",
                gradient: defaultGradients[1],
              ),
              _BenefitData(
                icon: Icons.picture_as_pdf_rounded,
                title: "PDF / CSV Reports",
                subtitle: "Export data for easy tax and expense filing.",
                gradient: defaultGradients[1],
              ),
              _BenefitData(
                icon: Icons.cloud_done_rounded,
                title: "Cloud Backup",
                subtitle: "Never lose your data with real-time sync.",
                gradient: defaultGradients[2],
              ),
              _BenefitData(
                icon: Icons.block_rounded,
                title: "Ad-Free Experience",
                subtitle: "Enjoy a clean interface without interruptions.",
                gradient: defaultGradients[3],
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

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: displayFeatures.length,
        itemBuilder: (context, index) {
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
          );
        },
      );
    });
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE066), Color(0xFFFF9F00), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1B35)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "BEST VALUE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Lifetime Access",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 11, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      Text(
                        "One-time payment + 3% platform fee",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Obx(
                  () => ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                    ).createShader(bounds),
                    child: Text(
                      "₹${_paymentController.premiumAmount.value}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                Text(
                  "one time",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            _paymentController
                .initiateOrder(_paymentController.premiumAmount.value);
          },
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE066), Color(0xFFFF9F00)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9F00).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.lock_open_rounded,
                    color: Color(0xFF1A1A1A), size: 18),
                SizedBox(width: 8),
                Text(
                  "UPGRADE NOW",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _completeOnboarding,
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05)
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "CONTINUE WITH FREE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
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
                Color(0xFF0A1628),
                Color(0xFF0D1F3C),
                Color(0xFF0A0F1E),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60 + (t * 30),
                left: -80 + (t * 20),
                child: _Orb(
                  size: 240,
                  color: const Color(0xFFFF9F00).withOpacity(0.08),
                ),
              ),
              Positioned(
                bottom: -80 + (t * -20),
                right: -60 + (t * 15),
                child: _Orb(
                  size: 260,
                  color: const Color(0xFF00B2E7).withOpacity(0.07),
                ),
              ),
              Positioned(
                top: size.height * 0.4 + (t * 15),
                left: size.width * 0.25,
                child: _Orb(
                  size: 150,
                  color: const Color(0xFFE064F7).withOpacity(0.04),
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

  const _AnimatedBenefitItem({
    required this.animation,
    required this.data,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(20 * (1 - animation.value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 0.7,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data.gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: data.gradient.first.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(data.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.45),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: data.gradient,
                ),
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
