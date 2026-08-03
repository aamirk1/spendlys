import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/app/modules/business/controllers/business_profile_controller.dart';

class BusinessProfileView extends StatelessWidget {
  const BusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: SafeArea(
          child: Obx(() => Stack(
                children: [
                  Form(
                    key: controller.formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: AnimationLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 600),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 60.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              Center(
                                child: GestureDetector(
                                  onTap: controller.pickLogo,
                                  child: Obx(() => Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.blue.withValues(alpha: 0.1),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            )
                                          ],
                                          image: controller.pickedLogo.value !=
                                                  null
                                              ? DecorationImage(
                                                  image: FileImage(controller
                                                      .pickedLogo.value!),
                                                  fit: BoxFit.cover,
                                                )
                                              : (controller.logoUrl.value !=
                                                      null
                                                  ? DecorationImage(
                                                      image: NetworkImage(() {
                                                        String url = controller
                                                            .logoUrl.value!;
                                                        if (!url.startsWith(
                                                            'http')) {
                                                          url =
                                                              "https://dailybachatapi.serwex.in$url";
                                                        }
                                                        String connector =
                                                            url.contains('?')
                                                                ? '&'
                                                                : '?';
                                                        return "$url${connector}t=${DateTime.now().millisecondsSinceEpoch}";
                                                      }()),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null),
                                        ),
                                        child: controller.pickedLogo.value ==
                                                    null &&
                                                controller.logoUrl.value == null
                                            ? const Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 40,
                                                color: Colors.blueAccent)
                                            : null,
                                      )),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  "Business Logo (Optional)",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildSectionTitle("General Information"),
                              _buildCard(
                                children: [
                                  _buildTextField(
                                    controller: controller.nameController,
                                    label: "Business Name",
                                    icon: Icons.store_rounded,
                                    validator: (v) => Validators.requiredField(
                                        v, "Business Name"),
                                  ),
                                  _buildTextField(
                                    controller: controller.addressController,
                                    label: "Address",
                                    icon: Icons.location_on_rounded,
                                    maxLines: 3,
                                    validator: (v) =>
                                        Validators.requiredField(v, "Address"),
                                  ),
                                  _buildTextField(
                                    controller: controller.phoneController,
                                    label: "Phone",
                                    icon: Icons.phone_rounded,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    validator: Validators.mobileValidator,
                                  ),
                                  _buildTextField(
                                    controller: controller.emailController,
                                    label: "Email",
                                    icon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: Validators.emailValidator,
                                  ),
                                  _buildTextField(
                                    controller: controller.gstController,
                                    label: "GST Number (Optional)",
                                    icon: Icons.receipt_long_rounded,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(15),
                                      UpperCaseTextFormatter(),
                                    ],
                                    validator: Validators.gstValidator,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              _buildSectionTitle("Payment Details"),
                              _buildCard(
                                children: [
                                  _buildTextField(
                                    controller: controller.upiController,
                                    label: "UPI ID",
                                    icon: Icons.qr_code_rounded,
                                    validator: (v) =>
                                        Validators.requiredField(v, "UPI ID"),
                                  ),
                                  _buildDropdownField(controller),
                                  _buildTextField(
                                    controller: controller.accountNoController,
                                    label: "Account Number",
                                    icon: Icons.account_balance_wallet_rounded,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    validator:
                                        Validators.accountNumberValidator,
                                  ),
                                  _buildTextField(
                                    controller: controller.ifscController,
                                    label: "IFSC Code",
                                    icon: Icons.account_balance_rounded,
                                    inputFormatters: [UpperCaseTextFormatter()],
                                    validator: Validators.ifscValidator,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 35),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    elevation: 8,
                                    shadowColor:
                                        Colors.blueAccent.withValues(alpha: 0.4),
                                  ),
                                  child: const Text(
                                    "SAVE PROFILE",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (controller.isLoading.value)
                    Container(
                      color: Colors.white.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      ),
                    ),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.blueAccent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDropdownField(BusinessProfileController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Obx(() => DropdownButtonFormField<String>(
            initialValue: controller.selectedBank.value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Bank Name",
              prefixIcon:
                  const Icon(Icons.account_balance, color: Colors.blueAccent),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
              ),
            ),
            items: controller.bankNames.map((bank) {
              return DropdownMenuItem(
                value: bank,
                child: Text(bank, style: const TextStyle(fontSize: 15)),
              );
            }).toList(),
            onChanged: (value) {
              controller.selectedBank.value = value;
            },
            validator: (value) =>
                value == null ? 'Bank Name is required' : null,
          )),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        cursorColor: Colors.blueAccent,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              maxLines == 1 ? Icon(icon, color: Colors.blueAccent) : null,
          alignLabelWithHint: maxLines > 1,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
