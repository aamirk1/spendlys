import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/colors.dart';

class PremiumDialogs {
  static void showPremiumRequiredDialog({String? message}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildDialogContent(message: message),
      ),
    );
  }

  static Widget _buildDialogContent({String? message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              size: 64,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Premium Feature",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message ??
                "This is a premium feature. Upgrade now to unlock professional branding and unlimited exports.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.toNamed(RoutesName.premiumView);
            },
            text: "UPGRADE TO PREMIUM",
            fontSize: 16,
            height: 54,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Continue With Free",
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
