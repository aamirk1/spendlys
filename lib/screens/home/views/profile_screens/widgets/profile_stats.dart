import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/utils/colors.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    final ExpenseController expenseController = Get.find<ExpenseController>();
    final IncomeController incomeController = Get.find<IncomeController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Obx(() {
        // Simple Monthly Summary Calculation
        double totalMonthlyIncome = 0;
        double totalMonthlyExpense = 0;
        final now = DateTime.now();

        for (var inc in incomeController.incomeList) {
          final date = inc['date'] as DateTime;
          if (date.month == now.month && date.year == now.year) {
            totalMonthlyIncome += inc['amount'];
          }
        }

        for (var exp in expenseController.expensesList) {
          final date = exp['date'] as DateTime;
          if (date.month == now.month && date.year == now.year) {
            totalMonthlyExpense += exp['amount'];
          }
        }

        double balance = totalMonthlyIncome - totalMonthlyExpense;
        bool isLoading = incomeController.isLoading.value || expenseController.isLoading.value;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Balance display
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'net_balance'.tr.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.5),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (isLoading)
                          const SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        else
                          Text(
                            '₹${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0
                                  ? (Get.isDarkMode ? Colors.green.shade400 : AppColors.green)
                                  : (Get.isDarkMode ? Colors.red.shade400 : AppColors.red),
                            ),
                          ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (balance >= 0 ? Colors.green : Colors.red).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        balance >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: balance >= 0 ? AppColors.green : AppColors.red,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Thin visual divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),

              // Income / Expense row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Income
                    Expanded(
                      child: _buildSubStat(
                        context,
                        title: 'income'.tr,
                        amount: totalMonthlyIncome,
                        color: AppColors.green,
                        icon: Icons.arrow_downward_rounded,
                        isLoading: isLoading,
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 40,
                      width: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),

                    // Expense
                    Expanded(
                      child: _buildSubStat(
                        context,
                        title: 'expense'.tr,
                        amount: totalMonthlyExpense,
                        color: AppColors.red,
                        icon: Icons.arrow_upward_rounded,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSubStat(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (isLoading)
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                else
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
