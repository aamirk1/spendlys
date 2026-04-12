import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/utils/utils.dart';

class FeedbackController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final messageController = TextEditingController();
  final rating = 5.obs;
  final category = 'General'.obs;
  final isLoading = false.obs;

  final List<String> categories = ['General', 'Bug', 'Suggestion', 'Other'];

  void setRating(int value) {
    rating.value = value;
  }

  void setCategory(String? value) {
    if (value != null) {
      category.value = value;
    }
  }

  Future<void> submitFeedback() async {
    if (messageController.text.trim().isEmpty) {
      Utils.showSnackbar("Error", "Please enter your feedback message");
      return;
    }

    try {
      isLoading.value = true;
      Utils.showLoadingDialog();

      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      await _apiClient.post(ApiConstants.feedback, data: {
        'user_id': user.uid,
        'rating': rating.value,
        'category': category.value,
        'message': messageController.text.trim(),
      });

      Get.back(); // Close loading dialog
      
      Utils.showSnackbar(
        "Thank You!", 
        "Your feedback has been submitted successfully.", 
        isError: false
      );
      
      // Clear fields
      messageController.clear();
      rating.value = 5;
      category.value = 'General';
      
      // Go back to previous screen after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        Get.back();
      });

    } catch (e) {
      if (Get.isOverlaysOpen) Get.back(); // Close loading dialog if open
      Utils.showSnackbar("Error", "Failed to submit feedback: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
