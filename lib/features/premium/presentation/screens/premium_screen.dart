import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/core/widgets/animated_press.dart';
import 'package:spendly/core/widgets/custom_button.dart';
import 'package:spendly/core/widgets/shimmer_loading.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentController());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
              Color(0xFF01579B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    AnimatedPress(
                      onTap: () => Get.back(),
                      child: const IgnorePointer(
                        child: IconButton(
                          onPressed: null,
                          icon: Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 10),
              const Icon(
                Icons.stars_rounded,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 10),
              const Text(
                'DailyBachat PREMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'Go beyond limits',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: AnimationLimiter(
                    child: Obx(() {
                      final bool showShimmer = controller.isLoading.value && controller.premiumFeatures.isEmpty;

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 40.0,
                            child: FadeInAnimation(
                              child: widget,
                            ),
                          ),
                          children: [
                            Center(
                              child: Text(
                                'Unlock Features',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (showShimmer) ...[
                              _buildShimmerFeatureItem(),
                              _buildShimmerFeatureItem(),
                              _buildShimmerFeatureItem(),
                              _buildShimmerFeatureItem(),
                            ] else ...[
                              ...controller.premiumFeatures.map((feature) => _buildFeatureItem(
                                    icon: _getIconData(feature.icon),
                                    title: feature.title,
                                    subtitle: feature.subtitle,
                                  )),
                            ],
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Choose Plan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: colorScheme.primary, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Annual Access',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'One-time payment + 3% platform fee',
                                          style: TextStyle(
                                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${controller.premiumAmount.value}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: controller.isPremium.value &&
                                      controller.remainingDays > 0
                                  ? '${controller.remainingDays} DAYS REMAINING'
                                  : 'UPGRADE NOW',
                              isLoading: controller.isLoading.value,
                              onPressed: controller.isPremium.value &&
                                      controller.remainingDays > 0
                                  ? null
                                  : () {
                                      controller.initiateOrder(
                                          controller.premiumAmount.value);
                                    },
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Secure payment via Razorpay',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildShimmerFeatureItem() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          ShimmerLoading(width: 48, height: 48, borderRadius: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 120, height: 16),
                SizedBox(height: 8),
                ShimmerLoading(width: 200, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
