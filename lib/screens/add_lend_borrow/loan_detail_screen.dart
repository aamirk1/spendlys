import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/res/components/custom_button.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/screens/add_lend_borrow/widgets/loan_details_screen_widgets/payment_history_card.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/utils/colors.dart';
import 'add_loan_screen.dart';
import 'package:spendly/models/myuser.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;
  final LoanController controller;

  const LoanDetailScreen(
      {required this.loan, required this.controller, super.key});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          "loan_details".tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => Get.to(() => AddLoanScreen(
                  myUser: MyUser(
                    userId: widget.loan.userId,
                    name: '',
                    email: '',
                    phoneNumber: '',
                    lastLogin: Timestamp.fromDate(widget.loan.date),
                  ),
                  controller: widget.controller,
                  loan: widget.loan,
                )),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAnimatedPremiumHeader(context),
            _buildAnimatedSummaryCards(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActionsHeader(context),
                      const SizedBox(height: 20),
                      _buildQuickActionGrid(context),
                      const SizedBox(height: 30),
                      PaymentHistoryCard(loan: widget.loan),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPremiumHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Obx(() {
            final percentagePaid = widget.loan.amount > 0
                ? (widget.loan.paidAmount.value / widget.loan.amount)
                : 0.0;
            final clampedPercentage = percentagePaid.clamp(0.0, 1.0);

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clampedPercentage),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 12.0,
                  percent: value.clamp(0.0, 1.0),
                  animation: false,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  progressColor: AppColors.primary,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${(value.clamp(0.0, 1.0) * 100).toInt()}%",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "paid_label".tr,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: Text(
              widget.loan.personName,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.loan.type == 'lent' ? "lent_to".tr : "borrowed_from".tr,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _buildAnimatedSummaryCards(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.translate(
        offset: const Offset(0, -50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem(
                      context,
                      "total_loan".tr,
                      widget.loan.amount,
                      AppColors.primary,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    Obx(() => _summaryItem(
                          context,
                          "paid_label".tr,
                          widget.loan.paidAmount.value,
                          AppColors.success,
                          icon: Icons.check_circle_outline,
                        )),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem(
                      context,
                      "due_date".tr,
                      widget.loan.expectedReturnDate,
                      AppColors.warning,
                      isDate: true,
                      icon: Icons.calendar_today_outlined,
                    ),
                    Obx(() {
                      final remaining =
                          widget.loan.amount - widget.loan.paidAmount.value;
                      return _summaryItem(
                        context,
                        "remaining_label".tr,
                        remaining,
                        AppColors.error,
                        icon: Icons.pending_outlined,
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String title,
    dynamic value,
    Color color, {
    bool isDate = false,
    IconData? icon,
  }) {
    String displayValue = "";
    if (isDate) {
      displayValue =
          value != null ? DateFormat('dd MMM, yyyy').format(value) : "na".tr;
    } else {
      displayValue = "₹${NumberFormat('#,##,###').format(value)}";
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color.withOpacity(0.7)),
                const SizedBox(width: 4),
              ],
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayValue,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "quick_actions".tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.bolt, color: AppColors.primary, size: 20),
        ),
      ],
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    return Row(
      children: [
        _betterActionButton(
          context,
          "record_payment".tr,
          Icons.add_circle_outline,
          AppColors.primary,
          () => _showPaymentSheet(context),
        ),
        const SizedBox(width: 16),
        _betterActionButton(
          context,
          "pay_full".tr,
          Icons.verified_outlined,
          AppColors.success,
          () => _markAsFullyPaid(context),
        ),
      ],
    );
  }

  Widget _betterActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.12),
                color.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    final amountController = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "record_payment".tr,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "how_much_paid".tr,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.currency_rupee, size: 28),
                ),
                hintText: "0.00",
                filled: true,
                fillColor: Theme.of(context).dividerColor.withOpacity(0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: "record_payment".tr.toUpperCase(),
              height: 60,
              borderRadius: 20,
              onPressed: () {
                final amt = double.tryParse(amountController.text);
                if (amt != null && amt > 0) {
                  widget.controller.updatePayment(widget.loan.id, amt);
                  Get.back();
                  Utils.showSnackbar("success".tr, "payment_recorded_msg".tr);
                } else {
                  Utils.showSnackbar("error".tr, "enter_amount_hint".tr);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _markAsFullyPaid(BuildContext context) {
    final remaining = widget.loan.amount - widget.loan.paidAmount.value;
    if (remaining <= 0) {
      Utils.showSnackbar("info".tr, "loan_fully_paid_msg".tr);
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "clear_full_balance".tr,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "${"clear_balance_desc".tr} ₹${NumberFormat('#,###').format(remaining)}.",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "cancel_btn".tr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          CustomButton(
            onPressed: () async {
              await widget.controller.updatePayment(widget.loan.id, remaining);
              Get.back();
              Utils.showSnackbar("success".tr, "loan_fully_paid_msg".tr);
            },
            backgroundColor: AppColors.success,
            text: "confirm_btn".tr,
            width: 140,
            height: 48,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "delete_record_title".tr,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text("delete_record_desc".tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "cancel_btn".tr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          CustomButton(
            onPressed: () async {
              await widget.controller.deleteLoan(widget.loan.id);
            },
            backgroundColor: Colors.redAccent,
            text: "delete_btn".tr,
            width: 140,
            height: 48,
          ),
        ],
      ),
    );
  }
}
