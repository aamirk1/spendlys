import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:uuid/uuid.dart';
import 'package:spendly/utils/utils.dart';

class SaveButton extends StatelessWidget {
  const SaveButton(
      {super.key,
      required this.formKey,
      required this.personController,
      required this.amountController,
      required this.expectedReturnDate,
      this.reasonController,
      required this.type,
      required this.controller,
      required this.date,
      required this.myUser});

  final GlobalKey<FormState> formKey;
  final TextEditingController personController;
  final TextEditingController amountController;
  final DateTime? expectedReturnDate;
  final TextEditingController? reasonController;
  final String type;
  final LoanController controller;
  final DateTime date;
  final MyUser myUser;

  @override
  Widget build(BuildContext context) {
    return buildSaveButton(formKey, personController, amountController,
        expectedReturnDate, reasonController, type, controller, date, myUser);
  }

  Widget buildSaveButton(
      GlobalKey<FormState> formKey,
      TextEditingController personController,
      TextEditingController amountController,
      DateTime? expectedReturnDate,
      TextEditingController? reasonController,
      String type,
      LoanController controller,
      DateTime date,
      MyUser myUser) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade500, Colors.purple.shade400],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomButton(
          text: 'Save Loan',
          onPressed: () {
            if (formKey.currentState!.validate()) {
              if (expectedReturnDate == null) {
                Utils.showSnackbar(
                  "Warning",
                  "Please select the expected return date.",
                );
                return;
              }
              final loan = Loan(
                userId: myUser.userId,
                id: const Uuid().v4(),
                personName: personController.text,
                amount: double.parse(amountController.text),
                paidAmount: 0.0.obs,
                expectedReturnDate: expectedReturnDate,
                reason:
                    (reasonController == null || reasonController.text.isEmpty)
                        ? null
                        : reasonController.text,
                type: type,
                date: date,
                status: 'pending'.obs,
              );
              controller.addLoan(loan);
              Get.back();
            }
          },
        ));
  }
}
