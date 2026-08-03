import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/modules/business/controllers/business_home_controller.dart';
import 'package:spendly/app/modules/expense/controllers/expense_controller.dart';
import 'package:spendly/app/modules/expense/controllers/income_controller.dart';
import 'package:spendly/app/modules/loan/controllers/loan_controller.dart';
import 'package:spendly/app/modules/premium/controllers/payment_controller.dart';
import 'package:spendly/app/data/models/myuser.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/modules/business/views/business_home_view.dart';
import 'package:spendly/app/modules/home/widgets/balance_card.dart';
import 'package:spendly/app/modules/home/widgets/home_app_bar.dart';
import 'package:spendly/app/modules/home/widgets/overview_cards_list.dart';
import 'package:spendly/app/modules/home/widgets/premium_insights_banner.dart';
import 'package:spendly/app/modules/home/widgets/pressable_scale.dart';
import 'package:spendly/app/modules/home/widgets/quick_actions_row.dart';
import 'package:spendly/app/modules/home/widgets/recent_transactions_list.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key, required this.myUser});
  final MyUser myUser;

  final ExpenseController expenseController = Get.find<ExpenseController>();
  final IncomeController incomeController = Get.find<IncomeController>();
  final LoanController loanController = Get.find<LoanController>();
  final BusinessHomeController businessController =
      Get.find<BusinessHomeController>();
  final PaymentController paymentController = Get.put(PaymentController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            businessController.fetchSummary(),
            loanController.fetchLoans(),
            paymentController.checkPremiumStatus(),
            expenseController.fetchExpenses(forceRefresh: true),
            incomeController.fetchIncomes(forceRefresh: true),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeAppBar(myUser: myUser),
              const SizedBox(height: 20),
              BalanceCard(),
              const SizedBox(height: 20),
              const QuickActionsRow(),
              const SizedBox(height: 24),
              _buildOverviewHeader(context),
              const SizedBox(height: 12),
              OverviewCardsList(),
              const SizedBox(height: 24),
              _buildTransactionHeader(context),
              const SizedBox(height: 12),
              RecentTransactionsList(),
              const SizedBox(height: 24),
              Obx(() => paymentController.isPremium.value
                  ? const SizedBox.shrink()
                  : PremiumInsightsBanner()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Overview",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        PressableScale(
          onTap: () => Get.toNamed(RoutesName.businessHome),
          child: Row(
            children: [
              Text(
                "View All",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.indigo.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.indigo.shade600, size: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'recent_transactions'.tr,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        PressableScale(
          onTap: () => Get.toNamed(RoutesName.viewAllExpenses),
          child: Row(
            children: [
              Text(
                'view_history'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.indigo.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.indigo.shade600, size: 10),
            ],
          ),
        ),
      ],
    );
  }
}
