import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/screens/add_lend_borrow/loan_detail_screen.dart';
import 'package:spendly/utils/colors.dart';

class BorrowScreen extends StatelessWidget {
  const BorrowScreen({super.key, required this.controller});
  final LoanController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.borrowed.isEmpty
        ? Center(
            child: Center(
            child: Text("No borrowed loans",
                style: TextStyle(color: AppColors.red)),
          ))
        : ListView.builder(
            itemCount: controller.borrowed.length,
            itemBuilder: (context, index) {
              final loan = controller.borrowed[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(loan.personName,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "₹${loan.amount} • Due: ${loan.expectedReturnDate != null ? DateFormat.yMMMd().format(loan.expectedReturnDate!) : 'N/A'}",
                    style: TextStyle(fontSize: 16, color: AppColors.grey),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text("Delete Loan"),
                          content: const Text(
                              "Are you sure you want to delete this loan?"),
                          backgroundColor: AppColors.red50,
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(Get.context!,
                                            rootNavigator: true)
                                        .pop();
                                  },
                                  child: const Text("Cancel"),
                                ),
                                CustomButton(
                                  text: "Yes, Delete",
                                  onPressed: () async {
                                    await controller.deleteLoan(loan.id);
                                    // Close dialog reliably
                                    Navigator.of(Get.context!,
                                            rootNavigator: true)
                                        .pop();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.delete_forever,
                        color: AppColors.red, size: 28),
                  ),
                  onTap: () => Get.to(() =>
                      LoanDetailScreen(loan: loan, controller: controller)),
                ),
              );
            },
          ));
  }
}
