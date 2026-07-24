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
import 'package:spendly/controllers/payment_controller.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key, required this.myUser});
  final MyUser myUser;

  final ExpenseController expenseController = Get.find<ExpenseController>();
  final IncomeController incomeController = Get.find<IncomeController>();
  final LoanController loanController = Get.find<LoanController>();
  final BusinessHomeController businessController =
      Get.find<BusinessHomeController>();
  final PaymentController paymentController = Get.put(PaymentController());

  // Reactive state for balance visibility
  final RxBool isBalanceVisible = true.obs;

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

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning ☀️";
    } else if (hour < 17) {
      return "Good Afternoon 🌤️";
    } else if (hour < 21) {
      return "Good Evening 🌆";
    } else {
      return "Good Night 🌙";
    }
  }

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
              _buildAppBar(context),
              const SizedBox(height: 20),
              _buildBalanceCard(context),
              const SizedBox(height: 20),
              _buildQuickActionsRow(context),
              const SizedBox(height: 24),
              _buildOverviewHeader(context),
              const SizedBox(height: 12),
              _buildOverviewCardsList(context),
              const SizedBox(height: 24),
              _buildTransactionHeader(context),
              const SizedBox(height: 12),
              _buildTransactionsList(context),
              const SizedBox(height: 24),
              Obx(() => paymentController.isPremium.value
                  ? const SizedBox.shrink()
                  : _buildPremiumInsightsBanner(context)),
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
            PressableScale(
              onTap: () =>
                  Get.toNamed(RoutesName.profileView, arguments: myUser),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.shade500,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  (myUser.name.isNotEmpty) ? myUser.name[0].toUpperCase() : "?",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getGreeting(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  myUser.name.isNotEmpty ? myUser.name : "Guest User",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  DateFormat('EEEE, d MMM').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            PressableScale(
              onTap: () => Get.toNamed(RoutesName.notificationsScreen),
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(Icons.notifications_none_rounded,
                        color: Colors.grey.shade800, size: 24),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "3",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PressableScale(
              onTap: () => Get.toNamed(RoutesName.chatListView),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(CupertinoIcons.chat_bubble_2,
                    color: Colors.indigo.shade400, size: 24),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'This Month',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white, size: 14),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    double totalIncome = incomeController.categoryTotals.values
                        .fold(0, (sum, value) => sum + value);
                    double totalExpense = expenseController
                        .categoryTotals.values
                        .fold(0, (sum, value) => sum + value);
                    double balance = totalIncome - totalExpense;
                    return Text(
                      isBalanceVisible.value
                          ? '₹ ${NumberFormat('#,##,##0.00').format(balance)}'
                          : '₹ ••••••••',
                      style: const TextStyle(
                        fontSize: 34,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  PressableScale(
                    onTap: () => Get.toNamed(RoutesName.viewAllExpenses),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white, size: 9),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1, thickness: 1),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _balanceStatItem(
                        icon: Icons.arrow_upward_rounded,
                        label: "income".tr,
                        color: Colors.greenAccent.shade400,
                        amountObx: () => incomeController.categoryTotals.values
                            .fold(0, (sum, value) => sum + value),
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
                        amountObx: () => expenseController.categoryTotals.values
                            .fold(0, (sum, value) => sum + value),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      _balanceStatItem(
                        icon: CupertinoIcons.folder_badge_plus,
                        label: "Savings",
                        color: Colors.blueAccent.shade100,
                        amountObx: () {
                          double inc = incomeController.categoryTotals.values
                              .fold(0, (s, v) => s + v);
                          double exp = expenseController.categoryTotals.values
                              .fold(0, (s, v) => s + v);
                          double diff = inc - exp;
                          return diff > 0 ? diff : 0.0;
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
                      '₹${amountObx().toStringAsFixed(0)}',
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

  Widget _buildQuickActionsRow(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionButton(
            icon: Icons.file_download_outlined,
            label: "Add Income",
            color: Colors.green,
            bgColor: Colors.green.shade50,
            onTap: () => Get.toNamed(RoutesName.incomeExpenseHome,
                arguments: {'initialIndex': 0}),
          ),
          _quickActionDivider(),
          _quickActionButton(
            icon: CupertinoIcons.arrow_right_arrow_left,
            label: "Add Expense",
            color: Colors.redAccent,
            bgColor: Colors.red.shade50,
            onTap: () => Get.toNamed(RoutesName.incomeExpenseHome,
                arguments: {'initialIndex': 1}),
          ),
          _quickActionDivider(),
          _quickActionButton(
            icon: Icons.receipt_long_outlined,
            label: "Create Invoice",
            color: Colors.orange,
            bgColor: Colors.orange.shade50,
            onTap: () => Get.toNamed(RoutesName.createInvoice),
          ),
          _quickActionDivider(),
          _quickActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: "Scan & Pay",
            color: Colors.deepPurple,
            bgColor: Colors.deepPurple.shade50,
            onTap: () => _showScanPaySimulator(context),
          ),
        ],
      ),
    );
  }

  Widget _quickActionDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade100,
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
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

  Widget _buildOverviewCardsList(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _overviewSparklineCard(
            context,
            title: "Today's Income",
            color: Colors.green.shade600,
            bgColor: Colors.green.shade50.withOpacity(0.4),
            icon: CupertinoIcons.folder_badge_plus,
            amountObx: () => incomeController.incomeList
                .where((e) => isToday(e['date']))
                .fold(0.0, (sum, e) => sum + e['amount']),
            trendDataObx: () => getWeeklyTrends(incomeController.incomeList),
          ),
          const SizedBox(width: 12),
          _overviewSparklineCard(
            context,
            title: "Today's Expense",
            color: Colors.red.shade600,
            bgColor: Colors.red.shade50.withOpacity(0.4),
            icon: CupertinoIcons.arrow_down_right_circle,
            amountObx: () => expenseController.expensesList
                .where((e) => isToday(e['date']))
                .fold(0.0, (sum, e) => sum + e['amount']),
            trendDataObx: () => getWeeklyTrends(expenseController.expensesList),
          ),
          const SizedBox(width: 12),
          _overviewSparklineCard(
            context,
            title: "Pending Invoices",
            color: Colors.orange.shade700,
            bgColor: Colors.orange.shade50.withOpacity(0.4),
            icon: Icons.receipt_long_rounded,
            amountObx: () => businessController.pendingAmount.value,
            trendDataObx: () => [1.0, 1.2, 1.1, 1.5, 1.3, 1.8, 1.4],
          ),
          const SizedBox(width: 12),
          _overviewSparklineCard(
            context,
            title: "Loan Due",
            color: Colors.deepPurple.shade600,
            bgColor: Colors.deepPurple.shade50.withOpacity(0.4),
            icon: Icons.history_toggle_off_rounded,
            amountObx: () => loanController.totalBorrowed,
            trendDataObx: () => [2.0, 1.8, 2.2, 1.5, 2.0, 1.7, 2.5],
          ),
        ],
      ),
    );
  }

  Widget _overviewSparklineCard(
    BuildContext context, {
    required String title,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required double Function() amountObx,
    required List<double> Function() trendDataObx,
  }) {
    return PressableScale(
      onTap: () {
        if (title.contains("Income")) {
          Get.toNamed(RoutesName.viewAllIncome);
        } else if (title.contains("Expense")) {
          Get.toNamed(RoutesName.viewAllExpenses);
        } else if (title.contains("Invoice")) {
          Get.toNamed(RoutesName.businessHome);
        } else {
          Get.toNamed(RoutesName.addLendBorrowView, arguments: {'index': 0});
        }
      },
      child: Container(
        width: 135,
        height: 125,
        padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            Obx(() => Text(
                  '₹${amountObx().toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )),
            const Spacer(),
            Obx(() {
              final trend = trendDataObx();
              return SizedBox(
                width: double.infinity,
                height: 30,
                child: CustomPaint(
                  painter: SparklinePainter(data: trend, color: color),
                ),
              );
            }),
          ],
        ),
      ),
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

  Widget _buildTransactionsList(BuildContext context) {
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

  Widget _buildPremiumInsightsBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5E35B1), // Deep Violet
            Color(0xFF3949AB), // Blue Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(RoutesName.premiumView),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grow your business with smart insights',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track, manage & grow your business better.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'See Insights',
                    style: TextStyle(
                      color: Color(0xFF5E35B1),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScanPaySimulator(BuildContext context) {
    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        bool isScanning = true;
        bool isSuccess = false;

        Future.delayed(const Duration(milliseconds: 2500), () {
          if (context.mounted) {
            setState(() {
              isScanning = false;
              isSuccess = true;
            });
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted) {
                Get.back();
                Get.snackbar(
                  'Simulated Payment Success',
                  '₹ 780.00 transferred successfully to Vishal!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 16,
                );
              }
            });
          }
        });

        return Container(
          height: 420,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan & Pay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                isScanning
                    ? 'Align code within the frame to scan'
                    : 'Simulating Payment Complete',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Center(
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: isScanning
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.indigo.shade400, width: 3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        const SizedBox(
                          width: 180,
                          height: 180,
                          child: ScannerLaserLine(),
                        ),
                        Icon(Icons.qr_code_2_rounded,
                            size: 100, color: Colors.grey.shade200),
                      ],
                    ),
                    secondChild: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade600, size: 44),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '₹ 780.00 Sent',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'to Vishal',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// Custom Painter to draw Bezier Sparklines with Gradient Fills
