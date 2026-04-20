import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/screens/add_income_and_expense/add_expense.dart';
import 'package:spendly/screens/add_income_and_expense/add_income.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';

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
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
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
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF1E293B), size: 18),
                    ),
                  ),
                  const Text(
                    "Balance Overview",
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              Obx(() {
                final totalIncome = incomeController.incomeList.fold<double>(
                    0, (sum, item) => sum + (item['amount'] as double));
                final totalExpense = expenseController.expensesList
                    .fold<double>(
                        0, (sum, item) => sum + (item['amount'] as double));
                final balance = totalIncome - totalExpense;

                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "current_balance".tr,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "₹${NumberFormat('#,##,###.##').format(balance)}",
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          _buildSummaryItem(
                            "income".tr,
                            totalIncome,
                            const Color(0xFF22C55E), // Emerald Green
                            Icons.trending_up_rounded,
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.withOpacity(0.15)),
                          _buildSummaryItem(
                            "expense".tr,
                            totalExpense,
                            const Color(0xFFF97316), // Orange
                            Icons.trending_down_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 10, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              "₹${NumberFormat('#,###').format(amount)}",
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
          color: const Color(0xFFE2E8F0).withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
