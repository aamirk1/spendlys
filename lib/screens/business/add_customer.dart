import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/screens/business/customers_list.dart';
import 'package:spendly/utils/validators.dart';

class AddCustomerView extends StatefulWidget {
  const AddCustomerView({super.key});

  @override
  State<AddCustomerView> createState() => _AddCustomerViewState();
}

class _AddCustomerViewState extends State<AddCustomerView> {
  late final CustomersController controller;
  late final Map<String, dynamic>? customer;
  late final bool isEdit;
  final Color primaryColor = const Color(0xFF5F33E1);

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomersController>();
    customer = Get.arguments as Map<String, dynamic>?;
    isEdit = customer != null;

    if (isEdit) {
      controller.nameController.text = customer!['name'] ?? '';
      controller.phoneController.text = customer!['phone'] ?? '';
      controller.emailController.text = customer!['email'] ?? '';
      controller.addressController.text = customer!['address'] ?? '';
    } else {
      controller.nameController.clear();
      controller.phoneController.clear();
      controller.emailController.clear();
      controller.addressController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEdit ? "Edit Customer" : "New Customer",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Decorative header banner with premium design
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? "Edit Customer Details" : "Add New Customer",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEdit
                          ? "Keep this customer's details and billing information up to date."
                          : "Keep all your customer billing details and transaction history synced.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Customer Input Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Customer Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 1. Full Name Input
                        TextFormField(
                          controller: controller.nameController,
                          validator: (v) => Validators.requiredField(v, "Full Name"),
                          decoration: _inputDeco("Full Name", Icons.person_rounded, primaryColor),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),

                        // 2. Phone Input
                        TextFormField(
                          controller: controller.phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDeco("Phone (Optional)", Icons.phone_rounded, primaryColor),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),

                        // 3. Email Input
                        TextFormField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDeco("Email (Optional)", Icons.email_rounded, primaryColor),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),

                        // 4. Address Input
                        TextFormField(
                          controller: controller.addressController,
                          maxLines: 3,
                          decoration: _inputDeco("Address (Optional)", Icons.location_on_rounded, primaryColor),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save Customer Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isEdit) {
                        controller.updateCustomer(customer!['id'].toString());
                      } else {
                        controller.addCustomer();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isEdit ? Icons.edit_rounded : Icons.save_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? "UPDATE CUSTOMER" : "SAVE CUSTOMER",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAFF),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}