class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double range = maxVal - minVal;

    double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double normalizedY = range == 0 ? 0.5 : (data[i] - minVal) / range;
      // Map to 10% - 90% range to avoid clipping
      double y =
          size.height - (normalizedY * size.height * 0.7 + size.height * 0.15);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double prevX = (i - 1) * stepX;
        double prevNormalizedY =
            range == 0 ? 0.5 : (data[i - 1] - minVal) / range;
        double prevY = size.height -
            (prevNormalizedY * size.height * 0.7 + size.height * 0.15);

        double cx1 = prevX + stepX / 2;
        double cy1 = prevY;
        double cx2 = prevX + stepX / 2;
        double cy2 = y;

        path.cubicTo(cx1, cy1, cx2, cy2, x, y);
      }
    }

    // Draw background gradient fill under sparkline
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

// Scanner Laser Line animation widget
class ScannerLaserLine extends StatefulWidget {
  const ScannerLaserLine({super.key});

  @override
  State<ScannerLaserLine> createState() => _ScannerLaserLineState();
}

class _ScannerLaserLineState extends State<ScannerLaserLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: _animation.value * 180, // Height matching square box
              left: 10,
              right: 10,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade400,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade400.withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// High-fidelity physical press scale feedback widget
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PressableScale({super.key, required this.child, required this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller.value;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
