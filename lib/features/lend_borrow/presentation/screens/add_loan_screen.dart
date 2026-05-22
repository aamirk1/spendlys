import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';
import 'package:spendly/core/routes/routes_name.dart';
import 'package:spendly/core/utils/utils.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:spendly/core/widgets/custom_app_bar.dart';
import 'package:spendly/core/widgets/custom_button.dart';
import 'package:spendly/features/lend_borrow/data/models/loan_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spendly/features/lend_borrow/presentation/cubits/loan_cubit.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/theme/colors.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:spendly/core/utils/validators.dart';

class AddLoanScreen extends StatefulWidget {
  final MyUser myUser;
  final Loan? loan; // Optional loan for edit mode

  const AddLoanScreen({
    required this.myUser,
    super.key,
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
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 16,
        color: theme.textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.disabledColor.withValues(alpha: 0.4),
          fontSize: 15,
        ),
        prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
    );
  }

  Widget buildSleekTypeSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => type = 'borrowed'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: type == 'borrowed'
                      ? AppColors.orange.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: type == 'borrowed'
                          ? AppColors.orange
                          : theme.disabledColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "borrowed_label".tr,
                      style: TextStyle(
                        color: type == 'borrowed'
                            ? AppColors.orange
                            : theme.disabledColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: type == 'lent'
                      ? AppColors.green.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: type == 'lent'
                          ? AppColors.green
                          : theme.disabledColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "lent_label".tr,
                      style: TextStyle(
                        color: type == 'lent'
                            ? AppColors.green
                            : theme.disabledColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
      {'name': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
      {'name': 'Credit Card', 'icon': Icons.credit_card_rounded},
      {'name': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
      {'name': 'Other', 'icon': Icons.payment_rounded},
    ];

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Payment Mode",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: paymentModes.length,
            itemBuilder: (context, index) {
              final mode = paymentModes[index];
              final isSelected = paymentMode == mode['name'];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Row(
                    children: [
                      Icon(
                        mode['icon'],
                        color: isSelected ? Colors.white : AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode['name'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor:
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                  shadowColor: Colors.transparent,
                  checkmarkColor: Colors.transparent,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : theme.dividerColor.withValues(alpha: 0.08),
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

    final theme = Theme.of(context);

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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: expectedReturnDate != null
                              ? theme.textTheme.bodyLarge?.color
                              : theme.disabledColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => selectCustomDate(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.edit_calendar_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: quickDates.map((qd) {
            final targetDate = getTargetDate(qd['days'] as int);
            final isSelected = expectedReturnDate != null &&
                expectedReturnDate!.year == targetDate.year &&
                expectedReturnDate!.month == targetDate.month &&
                expectedReturnDate!.day == targetDate.day;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  qd['label'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                shadowColor: Colors.transparent,
                checkmarkColor: Colors.transparent,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : theme.dividerColor.withValues(alpha: 0.08),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: isEditMode ? 'edit_transaction'.tr : 'new_transaction'.tr,
        backgroundColor: AppColors.primary,
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
                  // Card 1: Amount & Type Selector (Clean Header Card)
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            "enter_transaction_amount".tr.toUpperCase(),
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "₹",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
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
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  cursorColor: AppColors.primary,
                                  decoration: InputDecoration(
                                    hintText: "0",
                                    hintStyle: TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.disabledColor.withValues(alpha: 0.3),
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
                          const SizedBox(height: 24),
                          buildSleekTypeSelector(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 2: Partner Details
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_pin_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Partner Details",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.titleMedium?.color,
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
                                  color: AppColors.primary),
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
                            Validators.mobileValidator,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 3: Transaction Details
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payment_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Transaction Details",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.titleMedium?.color,
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
                  ),
                  const SizedBox(height: 16),

                  // Card 4: Notes / Reason
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.description_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Note / Memo",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.titleMedium?.color,
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
                  ),
                  const SizedBox(height: 28),

                  // Action Button
                  BlocBuilder<LoanCubit, LoanState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: isEditMode ? 'update_record'.tr : 'save_record'.tr,
                        isLoading: state.isLoading,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
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
                              final success = await context.read<LoanCubit>().updateLoan(updatedLoan);
                              if (!context.mounted) return;
                              if (success) {
                                Utils.showSnackbar('Success', 'Loan updated successfully!', isError: false);
                                Get.offAllNamed(RoutesName.addLendBorrowView, arguments: {'index': 0});
                              } else {
                                final error = context.read<LoanCubit>().state.errorMessage ?? 'Failed to update loan';
                                Utils.showSnackbar('Error', error);
                              }
                            } else {
                              final success = await context.read<LoanCubit>().addLoan(
                                    personName: personController.text,
                                    personPhone: phoneController.text,
                                    amount: double.parse(amountController.text),
                                    type: type,
                                    paymentMode: paymentMode,
                                    reason: reasonController.text,
                                    expectedReturnDate: expectedReturnDate,
                                    creatorName: widget.myUser.name,
                                  );
                              if (!context.mounted) return;
                              if (success) {
                                Utils.showSnackbar('Success', 'Loan added successfully!', isError: false);
                                Get.offAllNamed(RoutesName.homeView, arguments: {'index': 2});
                              } else {
                                final error = context.read<LoanCubit>().state.errorMessage ?? 'Failed to add loan';
                                Utils.showSnackbar('Error', error);
                              }
                            }
                          }
                        },
                        borderRadius: 18,
                      );
                    },
                  ),
                  const SizedBox(height: 40),

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
    final theme = Theme.of(context);

    return BlocBuilder<LoanCubit, LoanState>(
      builder: (context, state) {
        final recentLoans = state.loans.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'recent_transactions'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                state.loans.length > 5
                    ? GestureDetector(
                        onTap: () =>
                            Get.offNamed(RoutesName.addLendBorrowView, arguments: {
                          'myUser': widget.myUser,
                          'index': type == 'lent' ? 0 : 1,
                        }),
                        child: Text(
                          'view_all'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.indigo.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 16),
            if (recentLoans.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 50, color: theme.disabledColor.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text(
                        "no_loan_records".tr,
                        style:
                            TextStyle(color: theme.disabledColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: recentLoans.map((loan) {
                  final isLent = loan.type == 'lent';
                  final color = isLent ? AppColors.green : AppColors.orange;
                  final icon = isLent ? Icons.arrow_upward : Icons.arrow_downward;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.personName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(loan.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isLent ? "Lent" : "Borrowed",
                                      style: TextStyle(
                                        fontSize: 9,
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
                                fontSize: 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loan.paymentMode ?? 'N/A',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
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
