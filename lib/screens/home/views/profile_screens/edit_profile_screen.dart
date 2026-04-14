import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/edit_profile_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/utils/validators.dart';

class EditProfileScreen extends StatelessWidget {
  final MyUser myUser;
  const EditProfileScreen({super.key, required this.myUser});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController(myUser: myUser));

    return Scaffold(
      backgroundColor: Get.isDarkMode ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('customer_profile_update'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Get.isDarkMode ? Colors.white : Colors.black87,
        centerTitle: true,
      ),
      body: Obx(() => Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildSectionCard([
                        _buildTextField(
                          controller: controller.nameController,
                          label: 'full_name'.tr,
                          icon: Icons.person_outline_rounded,
                          validator: (v) =>
                              Validators.requiredField(v, 'full_name'.tr),
                        ),
                        _buildTextField(
                          controller: controller.emailController,
                          label: 'email'.tr,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.emailValidator,
                        ),
                      ]),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('save'.tr,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
          filled: true,
          fillColor: Get.isDarkMode ? Colors.black26 : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Get.theme.primaryColor, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
