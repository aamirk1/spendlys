import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:intl/intl.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/utils/colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../controllers/loan_controller.dart';
import 'loan_detail_screen.dart';
import 'add_loan_screen.dart';

class LoansScreen extends StatefulWidget {
  final MyUser myUser;

  const LoansScreen({required this.myUser, super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  late final LoanController controller;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = "".obs;
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoanController());
    controller.fetchLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        backgroundColor: AppColors.primary,
        title: "digital_ledger_title".tr,
        actions: [
          IconButton(
            onPressed: () => controller.fetchLoans(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSummaryHeader(),
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildTabSelector(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoanList(isLent: true),
                    _buildLoanList(isLent: false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => AddLoanScreen(
              myUser: widget.myUser,
              controller: controller,
            )),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("new_ledger_btn".tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final netBalance = controller.totalLent - controller.totalBorrowed;
        final isPositive = netBalance >= 0;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).cardColor,
                    Theme.of(context).cardColor.withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "net_balance".tr,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${NumberFormat('#,##,###').format(netBalance.abs())}",
                            style: TextStyle(
                              color: isPositive ? Colors.green : Colors.red,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isPositive ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPositive ? "plus_msg".tr : "minus_msg".tr,
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  Row(
                    children: [
                      _summaryMiniCard(
                        "lent_label".tr,
                        controller.totalLent,
                        Colors.green,
                        Icons.arrow_upward_rounded,
                      ),
                      const SizedBox(width: 20),
                      _summaryMiniCard(
                        "borrowed_label".tr,
                        controller.totalBorrowed,
                        Colors.orange,
                        Icons.arrow_downward_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _summaryMiniCard(
      String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              "₹${NumberFormat('#,##,###').format(amount)}",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) => searchQuery.value = value,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: "search_person_hint".tr,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).disabledColor,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: "lent_label".tr),
            Tab(text: "borrowed_label".tr),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanList({required bool isLent}) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      final allSubList = isLent ? controller.lent : controller.borrowed;
      final filteredList = allSubList.where((loan) {
        return loan.personName
            .toLowerCase()
            .contains(searchQuery.value.toLowerCase());
      }).toList();

      if (filteredList.isEmpty) {
        return _buildEmptyState();
      }

      return AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final loan = filteredList[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildLoanCard(loan),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 60, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            searchQuery.value.isEmpty
                ? "ledger_empty".tr
                : "no_matching_records".tr,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.value.isEmpty
                ? "empty_ledger_desc".tr
                : "search_different_name".tr,
            style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    return Obx(() {
      final progress = (loan.paidAmount.value / loan.amount).clamp(0.0, 1.0);
      final remaining = loan.amount - loan.paidAmount.value;
      final isOverdue = loan.expectedReturnDate != null &&
          loan.expectedReturnDate!.isBefore(DateTime.now()) &&
          loan.status.value != 'paid';

      return GestureDetector(
        onTap: () =>
            Get.to(() => LoanDetailScreen(loan: loan, controller: controller)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    color: _getStatusColor(loan.status.value, isOverdue),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  loan.personName[0].toUpperCase(),
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.personName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(loan.date),
                                      style: TextStyle(
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${NumberFormat('#,##,###').format(loan.amount)}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Theme.of(context).textTheme.bodyLarge?.color),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildStatusBadge(
                                      loan.status.value, isOverdue),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color),
                                  children: [
                                    TextSpan(text: "${'paid_label'.tr}: "),
                                    TextSpan(
                                      text:
                                          "₹${NumberFormat('#,###').format(loan.paidAmount.value)}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${(progress * 100).toInt()}% ${'done_label'.tr}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: progress == 1.0
                                      ? Colors.green
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        remaining == 0
                                            ? Colors.green
                                            : AppColors.primary,
                                        remaining == 0
                                            ? Colors.greenAccent
                                            : AppColors.primary
                                                .withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (loan.expectedReturnDate != null)
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month_outlined,
                                        size: 14,
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOverdue
                                          ? "overdue_label".tr
                                          : "${'due_label'.tr}: ${DateFormat('dd MMM').format(loan.expectedReturnDate!)}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOverdue
                                            ? Colors.red
                                            : Theme.of(context).textTheme.bodySmall?.color,
                                        fontWeight: isOverdue
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox(),
                              Text(
                                "remaining_label".tr + ": ₹${NumberFormat('#,###').format(remaining)}",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: remaining == 0
                                        ? Colors.green
                                        : Colors.red.shade400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Color _getStatusColor(String status, bool isOverdue) {
    if (status == 'paid') return Colors.green;
    if (isOverdue) return Colors.red;
    if (status == 'partially paid') return Colors.blue;
    return Colors.orange;
  }

  Widget _buildStatusBadge(String status, bool isOverdue) {
    Color color = _getStatusColor(status, isOverdue);
    String label = status.toUpperCase();
    if (isOverdue && status != 'paid') label = "OVERDUE";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5),
      ),
    );
  }
}
