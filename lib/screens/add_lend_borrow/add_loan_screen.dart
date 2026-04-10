import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/res/components/customBotton.dart';
import '../../models/loan_modal.dart';
import '../../controllers/loan_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:spendly/utils/colors.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanController controller;
  final MyUser myUser;
  final Loan? loan; // Optional loan for edit mode

  const AddLoanScreen({
    required this.myUser,
    super.key,
    required this.controller,
    this.loan,
  });

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController personController;
  late final TextEditingController amountController;
  late final TextEditingController reasonController;
  late String type;
  DateTime? expectedReturnDate;
  late DateTime date;

  bool get isEditMode => widget.loan != null;

  @override
  void initState() {
    super.initState();
    personController =
        TextEditingController(text: widget.loan?.personName ?? "");
    amountController = TextEditingController(
        text: widget.loan != null ? widget.loan!.amount.toString() : "");
    reasonController = TextEditingController(text: widget.loan?.reason ?? "");
    type = widget.loan?.type ?? 'borrowed';
    expectedReturnDate = widget.loan?.expectedReturnDate;
    date = widget.loan?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    personController.dispose();
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType keyboardType,
    String? Function(String?)? validator,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
            fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  color: Theme.of(context).textTheme.bodySmall?.color, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text("transaction_type".tr,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
        Row(
          children: [
            _typeCard('borrowed', "borrowed_label".tr, Icons.arrow_downward,
                Colors.orange),
            const SizedBox(width: 15),
            _typeCard(
                'lent', "lent_label".tr, Icons.arrow_upward, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _typeCard(String value, String label, IconData icon, Color color) {
    final isSelected = type == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => type = value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? color : Theme.of(context).disabledColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Theme.of(context).disabledColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final formattedDate = expectedReturnDate != null
        ? DateFormat('dd MMM yyyy').format(expectedReturnDate!)
        : 'select_due_date'.tr;

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: expectedReturnDate ??
              DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
        );
        if (pickedDate != null) {
          setState(() => expectedReturnDate = pickedDate);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Text(formattedDate,
                  style: TextStyle(
                      fontSize: 16,
                      color: expectedReturnDate != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).disabledColor)),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: isEditMode ? 'edit_transaction'.tr : 'new_transaction'.tr,
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditMode ? "update_record".tr : "digital_ledger_entry".tr,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color),
              ),
              const SizedBox(height: 8),
              Text(
                "lending_borrowing_desc".tr,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 35),
              _buildInputField(
                personController,
                'contact_name'.tr,
                'deal_with_hint'.tr,
                Icons.person_outline,
                TextInputType.text,
                (value) => value!.isEmpty ? 'name_required'.tr : null,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                amountController,
                'amount'.tr,
                'Enter transaction amount', // Need key for this too if wanted, or just use amount.tr
                Icons.currency_rupee_outlined,
                TextInputType.number,
                (value) {
                  if (value == null || value.isEmpty)
                    return 'amount_required'.tr;
                  if (double.tryParse(value) == null)
                    return 'invalid_amount'.tr;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildInputField(
                reasonController,
                'note_memo'.tr,
                'reason_hint'.tr,
                Icons.note_alt_outlined,
                TextInputType.text,
                null,
              ),
              const SizedBox(height: 30),
              _buildLoanTypeSelector(),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text("expected_return_date".tr,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
              ),
              _buildDatePicker(context),
              const SizedBox(height: 50),
              CustomButton(
                text: isEditMode ? 'update_record'.tr : 'save_record'.tr,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (expectedReturnDate == null) {
                      Utils.showSnackbar("warning".tr, "set_return_date".tr);
                      return;
                    }

                    if (isEditMode) {
                      final updatedLoan = widget.loan!.copyWith(
                        personName: personController.text,
                        amount: double.parse(amountController.text),
                        type: type,
                        reason: reasonController.text,
                        expectedReturnDate: expectedReturnDate,
                      );
                      widget.controller.updateLoan(updatedLoan);
                    } else {
                      final loan = Loan(
                        userId: widget.myUser.userId,
                        id: const Uuid().v4(),
                        personName: personController.text,
                        amount: double.parse(amountController.text),
                        paidAmount: 0.0.obs,
                        expectedReturnDate: expectedReturnDate!,
                        reason: reasonController.text,
                        type: type,
                        date: date,
                        status: 'pending'.obs,
                      );
                      widget.controller.addLoan(loan);
                    }
                    Get.back();
                  }
                },
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension LoanExtension on Loan {
  Loan copyWith({
    String? personName,
    double? amount,
    String? type,
    String? reason,
    DateTime? expectedReturnDate,
  }) {
    return Loan(
      id: id,
      userId: userId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount,
      status: status,
      date: date,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      paymentHistory: paymentHistory,
    );
  }
}
