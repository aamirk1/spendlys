import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/screens/business/business_home_view.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key, required this.myUser});
  final MyUser myUser;

  final ExpenseController expenseController = Get.find<ExpenseController>();
  final IncomeController incomeController = Get.find<IncomeController>();
  final LoanController loanController = Get.find<LoanController>();
  final BusinessHomeController businessController = Get.find<BusinessHomeController>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            businessController.fetchSummary(),
            loanController.fetchLoans(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              const SizedBox(height: 25),
              RepaintBoundary(child: _buildBalanceCard(context)),
              const SizedBox(height: 30),
              _buildFeaturesOverview(context),
              const SizedBox(height: 30),
              _buildTransactionHeader(context),
              const SizedBox(height: 15),
              RepaintBoundary(child: _buildTransactionsList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () =>
                  Get.toNamed(RoutesName.profileView, arguments: myUser),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.indigo.shade400),
                  ),
                  Text(
                    (myUser.name.isNotEmpty)
                        ? myUser.name[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  )
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("welcome".tr,
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                Text(myUser.name,
                    style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color)),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Get.toNamed(RoutesName.chatListView),
          icon: Icon(CupertinoIcons.chat_bubble_2_fill,
              color: Colors.indigo.shade400, size: 28),
        )
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade700,
            Colors.deepPurple.shade600,
            Colors.blue.shade600
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59305ABF), // Colors.indigo ~35% opacity
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Text('total_balance'.tr,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Obx(() {
            double totalIncome = incomeController.categoryTotals.values
                .fold(0, (sum, value) => sum + value);
            double totalExpense = expenseController.categoryTotals.values
                .fold(0, (sum, value) => sum + value);
            return Text(
              '₹ ${(totalIncome - totalExpense).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 42,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            );
          }),
          const SizedBox(height: 25),
          Row(
            children: [
              _balanceStatItem(
                icon: CupertinoIcons.arrow_up_circle_fill,
                label: "income".tr,
                color: Colors.greenAccent.shade400,
                amountObx: () => incomeController.categoryTotals.values
                    .fold(0, (sum, value) => sum + value),
              ),
              Container(
                  width: 1,
                  height: 35,
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 20)),
              _balanceStatItem(
                icon: CupertinoIcons.arrow_down_circle_fill,
                label: "expense".tr,
                color: Colors.redAccent.shade200,
                amountObx: () => expenseController.categoryTotals.values
                    .fold(0, (sum, value) => sum + value),
              ),
            ],
          ),
        ],
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
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
              Obx(() => Text('₹ ${amountObx().toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeaturesOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("feature_modules".tr,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color)),
        const SizedBox(height: 15),
        Row(
          children: [
            _overviewCard(
              context,
              title: "business_center".tr,
              subtitle: "invoices_subtitle".tr,
              icon: Icons.storefront_rounded,
              color: Colors.blue.shade600,
              valueObx: () =>
                  "₹${businessController.totalRevenue.value.toStringAsFixed(0)} / ₹${businessController.pendingAmount.value.toStringAsFixed(0)}",
              onTap: () => Get.toNamed(RoutesName.businessHome),
            ),
            const SizedBox(width: 15),
            _overviewCard(
              context,
              title: "digital_ledger".tr,
              subtitle: "lent_borrowed".tr,
              icon: Icons.menu_book_rounded,
              color: Colors.orange.shade600,
              valueObx: () =>
                  "₹${loanController.totalLent.toStringAsFixed(0)} / ₹${loanController.totalBorrowed.toStringAsFixed(0)}",
              onTap: () =>
                  Get.toNamed(RoutesName.addLendBorrowView, arguments: myUser),
            ),
          ],
        ),
      ],
    );
  }

  Widget _overviewCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required String Function() valueObx,
      required VoidCallback onTap}) {
    return Expanded(
      child: RepaintBoundary(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000), // black ~4% opacity
                    blurRadius: 10,
                    offset: Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Obx(() => Text(valueObx(),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('recent_transactions'.tr,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color)),
        GestureDetector(
          onTap: () => Get.toNamed(RoutesName.viewAllExpenses),
          child: Text('view_history'.tr,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.indigo.shade600,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return Obx(() {
      final expenses = expenseController.expensesList;
      Map<String, double> categoryTotals = {};
      Map<String, DateTime> latestDatePerCategory = {};

      for (var expense in expenses) {
        String category = expense['category'];
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + expense['amount'];
        if (latestDatePerCategory[category] == null ||
            expense['date'].isAfter(latestDatePerCategory[category]!)) {
          latestDatePerCategory[category] = expense['date'];
        }
      }

      if (categoryTotals.isEmpty) {
        return Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text("no_transactions".tr,
                  style: TextStyle(color: Theme.of(context).disabledColor)),
            ],
          ),
        );
      }

      return Column(
        children: categoryTotals.keys.take(5).map((category) {
          final total = categoryTotals[category]!;
          final date = latestDatePerCategory[category]!;
          final categoryData = expenseController.expenseCategories.firstWhere(
            (e) => e['name'] == category,
            orElse: () => {'icon': Icons.category, 'color': Colors.grey},
          );

          return RepaintBoundary(
           child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x05000000), // black ~2% opacity
                    blurRadius: 5,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      (categoryData['color'] as Color).withOpacity(0.15),
                  child: Icon(categoryData['icon'] as IconData,
                      color: categoryData['color'] as Color, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color)),
                      Text(DateFormat('dd MMM').format(date),
                          style: TextStyle(
                              fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                ),
                Text("₹${total.toStringAsFixed(0)}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
           ),
          );
        }).toList(),
      );
    });
  }
}
