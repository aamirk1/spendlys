import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/screens/home/widgets/pressable_scale.dart';
import 'package:spendly/res/routes/routes_name.dart';

class ViewAllExpense extends StatefulWidget {
  const ViewAllExpense({super.key});

  @override
  State<ViewAllExpense> createState() => _ViewAllExpenseState();
}

class _ViewAllExpenseState extends State<ViewAllExpense>
    with SingleTickerProviderStateMixin {
  final ExpenseController expenseController = Get.find<ExpenseController>();
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = "".obs;
  final RxString sortBy = "Recent".obs;
  final RxString selectedPeriod = "This Month".obs;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredAndSortedExpenses({required String mode}) {
    final list = expenseController.expensesList.toList();
    final query = searchQuery.value.toLowerCase().trim();

    // Filter by Tab (mode)
    final modeFiltered = list.where((expense) {
      final paymentMode = expense['payment_mode'] ?? 'Cash';
      if (mode == 'Cash') {
        return paymentMode == 'Cash';
      } else if (mode == 'Digital') {
        return paymentMode != 'Cash';
      }
      return true; // 'All'
    }).toList();

    // Filter by search query
    final filtered = modeFiltered.where((expense) {
      if (query.isEmpty) return true;
      final descMatch = (expense['description'] as String).toLowerCase().contains(query);
      final categoryMatch = (expense['category'] as String).toLowerCase().contains(query);
      return descMatch || categoryMatch;
    }).toList();

    // Sort
    if (sortBy.value == "Recent") {
      filtered.sort((a, b) => b['date'].compareTo(a['date']));
    } else if (sortBy.value == "Oldest") {
      filtered.sort((a, b) => a['date'].compareTo(b['date']));
    } else if (sortBy.value == "Amount: High to Low") {
      filtered.sort((a, b) => b['amount'].compareTo(a['amount']));
    } else if (sortBy.value == "Amount: Low to High") {
      filtered.sort((a, b) => a['amount'].compareTo(b['amount']));
    } else if (sortBy.value == "Category") {
      filtered.sort((a, b) => (a['category'] as String).compareTo(b['category'] as String));
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
            Get.back();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "All Expenses",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Track your spending & payments",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => expenseController.fetchExpenses(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.black87, size: 20),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: PressableScale(
                onTap: () => Get.toNamed(RoutesName.incomeExpenseHome, arguments: 1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
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
                  _buildIndividualTab(mode: "All"),
                  _buildIndividualTab(mode: "Cash"),
                  _buildIndividualTab(mode: "Digital"),
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
        final expenses = expenseController.expensesList;
        final now = DateTime.now();

        final cashExpenses = expenses.where((e) => (e['payment_mode'] ?? 'Cash') == 'Cash');
        final digitalExpenses = expenses.where((e) => (e['payment_mode'] ?? 'Cash') != 'Cash');

        final totalCash = cashExpenses.fold<double>(0, (sum, item) => sum + item['amount']);
        final totalDigital = digitalExpenses.fold<double>(0, (sum, item) => sum + item['amount']);

        final cashCount = cashExpenses.length;
        final digitalCount = digitalExpenses.length;

        bool _isWithinFilter(DateTime date, String filter) {
          switch (filter) {
            case 'This Week':
              final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
              final startOfWeek = DateTime(now.year, now.month, now.day)
                  .subtract(Duration(days: daysToSubtract));
              final endOfWeek = startOfWeek.add(const Duration(days: 7));
              return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
                  date.isBefore(endOfWeek);
            case 'This Month':
              return date.year == now.year && date.month == now.month;
            case 'This Year':
              return date.year == now.year;
            default:
              return true;
          }
        }

        // Current Month calculation
        final cashMonth = cashExpenses
            .where((e) => _isWithinFilter(e['date'] as DateTime, selectedPeriod.value))
            .fold<double>(0, (sum, item) => sum + item['amount']);
        final digitalMonth = digitalExpenses
            .where((e) => _isWithinFilter(e['date'] as DateTime, selectedPeriod.value))
            .fold<double>(0, (sum, item) => sum + item['amount']);

        // Today calculation
        final cashToday = cashExpenses
            .where((e) =>
                (e['date'] as DateTime).year == now.year &&
                (e['date'] as DateTime).month == now.month &&
                (e['date'] as DateTime).day == now.day)
            .fold<double>(0, (sum, item) => sum + item['amount']);
        final digitalToday = digitalExpenses
            .where((e) =>
                (e['date'] as DateTime).year == now.year &&
                (e['date'] as DateTime).month == now.month &&
                (e['date'] as DateTime).day == now.day)
            .fold<double>(0, (sum, item) => sum + item['amount']);

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: "Cash Expense",
                amount: totalCash,
                count: cashCount,
                monthAmount: cashMonth,
                todayAmount: cashToday,
                themeColor: const Color(0xFFF97316),
                iconData: Icons.money_off_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: "Digital Expense",
                amount: totalDigital,
                count: digitalCount,
                monthAmount: digitalMonth,
                todayAmount: digitalToday,
                themeColor: const Color(0xFF5F33E1),
                iconData: Icons.credit_card_rounded,
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
    required int count,
    required double monthAmount,
    required double todayAmount,
    required Color themeColor,
    required IconData iconData,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  color: themeColor.withOpacity(0.1),
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
            "$count ${count == 1 ? 'Transaction' : 'Transactions'}",
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
                    PopupMenuButton<String>(
                      initialValue: selectedPeriod.value,
                      onSelected: (String value) {
                        selectedPeriod.value = value;
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (BuildContext context) {
                        return ['This Week', 'This Month', 'This Year']
                            .map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(
                              choice,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedPeriod.value,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹${NumberFormat('#,###').format(monthAmount)}",
                      style: TextStyle(
                        color: themeColor,
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
                      "Today",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "₹${NumberFormat('#,###').format(todayAmount)}",
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
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Cash"),
            Tab(text: "Digital"),
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
                    color: Colors.black.withOpacity(0.02),
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
                  hintText: "Search by description or category",
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
                    color: Colors.black.withOpacity(0.02),
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
                    'Category'
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

  Widget _buildIndividualTab({required String mode}) {
    return Obx(() {
      final list = _getFilteredAndSortedExpenses(mode: mode);

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No transactions found",
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 16)),
            ],
          ),
        );
      }

      return AnimationLimiter(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: _buildTransactionCard(item),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final categoryName = item['category'] as String;
    final description = item['description'] as String;
    final date = item['date'] as DateTime;
    final amount = item['amount'] as double;
    final paymentMode = item['payment_mode'] ?? 'Cash';

    final categoryData = expenseController.expenseCategories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'icon': Icons.category, 'color': Colors.grey},
    );

    final categoryIcon = categoryData['icon'] as IconData;
    final categoryColor = categoryData['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${DateFormat('dd MMM yyyy, hh:mm a').format(date)} • $paymentMode",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount & Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "- ₹${NumberFormat('#,##,###.##').format(amount)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    Icons.edit_rounded,
                    Colors.blue,
                    () => _editExpense(context, item),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    Icons.delete_rounded,
                    Colors.redAccent,
                    () => _confirmDelete(context, item),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  void _editExpense(BuildContext context, Map<String, dynamic> expense) {
    TextEditingController amountController =
        TextEditingController(text: expense['amount'].toString());
    TextEditingController descriptionController =
        TextEditingController(text: expense['description']);
    String selectedCategory = expense['category'];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Edit Expense",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: expenseController.expenseCategories.map((category) {
                  return DropdownMenuItem(
                      value: category['name'] as String,
                      child: Text(category['name'] as String));
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    expenseController.updateExpense(expense['id'], {
                      'amount': double.parse(amountController.text.trim()),
                      'description': descriptionController.text.trim(),
                      'category': selectedCategory,
                      'date': (expense['date'] as DateTime).toIso8601String(),
                    });
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Save Changes",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> expense) {
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text("Delete Expense?"),
        content: const Text("This action cannot be undone."),
        actions: [
          CupertinoDialogAction(
              child: const Text("Cancel"), onPressed: () => Get.back()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              expenseController.deleteExpense(expense['id']);
              Get.back();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
