import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/models/myuser.dart';
import 'package:intl/intl.dart';
import 'package:spendly/app/utils/colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/app/data/services/whatsapp_service.dart';
import 'package:spendly/app/modules/loan/controllers/loan_controller.dart';
import 'package:spendly/app/modules/loan/views/loan_detail_view.dart';
import 'package:spendly/app/modules/loan/views/add_loan_view.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/data/models/loan_modal.dart';

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
  final RxString sortBy = "Recent".obs;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoanController());

    int initialIndex = 0;
    if (Get.arguments is Map && Get.arguments['index'] != null) {
      initialIndex = Get.arguments['index'];
    }
    // We map: 0 -> All, 1 -> You Lent, 2 -> You Borrowed
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: initialIndex.clamp(0, 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Loan> _getFilteredAndSortedLoans({required bool isLent}) {
    final allSubList = isLent ? controller.lent : controller.borrowed;
    final query = searchQuery.value.toLowerCase().trim();

    // Filter
    final filtered = allSubList.where((loan) {
      if (query.isEmpty) return true;
      final nameMatch = loan.personName.toLowerCase().contains(query);
      final phoneMatch =
          loan.personPhone?.toLowerCase().contains(query) ?? false;
      return nameMatch || phoneMatch;
    }).toList();

    // Sort
    if (sortBy.value == "Recent") {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    } else if (sortBy.value == "Oldest") {
      filtered.sort((a, b) => a.date.compareTo(b.date));
    } else if (sortBy.value == "Amount: High to Low") {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (sortBy.value == "Amount: Low to High") {
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (sortBy.value == "Due Date") {
      filtered.sort((a, b) {
        if (a.expectedReturnDate == null && b.expectedReturnDate == null)
          return 0;
        if (a.expectedReturnDate == null) return 1;
        if (b.expectedReturnDate == null) return -1;
        return a.expectedReturnDate!.compareTo(b.expectedReturnDate!);
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed(RoutesName.homeView);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Lent / Borrowed",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Track what you lent or borrowed",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => controller.fetchLoans(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.black87, size: 20),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: PressableScale(
                onTap: () => Get.to(() => AddLoanScreen(
                      myUser: widget.myUser,
                      controller: controller,
                    )),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F33E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSummaryHeader(),
            const SizedBox(height: 12),
            _buildTabSelector(),
            const SizedBox(height: 12),
            _buildSearchAndSortBar(),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTab(),
                  _buildIndividualTab(isLent: true),
                  _buildIndividualTab(isLent: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Unique people counts
        final lentPeople = controller.lent
            .map((e) => e.personName.trim().toLowerCase())
            .toSet()
            .length;
        final borrowedPeople = controller.borrowed
            .map((e) => e.personName.trim().toLowerCase())
            .toSet()
            .length;

        // Lent Overdue / Due Today
        final lentOverdue = controller.lent
            .where((loan) =>
                loan.status.value != 'paid' &&
                loan.expectedReturnDate != null &&
                loan.expectedReturnDate!.isBefore(today))
            .fold(0.0,
                (sum, loan) => sum + (loan.amount - loan.paidAmount.value));
        final lentDueToday = controller.lent
            .where((loan) =>
                loan.status.value != 'paid' &&
                loan.expectedReturnDate != null &&
                DateTime(
                        loan.expectedReturnDate!.year,
                        loan.expectedReturnDate!.month,
                        loan.expectedReturnDate!.day)
                    .isAtSameMomentAs(today))
            .fold(0.0,
                (sum, loan) => sum + (loan.amount - loan.paidAmount.value));

        // Borrowed Overdue / Due Today
        final borrowedOverdue = controller.borrowed
            .where((loan) =>
                loan.status.value != 'paid' &&
                loan.expectedReturnDate != null &&
                loan.expectedReturnDate!.isBefore(today))
            .fold(0.0,
                (sum, loan) => sum + (loan.amount - loan.paidAmount.value));
        final borrowedDueToday = controller.borrowed
            .where((loan) =>
                loan.status.value != 'paid' &&
                loan.expectedReturnDate != null &&
                DateTime(
                        loan.expectedReturnDate!.year,
                        loan.expectedReturnDate!.month,
                        loan.expectedReturnDate!.day)
                    .isAtSameMomentAs(today))
            .fold(0.0,
                (sum, loan) => sum + (loan.amount - loan.paidAmount.value));

        return Row(
          children: [
            // Left card: You Lent (Receivable)
            Expanded(
              child: _buildSummaryCard(
                title: "You Lent (Receivable)",
                amount: controller.totalLent,
                peopleCount: lentPeople,
                overdueAmount: lentOverdue,
                dueTodayAmount: lentDueToday,
                themeColor: const Color(0xFF2E7D32),
                iconData: Icons.arrow_outward_rounded,
                isLent: true,
              ),
            ),
            const SizedBox(width: 12),
            // Right card: You Borrowed (Payable)
            Expanded(
              child: _buildSummaryCard(
                title: "You Borrowed (Payable)",
                amount: controller.totalBorrowed,
                peopleCount: borrowedPeople,
                overdueAmount: borrowedOverdue,
                dueTodayAmount: borrowedDueToday,
                themeColor: const Color(0xFF5F33E1),
                iconData: Icons.arrow_downward_rounded,
                isLent: false,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required int peopleCount,
    required double overdueAmount,
    required double dueTodayAmount,
    required Color themeColor,
    required IconData iconData,
    required bool isLent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 14,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "₹${NumberFormat('#,##,###').format(amount)}",
            style: TextStyle(
              color: themeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "$peopleCount ${peopleCount == 1 ? 'Person' : 'People'}",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Overdue",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹${NumberFormat('#,###').format(overdueAmount)}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Due Today",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹${NumberFormat('#,###').format(dueTodayAmount)}",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final Color primaryColor = const Color(0xFF5F33E1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "You Lent"),
            Tab(text: "You Borrowed"),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) => searchQuery.value = value,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search by name or phone",
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.grey.shade400, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            return Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy.value,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.indigo.shade400, size: 18),
                  alignment: Alignment.centerRight,
                  style: TextStyle(
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      sortBy.value = newValue;
                    }
                  },
                  items: <String>[
                    'Recent',
                    'Oldest',
                    'Amount: High to Low',
                    'Amount: Low to High',
                    'Due Date'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text("Sort by: $value"),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    return Obx(() {
      final lentList = _getFilteredAndSortedLoans(isLent: true);
      final borrowedList = _getFilteredAndSortedLoans(isLent: false);

      if (lentList.isEmpty && borrowedList.isEmpty) {
        return _buildEmptyState();
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lentList.isNotEmpty) ...[
              _buildSectionHeader(
                title: "You Lent (Receivable)",
                onViewAll: () => _tabController.animateTo(1),
              ),
              const SizedBox(height: 8),
              ...lentList.take(4).map((loan) => _buildLoanCard(loan)),
              _buildSeeAllBanner(isLent: true, count: lentList.length),
              const SizedBox(height: 20),
            ],
            if (borrowedList.isNotEmpty) ...[
              _buildSectionHeader(
                title: "You Borrowed (Payable)",
                onViewAll: () => _tabController.animateTo(2),
              ),
              const SizedBox(height: 8),
              ...borrowedList.take(4).map((loan) => _buildLoanCard(loan)),
              _buildSeeAllBanner(isLent: false, count: borrowedList.length),
              const SizedBox(height: 20),
            ],
            _buildWhatsAppReminderBanner(),
          ],
        ),
      );
    });
  }

  Widget _buildIndividualTab({required bool isLent}) {
    return Obx(() {
      final list = _getFilteredAndSortedLoans(isLent: isLent);

      if (list.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: [
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final loan = list[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 30.0,
                      child: FadeInAnimation(
                        child: _buildLoanCard(loan),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (isLent) _buildWhatsAppReminderBanner(),
        ],
      );
    });
  }

  Widget _buildSectionHeader(
      {required String title, required VoidCallback onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            children: [
              Text(
                "View All",
                style: TextStyle(
                  color: Colors.indigo.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.indigo.shade600,
                size: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeeAllBanner({required bool isLent, required int count}) {
    final Color themeColor =
        isLent ? const Color(0xFF2E7D32) : const Color(0xFF5F33E1);
    return PressableScale(
      onTap: () {
        _tabController.animateTo(isLent ? 1 : 2);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isLent
                      ? Icons.savings_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: themeColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isLent
                      ? "See all lent ($count)"
                      : "See all borrowed ($count)",
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: themeColor,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan) {
    final themeColor =
        loan.type == 'lent' ? const Color(0xFF2E7D32) : const Color(0xFF5F33E1);

    return Obx(() {
      final name = loan.personName;

      return PressableScale(
        onTap: () =>
            Get.to(() => LoanDetailScreen(loan: loan, controller: controller)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: themeColor,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _buildCardSubtitle(loan),
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
                      fontSize: 14,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd MMM yyyy').format(loan.date),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade300,
                size: 12,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCardSubtitle(Loan loan) {
    final isPaid = loan.status.value == 'paid';
    final remaining = loan.amount - loan.paidAmount.value;
    final themeColor =
        loan.type == 'lent' ? const Color(0xFF2E7D32) : const Color(0xFF5F33E1);

    String dueText = "";
    Color dueColor = Colors.grey.shade500;

    if (isPaid) {
      dueText = "Paid";
      dueColor = const Color(0xFF2E7D32);
    } else if (loan.expectedReturnDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final returnDate = DateTime(loan.expectedReturnDate!.year,
          loan.expectedReturnDate!.month, loan.expectedReturnDate!.day);
      final difference = returnDate.difference(today).inDays;

      if (difference < 0) {
        dueText =
            "Overdue by ${difference.abs()} ${difference.abs() == 1 ? 'day' : 'days'}";
        dueColor = Colors.red;
      } else if (difference == 0) {
        dueText = "Due today";
        dueColor = Colors.orange;
      } else {
        dueText = "Due in $difference ${difference == 1 ? 'day' : 'days'}";
        dueColor = Colors.orange;
      }
    }

    return Row(
      children: [
        Text(
          "₹${NumberFormat('#,##,###').format(remaining)}",
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        if (dueText.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "•",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ),
          Text(
            dueText,
            style: TextStyle(
              color: dueColor,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWhatsAppReminderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6D1FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF5F33E1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Send Reminders",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Send payment reminders to multiple contacts on WhatsApp",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showWhatsAppRemindersBottomSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F33E1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.send_rounded, size: 12),
            label: const Text(
              "Send Now",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppRemindersBottomSheet() {
    final Map<String, Loan> receivableContacts = {};
    for (var loan in controller.lent) {
      if (loan.status.value != 'paid' &&
          loan.personPhone != null &&
          loan.personPhone!.isNotEmpty) {
        final key = loan.personName.trim().toLowerCase();
        if (!receivableContacts.containsKey(key)) {
          receivableContacts[key] = loan;
        }
      }
    }

    final contactsList = receivableContacts.values.toList();
    final selectedLoans = <Loan>[].obs;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Send WhatsApp Reminders",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Select contacts you want to send payment reminders to:",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (contactsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        "No contacts with pending lent loans and phone numbers found.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: Obx(() {
                  // Access selectedLoans.length to register the RxList dependency with Obx
                  final _ = selectedLoans.length;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: contactsList.length,
                    itemBuilder: (context, index) {
                      final loan = contactsList[index];
                      final isSelected = selectedLoans.contains(loan);
                      final remaining = loan.amount - loan.paidAmount.value;

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          if (val == true) {
                            selectedLoans.add(loan);
                          } else {
                            selectedLoans.remove(loan);
                          }
                        },
                        title: Text(
                          loan.personName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          "Pending: ₹${NumberFormat('#,##,###').format(remaining)} • ${loan.personPhone}",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                        activeColor: const Color(0xFF5F33E1),
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
            const SizedBox(height: 16),
            Obx(() {
              final isEnabled = selectedLoans.isNotEmpty;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isEnabled
                      ? () async {
                          Get.back(); // Close bottom sheet

                          // Show a loading dialog
                          Get.dialog(
                            const Center(
                                child: CupertinoActivityIndicator(radius: 16)),
                            barrierDismissible: false,
                          );

                          int successCount = 0;
                          for (var target in selectedLoans) {
                            final remaining =
                                target.amount - target.paidAmount.value;
                            final dueDateStr = target.expectedReturnDate != null
                                ? DateFormat('dd-MM-yyyy')
                                    .format(target.expectedReturnDate!)
                                : 'N/A';

                            try {
                              await WhatsAppService.sendLoanNotification(
                                phone: target.personPhone!,
                                lenderName: widget.myUser.name.isNotEmpty
                                    ? widget.myUser.name
                                    : 'Spendly User',
                                borrowerName: target.personName,
                                amount: remaining,
                                dueDate: dueDateStr,
                                type: 'lent',
                              );
                              successCount++;
                            } catch (_) {}
                          }

                          Get.back(); // Close loading dialog

                          Get.snackbar(
                            "Reminders Sent",
                            "Successfully sent reminders to $successCount contact(s) via WhatsApp.",
                            backgroundColor: Colors.green.shade50,
                            colorText: Colors.green.shade800,
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                color: Colors.green),
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1),
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    selectedLoans.isEmpty
                        ? "Select Contacts to Send"
                        : "Send Reminder to ${selectedLoans.length} ${selectedLoans.length == 1 ? 'Contact' : 'Contacts'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
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
                size: 60, color: const Color(0xFF5F33E1).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            searchQuery.value.isEmpty
                ? "No entries found"
                : "No matching records",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.value.isEmpty
                ? "Start by adding a lent or borrowed bill!"
                : "Try searching with a different name or phone.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
