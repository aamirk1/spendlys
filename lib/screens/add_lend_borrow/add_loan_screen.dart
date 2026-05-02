import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/res/components/custom_button.dart';
import '../../models/loan_modal.dart';
import '../../controllers/loan_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/utils/validators.dart';

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
  late final TextEditingController phoneController;
  late final TextEditingController amountController;
  late final TextEditingController reasonController;
  late String type;
  String paymentMode = 'Cash';
  DateTime? expectedReturnDate;
  late DateTime date;

  bool get isEditMode => widget.loan != null;

  @override
  void initState() {
    super.initState();
    personController =
        TextEditingController(text: widget.loan?.personName ?? "");
    phoneController =
        TextEditingController(text: widget.loan?.personPhone ?? "");
    amountController = TextEditingController(
        text: widget.loan != null ? widget.loan!.amount.toString() : "");
    reasonController = TextEditingController(text: widget.loan?.reason ?? "");
    type = widget.loan?.type ?? 'borrowed';
    paymentMode = widget.loan?.paymentMode ?? 'Cash';
    expectedReturnDate = widget.loan?.expectedReturnDate;
    date = widget.loan?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    personController.dispose();
    phoneController.dispose();
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
    String? Function(String?)? validator, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color
                  ?.withOpacity(0.8),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).disabledColor.withOpacity(0.5),
              fontSize: 15,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.primary, size: 22)
                : null,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text("transaction_type".tr,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.8))),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _typeCard('borrowed', "borrowed_label".tr,
                  Icons.arrow_downward_rounded, AppColors.orange),
              _typeCard('lent', "lent_label".tr, Icons.arrow_upward_rounded,
                  AppColors.green),
            ],
          ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).disabledColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).disabledColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text("expected_return_date".tr,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.8))),
        ),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: expectedReturnDate ??
                  DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime(2023),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              setState(() => expectedReturnDate = pickedDate);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 22, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(formattedDate,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: expectedReturnDate != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).disabledColor)),
                ),
                Icon(Icons.edit_calendar_rounded,
                    size: 20, color: Theme.of(context).disabledColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModeSelector(BuildContext context) {
    final List<String> paymentModes = [
      'Cash',
      'Bank Transfer',
      'Credit Card',
      'UPI',
      'Other'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text("Payment Mode",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.8))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: paymentMode,
              isExpanded: true,
              dropdownColor: Theme.of(context).cardColor,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary),
              items: paymentModes.map((String mode) {
                return DropdownMenuItem<String>(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(
                        mode == 'Cash'
                            ? Icons.money_rounded
                            : mode == 'Bank Transfer'
                                ? Icons.account_balance_rounded
                                : mode == 'Credit Card'
                                    ? Icons.credit_card_rounded
                                    : mode == 'UPI'
                                        ? Icons.qr_code_scanner_rounded
                                        : Icons.payment_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(mode,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    paymentMode = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
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
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditMode ? "update_record".tr : "digital_ledger_entry".tr,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "lending_borrowing_desc".tr,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputField(
                      personController,
                      'contact_name'.tr,
                      'deal_with_hint'.tr,
                      Icons.person_rounded,
                      TextInputType.text,
                      (value) => (value == null || value.isEmpty)
                          ? 'name_required'.tr
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      phoneController,
                      'phone'.tr,
                      'person_phone_hint'.tr,
                      Icons.phone_iphone_rounded,
                      TextInputType.phone,
                      (value) {
                        if (value == null || value.isEmpty) {
                          return 'amount_required'.tr;
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'Enter a valid 10-digit phone number'; // I should check if there's a translation for this
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      amountController,
                      'amount'.tr,
                      'enter_transaction_amount'.tr,
                      Icons.currency_rupee_rounded,
                      TextInputType.number,
                      (value) {
                        if (value == null || value.isEmpty) {
                          return 'amount_required'.tr;
                        }
                        if (double.tryParse(value) == null) {
                          return 'invalid_amount'.tr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      reasonController,
                      'note_memo'.tr,
                      'reason_hint'.tr,
                      Icons.description_rounded,
                      TextInputType.multiline,
                      (value) {
                        if (value != null && value.length > 100) {
                          return 'Note is too long (max 100 chars)';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    _buildLoanTypeSelector(),
                    const SizedBox(height: 24),
                    _buildPaymentModeSelector(context),
                    const SizedBox(height: 24),
                    _buildDatePicker(context),
                    const SizedBox(height: 48),
                    Obx(() => CustomButton(
                          text: isEditMode
                              ? 'update_record'.tr
                              : 'save_record'.tr,
                          isLoading: widget.controller.isLoading.value,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (expectedReturnDate == null) {
                                Utils.showSnackbar(
                                    "warning".tr, "set_return_date".tr);
                                return;
                              }

                              if (isEditMode) {
                                final updatedLoan = widget.loan!.copyWith(
                                  personName: personController.text,
                                  personPhone: phoneController.text,
                                  amount: double.parse(amountController.text),
                                  type: type,
                                  paymentMode: paymentMode,
                                  reason: reasonController.text,
                                  expectedReturnDate: expectedReturnDate,
                                );
                                await widget.controller.updateLoan(updatedLoan);
                              } else {
                                final loan = Loan(
                                  userId: widget.myUser.userId,
                                  id: const Uuid().v4(),
                                  personName: personController.text,
                                  personPhone: phoneController.text,
                                  amount: double.parse(amountController.text),
                                  paidAmount: 0.0.obs,
                                  expectedReturnDate: expectedReturnDate!,
                                  reason: reasonController.text,
                                  type: type,
                                  paymentMode: paymentMode,
                                  date: date,
                                  status: 'pending'.obs,
                                );
                                await widget.controller.addLoan(loan);
                              }
                            }
                          },
                          backgroundColor: AppColors.primary,
                          textColor: Colors.white,
                          borderRadius: 18,
                        )),
                    const SizedBox(height: 40),
                    _buildRecentEntries(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('recent_transactions'.tr,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color)),
            Obx(() => widget.controller.loans.length > 5
                ? GestureDetector(
                    onTap: () => Get.offNamed(RoutesName.addLendBorrowView,
                        arguments: {
                          'myUser': widget.myUser,
                          'index': type == 'lent' ? 0 : 1
                        }),
                    child: Text('view_all'.tr,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.indigo.shade600,
                            fontWeight: FontWeight.w600)),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 15),
        Obx(() {
          final recentLoans = widget.controller.loans.take(5).toList();

          if (recentLoans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 50, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text("no_loan_records".tr,
                        style:
                            TextStyle(color: Theme.of(context).disabledColor)),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: recentLoans.map((loan) {
              final isLent = loan.type == 'lent';
              final color = isLent ? Colors.green : Colors.orange;
              final icon = isLent ? Icons.arrow_upward : Icons.arrow_downward;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loan.personName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color)),
                          const SizedBox(height: 2),
                          Text(DateFormat('dd MMM yyyy').format(loan.date),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("₹${loan.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: color)),
                        Text(loan.paymentMode ?? 'N/A',
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).disabledColor)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

extension LoanExtension on Loan {
  Loan copyWith({
    String? personName,
    String? personPhone,
    double? amount,
    String? type,
    String? paymentMode,
    String? reason,
    DateTime? expectedReturnDate,
  }) {
    return Loan(
      id: id,
      userId: userId,
      personName: personName ?? this.personName,
      personPhone: personPhone ?? this.personPhone,
      amount: amount ?? this.amount,
      paidAmount: paidAmount,
      status: status,
      date: date,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      type: type ?? this.type,
      paymentMode: paymentMode ?? this.paymentMode,
      reason: reason ?? this.reason,
      paymentHistory: paymentHistory,
    );
  }
}
