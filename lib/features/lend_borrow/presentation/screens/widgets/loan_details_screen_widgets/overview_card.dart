import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:spendly/features/lend_borrow/data/models/loan_model.dart';
import 'package:spendly/features/lend_borrow/presentation/screens/widgets/loan_details_screen_widgets/info_column.dart';
import 'package:spendly/features/lend_borrow/presentation/screens/widgets/loan_details_screen_widgets/overall_payment_status.dart';

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

    final remaining = loan.amount - loan.paidAmount;
    final formattedRemaining = NumberFormat('#,##0').format(remaining);
    final percentagePaid = loan.amount > 0 ? (loan.paidAmount / loan.amount) : 0.0;

    Color progressColor;
    if (remaining == 0) {
      progressColor = Colors.greenAccent.shade400;
    } else if (percentagePaid >= 0.75) {
      progressColor = Colors.lightGreenAccent.shade400;
    } else if (percentagePaid >= 0.3) {
      progressColor = Colors.amberAccent.shade400;
    } else {
      progressColor = Colors.redAccent.shade400;
    }

    final clampedPercentage = percentagePaid.clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 85.0,
              lineWidth: 10.0,
              percent: clampedPercentage,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "₹$formattedRemaining",
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
              progressColor: progressColor,
              backgroundColor: Colors.grey.shade200,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animateFromLastPercent: true,
            ),
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
                paidAmount: loan.paidAmount,
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
