// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:spendly/res/components/customBotton.dart';
// import 'package:spendly/screens/add_lend_borrow/loan_controller.dart';
// import 'package:spendly/screens/add_lend_borrow/loan_modal.dart';
// import 'package:spendly/utils/colors.dart';
// import 'package:intl/intl.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';

// class LoanDetailScreen extends StatelessWidget {
//   final Loan loan;
//   final LoanController controller;

//   LoanDetailScreen({required this.loan, required this.controller, Key? key})
//       : super(key: key);

//   final paymentController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           loan.personName,
//           style: const TextStyle(
//               fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: Colors.indigo.shade700,
//         elevation: 3,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.indigo.shade100,
//               Colors.indigo.shade50,
//               Colors.white,
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(15),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _buildOverviewCard(loan: loan),
//               const SizedBox(height: 20),
//               _buildPaymentInputCard(controller: controller, loanId: loan.id),
//               const SizedBox(height: 20),
//               _buildPaymentHistoryCard(loan: loan),
//               const SizedBox(height: 10),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// Widget _buildOverviewCard({required Loan loan}) {
//   final formattedAmount = NumberFormat('#,##0').format(loan.amount);
//   final formattedDueDate = loan.expectedReturnDate != null
//       ? DateFormat('dd MMM yyyy').format(loan.expectedReturnDate!)
//       : 'N/A';

//   return Card(
//     elevation: 4,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//     child: Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Obx(() {
//             final remaining = loan.amount - loan.paidAmount.value;
//             final formattedRemainingObx =
//                 NumberFormat('#,##0').format(remaining);
//             final percentagePaidObx =
//                 loan.amount > 0 ? (loan.paidAmount.value / loan.amount) : 0;

//             Color progressColorObx;
//             if (remaining == 0) {
//               progressColorObx = Colors.greenAccent.shade400;
//             } else if (percentagePaidObx >= 0.75) {
//               progressColorObx = Colors.lightGreenAccent.shade400;
//             } else if (percentagePaidObx >= 0.3) {
//               progressColorObx = Colors.amberAccent.shade400;
//             } else {
//               progressColorObx = Colors.redAccent.shade400;
//             }

//             return CircularPercentIndicator(
//               radius: 85.0,
//               lineWidth: 10.0,
//               percent: percentagePaidObx.toDouble(),
//               center: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "₹$formattedRemainingObx",
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 26,
//                       color: Colors.indigo,
//                     ),
//                   ),
//                   const Text(
//                     "Remaining",
//                     style: TextStyle(color: Colors.blueGrey),
//                   ),
//                 ],
//               ),
//               progressColor: progressColorObx,
//               backgroundColor: Colors.grey.shade200,
//               circularStrokeCap: CircularStrokeCap.round,
//               animation: true,
//               animateFromLastPercent: true,
//             );
//           }),
//           const SizedBox(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildInfoColumn(
//                   title: "Total",
//                   value: "₹$formattedAmount",
//                   color: Colors.indigo.shade700,
//                   fontSize: 15),
//               _buildInfoColumn(
//                   title: "Due",
//                   value: formattedDueDate,
//                   color: Colors.deepPurple.shade700,
//                   fontSize: 15),
//             ],
//           ),
//           const SizedBox(height: 14),
//           _buildOverallPaymentStatus(
//               loan.paidAmount.value, loan.amount, loan.expectedReturnDate),
//           if (loan.reason != null && loan.reason!.isNotEmpty) ...[
//             const SizedBox(height: 14),
//             Text("Reason: ${loan.reason}",
//                 style: const TextStyle(fontSize: 15, color: Colors.black87)),
//           ],
//         ],
//       ),
//     ),
//   );
// }

// Widget _buildOverallPaymentStatus(
//     double paidAmount, double totalAmount, DateTime? dueDate) {
//   if (paidAmount >= totalAmount) {
//     return const Text(
//       "Status: Paid",
//       style: TextStyle(
//           fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.green),
//     );
//   } else if (dueDate != null) {
//     final now = DateTime.now();
//     if (now.isAfter(dueDate)) {
//       return const Text(
//         "Status: Overdue",
//         style: TextStyle(
//             fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error),
//       );
//     } else {
//       final difference = dueDate.difference(now).inDays;
//       if (difference <= 7) {
//         return const Text(
//           "Status: Due Soon",
//           style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: AppColors.orange),
//         );
//       } else if (paidAmount > 0) {
//         return const Text(
//           "Status: Partially Paid",
//           style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: AppColors.orange),
//         );
//       } else {
//         return const Text(
//           "Status: Not Paid",
//           style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: AppColors.error),
//         );
//       }
//     }
//   } else {
//     if (paidAmount > 0) {
//       return const Text(
//         "Status: Partially Paid",
//         style: TextStyle(
//             fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.orange),
//       );
//     } else {
//       return const Text(
//         "Status: Not Paid",
//         style: TextStyle(
//             fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error),
//       );
//     }
//   }
// }

