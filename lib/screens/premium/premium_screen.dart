import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/res/components/custom_button.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentController());

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.stars_rounded,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              const Text(
                'SPENDLY PREMIUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
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
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Unlock Features',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFeatureItem(
                        icon: Icons.auto_graph_rounded,
                        title: 'Advanced Analytics',
                        subtitle: 'Detailed insights into your spending patterns.',
                      ),
                      _buildFeatureItem(
                        icon: Icons.picture_as_pdf_rounded,
                        title: 'Custom Invoices',
                        subtitle: 'Add your logo and branding to all exports.',
                      ),
                      _buildFeatureItem(
                        icon: Icons.cloud_done_rounded,
                        title: 'Cloud Backup',
                        subtitle: 'Never lose your data with automatic sync.',
                      ),
                      _buildFeatureItem(
                        icon: Icons.block_rounded,
                        title: 'Ad-Free Experience',
                        subtitle: 'Focus on your finances without distractions.',
                      ),
                      const Spacer(),
                      const Text(
                        'Choose Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lifetime Access',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text('One-time payment'),
                              ],
                            ),
                            Obx(() => Text(
                              '₹${controller.premiumAmount.value}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(() => CustomButton(
                            text: controller.isPremium.value
                                ? 'ALREADY PREMIUM'
                                : 'UPGRADE NOW',
                            isLoading: controller.isLoading.value,
                            onPressed: controller.isPremium.value
                                ? null
                                : () {
                                    controller.initiateOrder(
                                        controller.premiumAmount.value);
                                  },
                          )),
                      const SizedBox(height: 16),
                      const Text(
                        'Secure payment via Razorpay',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue[800]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
