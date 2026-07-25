import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';

class RecentTransactionsList extends StatelessWidget {
  RecentTransactionsList({super.key});

  final ExpenseController expenseController = Get.find<ExpenseController>();
  final IncomeController incomeController = Get.find<IncomeController>();

  Map<String, dynamic> getCategoryDetails(String category, String type) {
    if (type == 'expense') {
      final cat = expenseController.expenseCategories.firstWhere(
        (e) => e['name'] == category,
        orElse: () => {'icon': Icons.category, 'color': Colors.grey},
      );
      return {
        'icon': cat['icon'] as IconData,
        'color': cat['color'] as Color,
      };
    } else {
      final cat = incomeController.incomeCategories.firstWhere(
        (e) => e['name'] == category,
        orElse: () =>
            {'icon': CupertinoIcons.question_circle_fill, 'color': Colors.grey},
      );
      return {
        'icon': cat['icon'] as IconData,
        'color': cat['color'] as Color,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expenses = expenseController.expensesList;
      final incomes = incomeController.incomeList;

      final List<Map<String, dynamic>> allTransactions = [];
      for (var e in expenses) {
        allTransactions.add({...e, 'type': 'expense'});
      }
      for (var i in incomes) {
        allTransactions.add({...i, 'type': 'income'});
      }

      allTransactions.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (allTransactions.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 50, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                "no_transactions".tr,
                style: TextStyle(
                    color: Theme.of(context).disabledColor, fontSize: 13),
              ),
            ],
          ),
        );
      }

      final recentList = allTransactions.take(5).toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentList.length,
          separatorBuilder: (context, index) =>
              Divider(color: Colors.grey.shade100, height: 1),
          itemBuilder: (context, index) {
            final tx = recentList[index];
            final type = tx['type'];
            final category = tx['category'];
            final amount = tx['amount'] as double;
            final date = tx['date'] as DateTime;

            final details = getCategoryDetails(category, type);
            final icon = details['icon'] as IconData;
            final iconColor = details['color'] as Color;

            final isIncome = type == 'income';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: iconColor.withOpacity(0.12),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('dd MMM').format(date)} • ${isIncome ? "income".tr : "expense".tr}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              isIncome ? Colors.green.shade700 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isIncome
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                        color: isIncome
                          ? Colors.green.shade600
                          : Colors.red.shade400,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.grey.shade300, size: 10),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
