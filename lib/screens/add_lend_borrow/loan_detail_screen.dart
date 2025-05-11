import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/screens/add_lend_borrow/loan_modal.dart';
import 'loan_controller.dart';
import 'package:intl/intl.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final LoanController controller;

  LoanDetailScreen({required this.loan, required this.controller, Key? key})
      : super(key: key);

  final paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loan.personName,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Section
              _buildAmountSection(),

              SizedBox(height: 16),

              // Remaining Amount Section
              _buildRemainingAmountSection(),

              SizedBox(height: 16),

              // Due Date and Reason Section
              _buildDueDateAndReason(),

              SizedBox(height: 24),

              // Payment Input
              _buildPaymentInput(),

              SizedBox(height: 24),

              // Mark Payment Button
              _buildMarkPaymentButton(),

              SizedBox(height: 32),

              // Payment History Section
              _buildPaymentHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Text(
      "Amount: ₹${loan.amount}",
      style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: Colors.deepPurple),
    );
  }

  Widget _buildRemainingAmountSection() {
    return Obx(() {
      final remainingAmount = loan.amount - loan.paidAmount.value;
      final percentagePaid = (loan.paidAmount.value / loan.amount) * 100;

      final isPaidBeforeDue = loan.expectedReturnDate != null &&
          DateTime.now().isBefore(loan.expectedReturnDate!);
      final isPaidAfterDue = loan.expectedReturnDate != null &&
          DateTime.now().isAfter(loan.expectedReturnDate!);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Remaining: ₹$remainingAmount",
            style: TextStyle(
              fontSize: 18,
              color: remainingAmount == 0
                  ? Colors.green
                  : percentagePaid >= 50
                      ? Colors.amber
                      : Colors.red,
            ),
          ),
          if (isPaidBeforeDue)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Paid before due date!",
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
          if (isPaidAfterDue)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Paid after due date. Late payment!",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildDueDateAndReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Due Date: ${loan.expectedReturnDate != null ? DateFormat.yMMMd().format(loan.expectedReturnDate!) : 'N/A'}",
          style: TextStyle(fontSize: 16),
        ),
        Text("Reason: ${loan.reason ?? 'N/A'}", style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildPaymentInput() {
    return TextField(
      controller: paymentController,
      decoration: InputDecoration(
        labelText: "Amount Paid",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payments, color: Colors.deepPurple),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMarkPaymentButton() {
    return ElevatedButton(
      onPressed: () {
        if (paymentController.text.isNotEmpty) {
          final paymentAmount = double.tryParse(paymentController.text);
          if (paymentAmount != null && paymentAmount > 0) {
            controller.updatePayment(loan.id ?? '', paymentAmount).then((_) {
              paymentController.clear();
              Get.snackbar("Success", "Payment recorded successfully");
            });
          } else {
            Get.snackbar("Error", "Enter a valid payment amount");
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text("Mark Payment", style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Obx(() {
          return loan.paymentHistory.isEmpty
              ? Text("No payments yet.", style: TextStyle(fontSize: 16))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: loan.paymentHistory.length,
                  itemBuilder: (context, index) {
                    final payment = loan.paymentHistory[index];
                    final date = DateTime.parse(payment['date']);
                    final formattedDate =
                        DateFormat('dd MMM yyyy, hh:mm a').format(date);

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        title: Text("₹${payment['amount']}",
                            style: TextStyle(fontSize: 16)),
                        subtitle: Text(formattedDate),
                        leading: Icon(Icons.payments, color: Colors.deepPurple),
                        trailing:
                            Icon(Icons.chevron_right, color: Colors.deepPurple),
                      ),
                    );
                  },
                );
        }),
      ],
    );
  }
}
