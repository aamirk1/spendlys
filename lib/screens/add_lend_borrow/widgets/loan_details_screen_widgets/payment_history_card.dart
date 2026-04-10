import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/models/loan_modal.dart';

class PaymentHistoryCard extends StatelessWidget {
  const PaymentHistoryCard({super.key, required this.loan});
  final Loan loan;
  @override
  Widget build(BuildContext context) {
    return buildPaymentHistoryCard(context: context, loan: loan);
  }

  Widget buildPaymentHistoryCard(
      {required BuildContext context, required Loan loan}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment History",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 14),
            Obx(() {
              return loan.paymentHistory.isEmpty
                  ? Text("No payments yet.",
                      style: TextStyle(
                          fontSize: 15, color: Theme.of(context).disabledColor))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: loan.paymentHistory.length,
                      separatorBuilder: (context, index) => Divider(
                          thickness: 0.8,
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.1)),
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
                              formattedDate = DateFormat('dd MMM, yyyy hh:mm a')
                                  .format(date);
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
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontSize: 16),
                          ),
                          subtitle: Text(
                            formattedDate,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color),
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
