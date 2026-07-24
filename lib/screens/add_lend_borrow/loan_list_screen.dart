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
import 'package:spendly/res/routes/routes_name.dart';

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
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoanController());

    int initialIndex = 0;
    if (Get.arguments is Map && Get.arguments['index'] != null) {
      initialIndex = Get.arguments['index'];
    }
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF5F33E1); // Premium Deep Purple/Indigo

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed(RoutesName.homeView);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "digital_ledger_title".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Track your lent & borrowed bills",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => controller.fetchLoans(),
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSummaryHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildTabSelector(),
            const SizedBox(height: 12),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Get.to(() => AddLoanScreen(
              myUser: widget.myUser,
              controller: controller,
            )),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("new_ledger_btn".tr,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 2,
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final Color primaryColor = const Color(0xFF5F33E1);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() {
        final netBalance = controller.totalLent - controller.totalBorrowed;
        final isPositive = netBalance >= 0;

        return Column(
          children: [
            // Side-by-side cards: Lent vs Borrowed
            Row(
              children: [
                _summaryMiniCard(
                  "lent_label".tr,
                  controller.totalLent,
                  Colors.green,
                  Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 14),
                _summaryMiniCard(
                  "borrowed_label".tr,
                  controller.totalBorrowed,
                  Colors.orange,
                  Icons.arrow_downward_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Net balance banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive ? Icons.account_balance_wallet_outlined : Icons.report_gmailerrorred_rounded,
                          color: isPositive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "net_balance".tr,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "₹${NumberFormat('#,##,###').format(netBalance.abs())}",
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
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
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              child: Text(
                "₹${NumberFormat('#,##,###').format(amount)}",
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    final Color primaryColor = const Color(0xFF5F33E1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
            style:
                TextStyle(color: Theme.of(context).disabledColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    final Color primaryColor = const Color(0xFF5F33E1);
    
    return Obx(() {
      final progress = (loan.paidAmount.value / loan.amount).clamp(0.0, 1.0);
      final remaining = loan.amount - loan.paidAmount.value;
      final isOverdue = loan.expectedReturnDate != null &&
          loan.expectedReturnDate!.isBefore(DateTime.now()) &&
          loan.status.value != 'paid';

      // Hash-based dynamic color for circle avatar
      final String name = loan.personName;
      final int hash = name.codeUnits.fold(0, (sum, code) => sum + code);
      final List<Color> colorsList = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.red];
      final Color avatarColor = colorsList[hash % colorsList.length];

      return GestureDetector(
        onTap: () =>
            Get.to(() => LoanDetailScreen(loan: loan, controller: controller)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    color: _getStatusColor(loan.status.value, isOverdue),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: avatarColor.withOpacity(0.12),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                                  style: TextStyle(
                                      color: avatarColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.personName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      DateFormat('dd MMM yyyy').format(loan.date),
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    if (loan.creatorName != null &&
                                        loan.userId != widget.myUser.userId)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          "${'created_by'.tr}: ${loan.creatorName}",
                                          style: TextStyle(
                                              color: primaryColor,
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "₹${NumberFormat('#,##,###').format(loan.amount)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildStatusBadge(
                                      loan.status.value, isOverdue),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Progress bar info row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                  children: [
                                    TextSpan(text: "${'paid_label'.tr}: "),
                                    TextSpan(
                                      text:
                                          "₹${NumberFormat('#,###').format(loan.paidAmount.value)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${(progress * 100).toInt()}% ${'done_label'.tr}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: progress == 1.0
                                      ? Colors.green
                                      : primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Custom premium progress bar
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        remaining == 0
                                            ? Colors.green
                                            : primaryColor,
                                        remaining == 0
                                            ? Colors.greenAccent
                                            : primaryColor.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Remaining details row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (loan.expectedReturnDate != null)
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month_outlined,
                                        size: 13,
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOverdue
                                          ? "overdue_label".tr
                                          : "${'due_label'.tr}: ${DateFormat('dd MMM').format(loan.expectedReturnDate!)}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.grey.shade500,
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
                                "${"remaining_label".tr}: ₹${NumberFormat('#,###').format(remaining)}",
                                style: TextStyle(
                                    fontSize: 11,
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
