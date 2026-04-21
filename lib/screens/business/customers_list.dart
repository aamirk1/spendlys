import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/validators.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/utils/business_export_helper.dart';
import 'package:spendly/widgets/premium_dialogs.dart';

class CustomersController extends GetxController {
  final customers = [].obs;
  final isLoading = false.obs;
  
  // For adding
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    
    isLoading.value = true;
    try {
      final response = await ApiService.get('/business/customers', headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        customers.value = jsonDecode(response.body);
      } else if (response.statusCode == 400 && response.body.contains("business profile first")) {
        // Not configured yet
        Utils.showSnackbar("Setup Required", "Please complete your Business Profile first.", isError: true);
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load customers: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer() async {
    if (!formKey.currentState!.validate()) return;
    
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.back(); // Close bottom sheet
    isLoading.value = true;
    try {
      final response = await ApiService.post(
        '/business/customers',
        headers: {'Content-Type': 'application/json', 'x-user-id': userId},
        body: {
          "name": nameController.text.trim(),
          "phone": phoneController.text.trim(),
          "email": emailController.text.trim(),
          "address": addressController.text.trim(),
        }
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Customer added successfully", isError: false);
        nameController.clear();
        phoneController.clear();
        emailController.clear();
        addressController.clear();
        fetchCustomers();
      } else {
        Utils.showSnackbar("Error", "Failed to add customer: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

class CustomersListView extends StatelessWidget {
  const CustomersListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers & Clients", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: "Export PDF",
            onPressed: () => _handleExport(context, controller, isPdf: true),
          ),
          IconButton(
            icon: const Icon(Icons.table_view_rounded),
            tooltip: "Export CSV",
            onPressed: () => _handleExport(context, controller, isPdf: false),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showAddCustomerSheet(context, controller),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Customer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value && controller.customers.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.indigo));
            }
            if (controller.customers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off_rounded, size: 80, color: Colors.indigo.withOpacity(0.5)),
                    const SizedBox(height: 20),
                    const Text("No customers added yet.", style: TextStyle(fontSize: 18, color: Colors.black54)),
                  ],
                ),
              );
            }
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10).copyWith(bottom: 80),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.customers.length,
                itemBuilder: (context, index) {
                  final cust = controller.customers[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildCustomerCard(cust),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, CustomersController controller, {required bool isPdf}) async {
    final paymentController = Get.put(PaymentController());
    if (!paymentController.isPremium.value) {
      PremiumDialogs.showPremiumRequiredDialog(
        message: "Exporting customer details is a premium feature. Upgrade now to unlock professional branding and unlimited exports."
      );
      return;
    }

    if (controller.customers.isEmpty) {
      Utils.showSnackbar("No Data", "There are no customers to export.");
      return;
    }

    Utils.showLoadingDialog();

    try {
      if (isPdf) {
        final pdfData = await BusinessExportHelper.generatePdfData(
          type: BusinessExportType.customers,
          data: controller.customers,
        );
        Get.back(); // Close loading dialog
        await BusinessExportHelper.showPrintPreview(pdfData, BusinessExportType.customers);
      } else {
        final csvPath = await BusinessExportHelper.generateCsvFile(
          type: BusinessExportType.customers,
          data: controller.customers,
        );
        Get.back(); // Close loading dialog
        await BusinessExportHelper.showShareSheet(csvPath, BusinessExportType.customers);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Utils.showSnackbar("Error", "Export failed: $e");
    }
  }

  Widget _buildCustomerCard(dynamic cust) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.indigo.withOpacity(0.1),
            child: Text(
              cust['name'] != null && cust['name'].toString().isNotEmpty ? cust['name'][0].toUpperCase() : "?",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cust['name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                if (cust['phone'] != null && cust['phone'].toString().isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text(cust['phone'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                if (cust['email'] != null && cust['email'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 14, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(cust['email'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Outstanding", style: TextStyle(fontSize: 10, color: Colors.redAccent)),
              Text(
                "₹${cust['pending_amount'] ?? '0.0'}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showAddCustomerSheet(BuildContext context, CustomersController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add New Customer", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller.nameController,
                  validator: (v) => Validators.requiredField(v, "Name"),
                  decoration: _inputDeco("Full Name", Icons.person_rounded),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco("Phone (Optional)", Icons.phone_rounded),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco("Email (Optional)", Icons.email_rounded),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: controller.addressController,
                  maxLines: 2,
                  decoration: _inputDeco("Address (Optional)", Icons.location_on_rounded),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.addCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("SAVE CUSTOMER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      prefixIcon: Icon(icon, color: Colors.indigo),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
    );
  }
}
