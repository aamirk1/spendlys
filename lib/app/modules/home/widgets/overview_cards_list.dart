import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/modules/expense/controllers/expense_controller.dart';
import 'package:spendly/app/modules/expense/controllers/income_controller.dart';
import 'package:spendly/app/modules/loan/controllers/loan_controller.dart';
import 'package:spendly/app/modules/business/views/business_home_view.dart';
import 'package:spendly/app/modules/home/widgets/overview_sparkline_card.dart';

class OverviewCardsList extends StatelessWidget {
  OverviewCardsList({super.key});

  final ExpenseController expenseController = Get.find<ExpenseController>();
  final IncomeController incomeController = Get.find<IncomeController>();
  final LoanController loanController = Get.find<LoanController>();
  final BusinessHomeController businessController = Get.find<BusinessHomeController>();

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<double> getWeeklyTrends(List<Map<String, dynamic>> items) {
    final Map<int, double> dayTotals = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      dayTotals[day.day] = 0.0;
    }
    for (var item in items) {
      final DateTime date = item['date'];
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        dayTotals[date.day] = (dayTotals[date.day] ?? 0.0) + item['amount'];
      }
    }
    final sortedDays = dayTotals.keys.toList()..sort();
    final list = sortedDays.map((d) => dayTotals[d]!).toList();
    if (list.every((v) => v == 0.0)) {
      return [1.0, 1.5, 1.2, 2.0, 1.8, 2.5, 2.0];
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          OverviewSparklineCard(
            title: "Today's Income",
            color: Colors.green.shade600,
            bgColor: Colors.green.shade50.withValues(alpha: 0.4),
            icon: CupertinoIcons.folder_badge_plus,
            amountObx: () => incomeController.incomeList
                .where((e) => isToday(e['date']))
                .fold(0.0, (sum, e) => sum + e['amount']),
            trendDataObx: () => getWeeklyTrends(incomeController.incomeList),
          ),
          const SizedBox(width: 12),
          OverviewSparklineCard(
            title: "Today's Expense",
            color: Colors.red.shade600,
            bgColor: Colors.red.shade50.withValues(alpha: 0.4),
            icon: CupertinoIcons.arrow_down_right_circle,
            amountObx: () => expenseController.expensesList
                .where((e) => isToday(e['date']))
                .fold(0.0, (sum, e) => sum + e['amount']),
            trendDataObx: () => getWeeklyTrends(expenseController.expensesList),
          ),
          const SizedBox(width: 12),
          OverviewSparklineCard(
            title: "Pending Invoices",
            color: Colors.orange.shade700,
            bgColor: Colors.orange.shade50.withValues(alpha: 0.4),
            icon: Icons.receipt_long_rounded,
            amountObx: () => businessController.pendingAmount,
            trendDataObx: () => [1.0, 1.2, 1.1, 1.5, 1.3, 1.8, 1.4],
          ),
          const SizedBox(width: 12),
          OverviewSparklineCard(
            title: "Loan Due",
            color: Colors.deepPurple.shade600,
            bgColor: Colors.deepPurple.shade50.withValues(alpha: 0.4),
            icon: Icons.history_toggle_off_rounded,
            amountObx: () => loanController.totalBorrowed,
            trendDataObx: () => [2.0, 1.8, 2.2, 1.5, 2.0, 1.7, 2.5],
          ),
        ],
      ),
    );
  }
}
