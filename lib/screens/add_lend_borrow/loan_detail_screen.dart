import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/customBotton.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/payment_history_card.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/colors.dart';
import 'add_loan_screen.dart';
import 'package:spendly/models/myuser.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final LoanController controller;

  LoanDetailScreen({required this.loan, required this.controller, super.key});

  final paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "loan_details".tr,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Get.to(() => AddLoanScreen(
                  myUser: MyUser(
                      userId: loan.userId,
                      name: '',
                      email: '',
                      phoneNumber: '',
                      lastLogin: loan.date.millisecondsSinceEpoch.toString()
                          as dynamic), // Mock user with ID
                  controller: controller,
                  loan: loan, // Pass the loan to enable edit mode
                )),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuickActions(context),
                  const SizedBox(height: 25),
                  PaymentHistoryCard(loan: loan),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Obx(() {
            final remaining = loan.amount - loan.paidAmount.value;
            final percentagePaid =
                loan.amount > 0 ? (loan.paidAmount.value / loan.amount) : 0.0;
            final clampedPercentage = percentagePaid.clamp(0.0, 1.0);

            return CircularPercentIndicator(
              radius: 100.0,
              lineWidth: 12.0,
              percent: clampedPercentage,
              animation: true,
              animateFromLastPercent: true,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: Colors.white.withOpacity(0.1),
              progressColor:
                  remaining == 0 ? Colors.greenAccent : Colors.orangeAccent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "balance_due".tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "₹${NumberFormat('#,##,###').format(remaining)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _headerInfoItem("total_loan".tr,
                    "₹${NumberFormat('#,###').format(loan.amount)}"),
                Container(width: 1, height: 30, color: Colors.white24),
                _headerInfoItem(
                    "due_date".tr,
                    loan.expectedReturnDate != null
                        ? DateFormat('dd MMM').format(loan.expectedReturnDate!)
                        : 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerInfoItem(String title, String value) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "quick_actions".tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                "record_payment".tr,
                Icons.add_card,
                Colors.indigo.shade50,
                Colors.indigo,
                () => _showPaymentSheet(context),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _actionButton(
                "pay_full".tr,
                Icons.check_circle,
                Colors.green.shade50,
                Colors.green,
                () => _markAsFullyPaid(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color bg, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    final amountController = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "record_payment".tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "enter_amount_hint".tr,
                prefixText: "₹ ",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),
            CustomButton(
              text: "record_payment".tr,
              onPressed: () {
                final amt = double.tryParse(amountController.text);
                if (amt != null && amt > 0) {
                  controller.updatePayment(loan.id, amt);
                  Get.back();
                } else {
                  Utils.showSnackbar("error".tr, "enter_amount_hint".tr);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _markAsFullyPaid(BuildContext context) {
    final remaining = loan.amount - loan.paidAmount.value;
    if (remaining <= 0) {
      Utils.showSnackbar("info".tr, "loan_fully_paid_msg".tr);
      return;
    }

    Get.dialog(
      AlertDialog(
        title: Text("clear_full_balance".tr),
        content: Text("clear_balance_desc".tr +
            "₹${NumberFormat('#,###').format(remaining)}."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("cancel_btn".tr)),
          TextButton(
            onPressed: () {
              controller.updatePayment(loan.id, remaining);
              Get.back();
            },
            child: Text("confirm_btn".tr),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text("delete_record_title".tr),
        content: Text("delete_record_desc".tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("cancel_btn".tr)),
          TextButton(
            onPressed: () {
              controller.deleteLoan(loan.id);
              Get.back(); // Close dialog
              Get.back(); // Go back to list
            },
            child: Text("delete_btn".tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
