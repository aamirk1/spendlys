import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/utils/utils.dart';

class EditProfileController extends GetxController {
  final MyUser myUser;
  EditProfileController({required this.myUser});

  late TextEditingController nameController;
  late TextEditingController emailController;
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: myUser.name);
    emailController = TextEditingController(text: myUser.email);
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myUser.userId)
          .update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
      });

      Utils.showSnackbar("Success", "Profile updated successfully", isError: false);
      Get.back(result: true); // Return true to indicate update happened
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to update profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
