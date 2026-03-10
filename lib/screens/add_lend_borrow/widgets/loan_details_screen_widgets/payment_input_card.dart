import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/utils/colors.dart';

class PaymentInputCard extends StatelessWidget {
  const PaymentInputCard({super.key, required this.controller, this.loanId});
  final LoanController controller;
  final String? loanId;
  @override
  Widget build(BuildContext context) {
    return buildPaymentInputCard(controller: controller, loanId: loanId);
  }

  Widget buildPaymentInputCard(
      {required LoanController controller, String? loanId}) {
    final paymentController = TextEditingController();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Payment Amount",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon:
                    const Icon(Icons.currency_rupee, color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: "Mark as Paid",
              onPressed: () {
                if (paymentController.text.isNotEmpty && loanId != null) {
                  final paymentAmount = double.tryParse(paymentController.text);
                  if (paymentAmount != null && paymentAmount > 0) {
                    controller.updatePayment(loanId, paymentAmount).then((_) {
                      paymentController.clear();
                      Get.snackbar("Success", "Payment recorded!",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.shade100,
                          colorText: Colors.green.shade800,
                          borderRadius: 10,
                          margin: const EdgeInsets.all(15));
                    });
                  } else {
                    Get.snackbar("Error", "Invalid amount",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade800,
                        borderRadius: 10,
                        margin: const EdgeInsets.all(15));
                  }
                } else if (loanId == null) {
                  Get.snackbar("Error", "Loan ID is missing",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade100,
                      colorText: Colors.red.shade800,
                      borderRadius: 10,
                      margin: const EdgeInsets.all(15));
                }
              },
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              fontSize: 17,
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
