import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/colors.dart';

class BusinessDialogs {
  static void showProfileRequiredDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildDialogContent(),
      ),
      barrierDismissible: false,
    );
  }

  static Widget _buildDialogContent() {
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
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_center_rounded,
              size: 64,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Business Profile Required",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Please create your business profile first to manage invoices, quotations, customers, and inventory.",
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
              Get.toNamed(RoutesName.businessProfile);
            },
            text: "CREATE BUSINESS PROFILE",
            backgroundColor: Colors.blueAccent,
            fontSize: 14,
            height: 54,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "LATER",
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
