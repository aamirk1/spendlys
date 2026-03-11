import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusinessProfileController extends GetxController {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final gstController = TextEditingController();
  
  final bankNameController = TextEditingController();
  final accountNoController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  void saveProfile() {
    // Logic to call API
    Get.back();
    Get.snackbar("Success", "Business Profile Updated");
  }
}

class BusinessProfileView extends StatelessWidget {
  const BusinessProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessProfileController());

    return Scaffold(
      appBar: AppBar(title: const Text("Business Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("General Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            _buildTextField(controller.nameController, "Business Name"),
            _buildTextField(controller.addressController, "Address", maxLines: 3),
            _buildTextField(controller.phoneController, "Phone", keyboardType: TextInputType.phone),
            _buildTextField(controller.emailController, "Email", keyboardType: TextInputType.emailAddress),
            _buildTextField(controller.gstController, "GST Number (Optional)"),
            
            const SizedBox(height: 30),
            const Text("Payment Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            _buildTextField(controller.upiController, "UPI ID"),
            _buildTextField(controller.bankNameController, "Bank Name"),
            _buildTextField(controller.accountNoController, "Account Number"),
            _buildTextField(controller.ifscController, "IFSC Code"),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("SAVE PROFILE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
