import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/custom_button.dart';
import '../../models/loan_modal.dart';
import '../../controllers/loan_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:spendly/utils/colors.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

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

  static const Color themePrimary = Color(0xFF5F33E1);

  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();

  Future<void> _pickContact() async {
    try {
      final Contact? contact = await _contactPicker.selectContact();
      if (contact != null) {
        setState(() {
          personController.text = contact.fullName ?? '';
          if (contact.phoneNumbers != null &&
              contact.phoneNumbers!.isNotEmpty) {
            String rawPhone = contact.phoneNumbers!.first;
            String cleanedPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
            if (cleanedPhone.length > 10) {
              cleanedPhone = cleanedPhone.substring(cleanedPhone.length - 10);
            }
            phoneController.text = cleanedPhone;
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error picking contact: $e");
      debugPrint(stackTrace.toString());
      Utils.showSnackbar("error".tr,
          "Could not select contact. Please try again or enter details manually.");
    }
  }

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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildSleekInputField(
    TextEditingController controller,
    String label,
    String? hint,
    IconData prefixIcon,
    TextInputType keyboardType,
    String? Function(String?)? validator, {
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
        prefixIcon: Icon(prefixIcon, color: themePrimary, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F9FD),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: themePrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }

  Widget buildSleekTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => type = 'borrowed'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: type == 'borrowed'
                      ? AppColors.orange.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: type == 'borrowed'
                          ? AppColors.orange
                          : Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "borrowed_label".tr,
                      style: TextStyle(
                        color: type == 'borrowed'
                            ? AppColors.orange
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => type = 'lent'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: type == 'lent'
                      ? AppColors.green.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: type == 'lent'
                          ? AppColors.green
                          : Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "lent_label".tr,
                      style: TextStyle(
                        color: type == 'lent'
                            ? AppColors.green
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPaymentModeSelector() {
    final List<Map<String, dynamic>> paymentModes = [
      {'name': 'Cash', 'icon': Icons.money_rounded},
      {'name': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
      {'name': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
      {'name': 'Credit Card', 'icon': Icons.credit_card_rounded},
      {'name': 'Other', 'icon': Icons.payment_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Payment Mode",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: paymentModes.length,
            itemBuilder: (context, index) {
              final mode = paymentModes[index];
              final isSelected = paymentMode == mode['name'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    children: [
                      Icon(
                        mode['icon'],
                        color: isSelected ? Colors.white : themePrimary,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        mode['name'],
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade800,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: themePrimary,
                  backgroundColor: const Color(0xFFF8F9FD),
                  shadowColor: Colors.transparent,
                  checkmarkColor: Colors.transparent,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? themePrimary : Colors.grey.shade200,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        paymentMode = mode['name'];
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildDatePickerCard(BuildContext context) {
    final formattedDate = expectedReturnDate != null
        ? DateFormat('dd MMM yyyy').format(expectedReturnDate!)
        : 'select_due_date'.tr;

    DateTime getTargetDate(int days) {
      return DateTime.now().add(Duration(days: days));
    }

    final quickDates = [
      {'label': '1 Wk', 'days': 7},
      {'label': '1 Mo', 'days': 30},
      {'label': '3 Mo', 'days': 90},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "expected_return_date".tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: themePrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: expectedReturnDate != null
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => selectCustomDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themePrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_calendar_rounded,
                    color: themePrimary, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: quickDates.map((qd) {
            final targetDate = getTargetDate(qd['days'] as int);
            final isSelected = expectedReturnDate != null &&
                expectedReturnDate!.year == targetDate.year &&
                expectedReturnDate!.month == targetDate.month &&
                expectedReturnDate!.day == targetDate.day;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(
                  qd['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade800,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: themePrimary,
                backgroundColor: const Color(0xFFF8F9FD),
                shadowColor: Colors.transparent,
                checkmarkColor: Colors.transparent,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? themePrimary : Colors.grey.shade200,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      expectedReturnDate = targetDate;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> selectCustomDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          expectedReturnDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: themePrimary,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEditMode ? 'edit_transaction'.tr : 'new_transaction'.tr,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: Amount & Type Selector
                  _buildSectionCard(
                    child: Column(
                      children: [
                        Text(
                          "enter_transaction_amount".tr.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "₹",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IntrinsicWidth(
                              stepWidth: 10,
                              child: TextFormField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                cursorColor: themePrimary,
                                decoration: InputDecoration(
                                  hintText: "0",
                                  hintStyle: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade300,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'amount_required'.tr;
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'invalid_amount'.tr;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        buildSleekTypeSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 2: Partner Details
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: themePrimary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_pin_rounded,
                                  color: themePrimary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Partner Details",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSleekInputField(
                          personController,
                          'contact_name'.tr,
                          'deal_with_hint'.tr,
                          Icons.person_rounded,
                          TextInputType.text,
                          (value) => (value == null || value.isEmpty)
                              ? 'name_required'.tr
                              : null,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.contacts_rounded,
                                color: themePrimary),
                            onPressed: _pickContact,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSleekInputField(
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
                              return 'Enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 3: Transaction Details
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: themePrimary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payment_rounded,
                                  color: themePrimary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Transaction Details",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        buildPaymentModeSelector(),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        buildDatePickerCard(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 4: Notes / Reason
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: themePrimary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.description_rounded,
                                  color: themePrimary, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Note / Memo",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSleekInputField(
                          reasonController,
                          'note_memo'.tr,
                          'reason_hint'.tr,
                          Icons.edit_note_rounded,
                          TextInputType.multiline,
                          (value) {
                            if (value != null && value.length > 100) {
                              return 'Note is too long (max 100 chars)';
                            }
                            return null;
                          },
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Button
                  Obx(() => CustomButton(
                        text:
                            isEditMode ? 'update_record'.tr : 'save_record'.tr,
                        isLoading: widget.controller.isLoading.value,
                        gradient: const LinearGradient(
                          colors: [
                            themePrimary,
                            Color(0xFF8C66FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                        borderRadius: 14,
                      )),
                  const SizedBox(height: 32),

                  // Recent Entries Section
                  buildRecentEntries(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRecentEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'recent_transactions'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Obx(() => widget.controller.loans.length > 5
                ? GestureDetector(
                    onTap: () =>
                        Get.offNamed(RoutesName.addLendBorrowView, arguments: {
                      'myUser': widget.myUser,
                      'index': type == 'lent' ? 0 : 1,
                    }),
                    child: const Text(
                      'view_all',
                      style: TextStyle(
                        fontSize: 12,
                        color: themePrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 14),
        Obx(() {
          final recentLoans = widget.controller.loans.take(5).toList();

          if (recentLoans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      "no_loan_records".tr,
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: recentLoans.map((loan) {
              final isLent = loan.type == 'lent';
              final color = isLent ? AppColors.green : AppColors.orange;
              final icon = isLent ? Icons.arrow_upward : Icons.arrow_downward;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.personName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(loan.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isLent ? "Lent" : "Borrowed",
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${loan.amount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          loan.paymentMode ?? 'N/A',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade400,
                          ),
                        ),
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
