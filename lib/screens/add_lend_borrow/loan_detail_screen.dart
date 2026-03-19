import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/customBotton.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/info_column.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/overall_payment_status.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/payment_history_card.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:spendly/utils/utils.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final LoanController controller;

  LoanDetailScreen({required this.loan, required this.controller, super.key});

  final paymentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loan.personName,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade700,
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade100,
              Colors.indigo.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverviewCard(loan: loan),
              const SizedBox(height: 20),
              _buildPaymentInputCard(controller: controller, loanId: loan.id),
              const SizedBox(height: 20),
              // _buildPaymentHistoryCard(
              //   loan: loan,
              // ),
              PaymentHistoryCard(loan: loan),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildOverviewCard({required Loan loan}) {
  final formattedAmount = NumberFormat('#,##0').format(loan.amount);
  final formattedDueDate = loan.expectedReturnDate != null
      ? DateFormat('dd MMM yyyy').format(loan.expectedReturnDate!)
      : 'N/A';

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Obx(() {
            final remaining = loan.amount - loan.paidAmount.value;
            final formattedRemainingObx =
                NumberFormat('#,##0').format(remaining);
            final percentagePaidObx =
                loan.amount > 0 ? (loan.paidAmount.value / loan.amount) : 0;

            Color progressColorObx;
            if (remaining == 0) {
              progressColorObx = Colors.greenAccent.shade400;
            } else if (percentagePaidObx >= 0.75) {
              progressColorObx = Colors.lightGreenAccent.shade400;
            } else if (percentagePaidObx >= 0.3) {
              progressColorObx = Colors.amberAccent.shade400;
            } else {
              progressColorObx = Colors.redAccent.shade400;
            }

            // Ensure the percentage is between 0.0 and 1.0
            final clampedPercentage = percentagePaidObx.clamp(0.0, 1.0);

            return CircularPercentIndicator(
              radius: 85.0,
              lineWidth: 10.0,
              percent: clampedPercentage.toDouble(),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "₹$formattedRemainingObx",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      color: Colors.indigo,
                    ),
                  ),
                  const Text(
                    "Remaining",
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
              progressColor: progressColorObx,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animateFromLastPercent: true,
            );
          }),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InfoColumn(
                  title: "Total",
                  value: "₹$formattedAmount",
                  color: Colors.indigo.shade700),
              InfoColumn(
                  title: "Due",
                  value: formattedDueDate,
                  color: Colors.indigo.shade700)
              // _buildInfoColumn(
              //     title: "Total",
              //     value: "₹$formattedAmount",
              //     color: Colors.indigo.shade700,
              //     fontSize: 15),
              // _buildInfoColumn(
              //     title: "Due",
              //     value: formattedDueDate,
              //     color: Colors.deepPurple.shade700,
              //     fontSize: 15),
            ],
          ),
          const SizedBox(height: 14),
          // _buildOverallPaymentStatus(
          //     loan.paidAmount.value, loan.amount, loan.expectedReturnDate),
          OverallPaymentStatus(
              paidAmount: loan.paidAmount.value,
              totalAmount: loan.amount,
              dueDate: loan.expectedReturnDate!),
          if (loan.reason != null && loan.reason!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text("Reason: ${loan.reason}",
                style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ],
        ],
      ),
    ),
  );
}

Widget _buildPaymentInputCard(
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
            backgroundColor: Colors.deepPurple.shade400,
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
