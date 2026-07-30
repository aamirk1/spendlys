import 'package:spendly/app/modules/expense/controllers/expense_controller.dart';
import 'package:spendly/app/modules/expense/controllers/income_controller.dart';
import 'package:spendly/app/modules/expense/views/add_expense_view.dart';
import 'package:spendly/app/modules/expense/views/add_income_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/app/utils/colors.dart';

class IncomeExpenseHome extends StatefulWidget {
  const IncomeExpenseHome({super.key});

  @override
  State<IncomeExpenseHome> createState() => _IncomeExpenseHomeState();
}

class _IncomeExpenseHomeState extends State<IncomeExpenseHome>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final incomeController = Get.find<IncomeController>();
  final expenseController = Get.find<ExpenseController>();

  @override
  void initState() {
    int initialIdx = 0;
    final args = Get.arguments;
    if (args is Map && args['initialIndex'] != null) {
      initialIdx = args['initialIndex'];
    } else if (args is int) {
      initialIdx = args;
    }
    tabController = TabController(initialIndex: initialIdx, length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
          child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildTabSelector(),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                AddIncome(),
                AddExpense(),
              ],
            ),
          )
        ],
      )),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B), size: 16),
            ),
          ),
          const Text(
            "Add Transaction",
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Obx(() {
            final totalIncome = incomeController.incomeList.fold<double>(
                0, (sum, item) => sum + (item['amount'] as double));
            final totalExpense = expenseController.expensesList
                .fold<double>(
                    0, (sum, item) => sum + (item['amount'] as double));
            final balance = totalIncome - totalExpense;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Bal: ₹${NumberFormat('#,###').format(balance)}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: "add_income".tr),
            Tab(text: "add_expense".tr),
          ],
        ),
      ),
    );
  }
}
