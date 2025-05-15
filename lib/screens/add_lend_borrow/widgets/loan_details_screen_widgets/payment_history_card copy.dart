import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/loan_modal.dart';

class PaymentHistoryCard extends StatelessWidget {
  const PaymentHistoryCard({super.key, required this.loan});
final  Loan loan;
  @override
  Widget build(BuildContext context) {
    return buildPaymentHistoryCard(loan:loan );
  }

Widget buildPaymentHistoryCard({required Loan loan}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment History",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo),
          ),
          const SizedBox(height: 14),
          Obx(() {
            return loan.paymentHistory.isEmpty
                ? const Text("No payments yet.",
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: loan.paymentHistory.length,
                    separatorBuilder: (context, index) =>
                        Divider(thickness: 0.8, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final payment = loan.paymentHistory[index];

                      // Defensive null & type checks
                      final amount = payment['amount'] ?? 0.0;
                      final timestamp = payment['timestamp'];

                      String formattedDate = 'Date unavailable';

                      if (timestamp != null) {
                        try {
                          DateTime? date;

                          if (timestamp is String) {
                            date = DateTime.tryParse(timestamp);
                          } else if (timestamp is DateTime) {
                            date = timestamp;
                          }

                          if (date != null) {
                            formattedDate =
                                DateFormat('dd MMM, yyyy hh:mm a').format(date);
                          } else {
                            formattedDate = 'Invalid date';
                          }
                        } catch (e) {
                          formattedDate = 'Invalid date';
                        }
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_downward,
                              color: Colors.indigo),
                        ),
                        title: Text(
                          "₹${NumberFormat('#,##0').format(amount)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 16),
                        ),
                        subtitle: Text(
                          formattedDate,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.blueGrey),
                        ),
                      );
                    },
                  );
          }),
        ],
      ),
    ),
  );
}
}