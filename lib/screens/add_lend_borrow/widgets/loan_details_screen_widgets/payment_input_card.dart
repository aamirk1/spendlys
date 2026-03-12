import 'package:flutter/material.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/utils/utils.dart';

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
                      Utils.showSnackbar("Success", "Payment recorded!", isError: false);
                    });
                  } else {
                    Utils.showSnackbar("Error", "Invalid amount");
                  }
                } else if (loanId == null) {
                  Utils.showSnackbar("Error", "Loan ID is missing");
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
