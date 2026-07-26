import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'pressable_scale.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  final ExpenseController expenseController = Get.find<ExpenseController>();
  final IncomeController incomeController = Get.find<IncomeController>();
  final LoanController loanController = Get.find<LoanController>();

  // Reactive state for balance visibility and active filter
  final RxBool isBalanceVisible = true.obs;
  final RxString selectedFilter = 'This Month'.obs;

  bool _isWithinFilter(DateTime date, String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'This Week':
        final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysToSubtract));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfWeek);
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      case 'This Year':
        return date.year == now.year;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A10E1), // Violet / Deep Purple
            Color(0xFF1E60E6), // Rich Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E60E6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Overlapping Card Watermarks
            Positioned(
              right: -45,
              bottom: -25,
              child: Transform.rotate(
                angle: -0.22,
                child: Container(
                  width: 160,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Icon(Icons.currency_rupee,
                          color: Colors.white.withOpacity(0.05), size: 40),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -15,
              bottom: 18,
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  width: 145,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.08), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Icon(Icons.currency_rupee,
                          color: Colors.white.withOpacity(0.05), size: 30),
                    ),
                  ),
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'total_balance'.tr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(() => PressableScale(
                                onTap: () => isBalanceVisible.toggle(),
                                child: Icon(
                                  isBalanceVisible.value
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              )),
                        ],
                      ),
                      // Dropdown filter button
                      Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: const Color(0xFF1E60E6),
                        ),
                        child: PopupMenuButton<String>(
                          initialValue: selectedFilter.value,
                          onSelected: (String value) {
                            selectedFilter.value = value;
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (BuildContext context) {
                            return ['This Week', 'This Month', 'This Year']
                                .map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(
                                  choice,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          child: Obx(() => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedFilter.value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 14),
                                  ],
                                ),
                              )),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final filter = selectedFilter.value;
                    double totalIncome = incomeController.incomeList
                        .where((item) =>
                            _isWithinFilter(item['date'] as DateTime, filter))
                        .fold(
                            0.0,
                            (sum, item) =>
                                sum + (item['amount'] as num).toDouble());
                    double totalExpense = expenseController.expensesList
                        .where((item) =>
                            _isWithinFilter(item['date'] as DateTime, filter))
                        .fold(
                            0.0,
                            (sum, item) =>
                                sum + (item['amount'] as num).toDouble());
                    double balance = totalIncome - totalExpense;
                    return Text(
                      isBalanceVisible.value
                          ? '₹ ${NumberFormat('#,##,##0.00').format(balance)}'
                          : '₹ *******',
                      style: const TextStyle(
                        fontSize: 34,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _balanceStatItem(
                        icon: Icons.arrow_upward_rounded,
                        label: "lent_label".tr,
                        color: Colors.greenAccent.shade400,
                        amountObx: () {
                          final filter = selectedFilter.value;
                          return loanController.lent
                              .where(
                                  (item) => _isWithinFilter(item.date, filter))
                              .fold(
                                  0.0,
                                  (sum, item) =>
                                      sum +
                                      (item.amount - item.paidAmount.value));
                        },
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      _balanceStatItem(
                        icon: Icons.arrow_downward_rounded,
                        label: "borrowed_label".tr,
                        color: Colors.redAccent.shade200,
                        amountObx: () {
                          final filter = selectedFilter.value;
                          return loanController.borrowed
                              .where(
                                  (item) => _isWithinFilter(item.date, filter))
                              .fold(
                                  0.0,
                                  (sum, item) =>
                                      sum +
                                      (item.amount - item.paidAmount.value));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(color: Colors.white24, height: 1, thickness: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _balanceStatItem(
                        icon: Icons.arrow_upward_rounded,
                        label: "income".tr,
                        color: Colors.greenAccent.shade400,
                        amountObx: () {
                          final filter = selectedFilter.value;
                          return incomeController.incomeList
                              .where((item) => _isWithinFilter(
                                  item['date'] as DateTime, filter))
                              .fold(
                                  0.0,
                                  (sum, item) =>
                                      sum + (item['amount'] as num).toDouble());
                        },
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      _balanceStatItem(
                        icon: Icons.arrow_downward_rounded,
                        label: "expense".tr,
                        color: Colors.redAccent.shade200,
                        amountObx: () {
                          final filter = selectedFilter.value;
                          return expenseController.expensesList
                              .where((item) => _isWithinFilter(
                                  item['date'] as DateTime, filter))
                              .fold(
                                  0.0,
                                  (sum, item) =>
                                      sum + (item['amount'] as num).toDouble());
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceStatItem(
      {required IconData icon,
      required String label,
      required Color color,
      required double Function() amountObx}) {
    return Expanded(
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Obx(() => Text(
                      isBalanceVisible.value
                          ? '₹${amountObx().toStringAsFixed(0)}'
                          : '₹ *******',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }
}