// Widget _buildInfoColumn(
//     {required String title,
//     required String value,
//     required Color color,
//     double fontSize = 16}) {
//   return Column(
//     children: [
//       Text(title,
//           style: TextStyle(
//               color: Colors.blueGrey.shade600,
//               fontWeight: FontWeight.w500,
//               fontSize: fontSize - 1)),
//       const SizedBox(height: 4),
//       Text(value,
//           style: TextStyle(
//               color: color, fontWeight: FontWeight.bold, fontSize: fontSize)),
//     ],
//   );
// }

// Widget _buildPaymentInputCard(
//     {required LoanController controller, String? loanId}) {
//   final paymentController = TextEditingController();
//   return Card(
//     elevation: 4,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//     child: Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           TextField(
//             controller: paymentController,
//             keyboardType: TextInputType.number,
//             decoration: InputDecoration(
//               labelText: "Payment Amount",
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//               prefixIcon:
//                   const Icon(Icons.currency_rupee, color: Colors.indigo),
//             ),
//           ),
//           const SizedBox(height: 16),
//           CustomButton(
//             text: "Mark as Paid",
//             onPressed: () {
//               if (paymentController.text.isNotEmpty && loanId != null) {
//                 final paymentAmount = double.tryParse(paymentController.text);
//                 if (paymentAmount != null && paymentAmount > 0) {
//                   controller.updatePayment(loanId, paymentAmount).then((_) {
//                     paymentController.clear();
//                     Get.snackbar("Success", "Payment recorded!",
//                         snackPosition: SnackPosition.BOTTOM,
//                         backgroundColor: Colors.green.shade100,
//                         colorText: Colors.green.shade800,
//                         borderRadius: 10,
//                         margin: const EdgeInsets.all(15));
//                   });
//                 } else {
//                   Get.snackbar("Error", "Invalid amount",
//                       snackPosition: SnackPosition.BOTTOM,
//                       backgroundColor: Colors.red.shade100,
//                       colorText: Colors.red.shade800,
//                       borderRadius: 10,
//                       margin: const EdgeInsets.all(15));
//                 }
//               } else if (loanId == null) {
//                 Get.snackbar("Error", "Loan ID is missing",
//                     snackPosition: SnackPosition.BOTTOM,
//                     backgroundColor: Colors.red.shade100,
//                     colorText: Colors.red.shade800,
//                     borderRadius: 10,
//                     margin: const EdgeInsets.all(15));
//               }
//             },
//             backgroundColor: Colors.deepPurple.shade400,
//             textColor: Colors.white,
//             fontSize: 17,
//             borderRadius: 14,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             elevation: 3,
//             icon: const Icon(Icons.check_circle_outline, color: Colors.white),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// Widget _buildPaymentHistoryCard({required Loan loan}) {
//   return Card(
//     elevation: 4,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//     child: Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Payment History",
//             style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.indigo),
//           ),
//           const SizedBox(height: 14),
//           Obx(() {
//             return loan.paymentHistory.isEmpty
//                 ? const Text("No payments yet.",
//                     style: TextStyle(fontSize: 15, color: Colors.blueGrey))
//                 : ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: loan.paymentHistory.length,
//                     separatorBuilder: (context, index) =>
//                         Divider(thickness: 0.8, color: Colors.grey.shade200),
//                     itemBuilder: (context, index) {
//                       final payment = loan.paymentHistory[index];
//                       final date = DateTime.parse(payment['date']);
//                       final formattedDate =
//                           DateFormat('dd MMM, yyyy hh:mm a').format(date);

//                       return ListTile(
//                         contentPadding: EdgeInsets.zero,
//                         leading: Container(
//                           padding: const EdgeInsets.all(7),
//                           decoration: BoxDecoration(
//                             color: Colors.purpleAccent.shade100,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Icon(Icons.arrow_downward,
//                               color: Colors.indigo),
//                         ),
//                         title: Text(
//                             "₹${NumberFormat('#,##0').format(payment['amount'])}",
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                                 fontSize: 16)),
//                         subtitle: Text(formattedDate,
//                             style: const TextStyle(
//                                 color: Colors.blueGrey, fontSize: 14)),
//                         trailing: const Icon(Icons.chevron_right,
//                             color: Colors.indigo),
//                       );
//                     },
//                   );
//           }),
//         ],
//       ),
//     ),
//   );
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/customBotton.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/info_column.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/overall_payment_status.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/payment_history_card.dart';
import 'package:spendly/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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
