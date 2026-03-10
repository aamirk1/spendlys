import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/info_column.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/overall_payment_status.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({super.key, required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    return buildOverviewCard(loan: loan);
  }

  Widget buildOverviewCard({required Loan loan}) {
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
              ],
            ),
            const SizedBox(height: 14),
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
}
