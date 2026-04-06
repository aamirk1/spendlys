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

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'income'.tr,
                    amount: totalMonthlyIncome,
                    color: AppColors.green,
                    icon: Icons.arrow_upward_rounded,
                    isLoading: incomeController.isLoading.value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'expense'.tr,
                    amount: totalMonthlyExpense,
                    color: AppColors.red,
                    icon: Icons.arrow_downward_rounded,
                    isLoading: expenseController.isLoading.value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBalanceCard(
                context,
                balance,
                incomeController.isLoading.value ||
                    expenseController.isLoading.value),
          ],
        );
      }),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, double balance, bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: balance >= 0
              ? [Colors.blue.shade400, Colors.blue.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (balance >= 0 ? Colors.blue : Colors.orange).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    net_balance.tr,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  if (isLoading)
                    const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                  else
                    Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          Icon(
            balance >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isLoading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
