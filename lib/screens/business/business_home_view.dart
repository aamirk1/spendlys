import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/services/business_service.dart';
import 'package:spendly/widgets/business_dialogs.dart';
import 'package:spendly/utils/utils.dart';

class BusinessHomeController extends GetxController {
  final isLoading = false.obs;

  // Raw data lists
  final invoices = [].obs;
  final quotations = [].obs;
  final customers = [].obs;
  final products = [].obs;

  // Selected tab & sub-filters
  final selectedSectionTab =
      'Invoices'.obs; // Invoices, Quotations, Customers, Products, Payments
  final activeInvoiceFilter = 'All'.obs; // All, Paid, Pending
  final activeQuotationFilter = 'All'.obs; // All, Accepted, Pending, Rejected
  final selectedFilter = 'This Month'.obs;

  // Search
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  // Focus node for appbar search action
  final searchFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text.trim();
    });
    refreshData();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchInvoices(),
        fetchQuotations(),
        fetchCustomers(),
        fetchProducts(),
      ]);
    } catch (e) {
      debugPrint("Error refreshing business dashboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSummary() => refreshData();

  // individual fetches
  Future<void> fetchInvoices() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/invoices',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        invoices.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching invoices: $e");
    }
  }

  Future<void> fetchQuotations() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/quotations',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        quotations.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching quotations: $e");
    }
  }

  Future<void> fetchCustomers() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/customers',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        customers.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching customers: $e");
    }
  }

  Future<void> fetchProducts() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/inventory/',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        products.value = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  bool _isWithinFilter(dynamic dateValue, String filter) {
    if (dateValue == null) return false;
    try {
      final DateTime date = dateValue is DateTime
          ? dateValue
          : DateTime.parse(dateValue.toString());
      final now = DateTime.now();
      switch (filter) {
        case 'This Week':
          final daysToSubtract = now.weekday == 7 ? 0 : now.weekday;
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysToSubtract));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          return date
                  .isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              date.isBefore(endOfWeek);
        case 'This Month':
          return date.year == now.year && date.month == now.month;
        case 'This Year':
          return date.year == now.year;
        default:
          return true;
      }
    } catch (_) {
      return false;
    }
  }

  // Dashboard calculations
  double get totalSales => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .fold(
          0.0,
          (sum, inv) =>
              sum + (double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0));
  int get totalInvoicesCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .length;
  int get paidInvoicesCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status']?.toString().toLowerCase() ?? '') == 'paid')
      .length;
  int get pendingInvoicesCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status']?.toString().toLowerCase() ?? '') != 'paid')
      .length;

  double get pendingAmount => invoices
          .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
          .fold(0.0, (sum, inv) {
        final double total =
            double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final double paid =
            double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return sum + (total - paid);
      });

  double get receivedAmount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .fold(
          0.0,
          (sum, inv) =>
              sum +
              (double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0));

  // Filtered lists for display
  List get filteredInvoices {
    List list = invoices;

    // Sub-filter tabs (All, Paid, Pending)
    if (activeInvoiceFilter.value == 'Paid') {
      list = list
          .where((inv) =>
              (inv['status']?.toString().toLowerCase() ?? '') == 'paid')
          .toList();
    } else if (activeInvoiceFilter.value == 'Pending') {
      list = list
          .where((inv) =>
              (inv['status']?.toString().toLowerCase() ?? '') != 'paid')
          .toList();
    }

    // Search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((inv) =>
              (inv['invoice_number']?.toString().toLowerCase() ?? '')
                  .contains(query) ||
              (inv['customer_name']?.toString().toLowerCase() ?? '')
                  .contains(query))
          .toList();
    }
    return list;
  }

  List get filteredQuotations {
    List list = quotations;

    // Sub-filter tabs (All, Accepted, Pending, Rejected)
    if (activeQuotationFilter.value == 'Accepted') {
      list = list
          .where((q) =>
              (q['status']?.toString().toLowerCase() ?? '') == 'accepted' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'converted')
          .toList();
    } else if (activeQuotationFilter.value == 'Pending') {
      list = list
          .where((q) =>
              (q['status']?.toString().toLowerCase() ?? '') == 'pending' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'sent' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'draft')
          .toList();
    } else if (activeQuotationFilter.value == 'Rejected') {
      list = list
          .where((q) =>
              (q['status']?.toString().toLowerCase() ?? '') == 'rejected' ||
              (q['status']?.toString().toLowerCase() ?? '') == 'expired')
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((q) =>
              (q['quotation_number']?.toString().toLowerCase() ?? '')
                  .contains(query) ||
              (q['customer_name']?.toString().toLowerCase() ?? '')
                  .contains(query))
          .toList();
    }
    return list;
  }

  List get filteredCustomers {
    List list = customers;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((c) =>
              (c['name']?.toString().toLowerCase() ?? '').contains(query) ||
              (c['phone']?.toString().toLowerCase() ?? '').contains(query))
          .toList();
    }
    return list;
  }

  List get filteredProducts {
    List list = products;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((p) =>
              (p['name']?.toString().toLowerCase() ?? '').contains(query))
          .toList();
    }
    return list;
  }

  // Quick Customer add callback
  Future<void> quickAddCustomer(String name, String phone) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.post('/business/customers',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: {"name": name, "phone": phone});
      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Customer $name added successfully!",
            isError: false);
        fetchCustomers();
      }
    } catch (e) {
      debugPrint("Failed to quick add customer: $e");
    }
  }

  // Record Payment dialogue invoice selection
  List get unpaidInvoices => invoices.where((inv) {
        final double total =
            double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final double paid =
            double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return (total - paid) > 0.01;
      }).toList();

  Future<void> recordInvoicePayment(
      String invoiceId, double amount, String method, String reference) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    try {
      final payload = {
        "amount": amount,
        "method": method,
        "reference_id": reference
      };
      final response = await ApiService.post(
          '/business/invoices/$invoiceId/payments',
          headers: {'Content-Type': 'application/json', 'x-user-id': userId},
          body: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar(
            "Success", "Payment of ₹${amount.toStringAsFixed(0)} recorded!",
            isError: false);
        refreshData();
      } else {
        Utils.showSnackbar(
            "Error", "Failed to record payment: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Exception recording payment: $e");
    }
  }
}

class BusinessHomeView extends StatelessWidget {
  const BusinessHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessHomeController());
    const Color primaryColor = Color(0xFF5F33E1); // Deep Purple
    const Color accentColor = Color(0xFFF3EFFF); // Lavender tint

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "business_center_title".tr,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage your business operations",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Colors.black87, size: 22),
            onPressed: () {
              controller.searchFocusNode.requestFocus();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded,
                color: Colors.black87, size: 22),
            onPressed: () => _showFilterSheet(context, controller),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateQuickSheet(context),
              icon:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              label: const Text("Create",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title Row & Overview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Business Overview",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      PopupMenuButton<String>(
                        initialValue: controller.selectedFilter.value,
                        onSelected: (String value) {
                          controller.selectedFilter.value = value;
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        child: Obx(() => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    controller.selectedFilter.value,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded,
                                      size: 14, color: Colors.grey),
                                ],
                              ),
                            )),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Horizontally scrollable summary cards
                _buildOverviewCards(controller, primaryColor),
                const SizedBox(height: 24),

                // 3. Module Tabs Selector
                _buildModuleSelector(controller, primaryColor),
                const SizedBox(height: 16),

                // 4. Search and dynamic segment lists
                Obx(() => _buildDynamicSection(
                    context, controller, primaryColor, accentColor)),
                const SizedBox(height: 24),

                // 5. Quick Actions Section
                // const Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 16.0),
                //   child: Text(
                //     "Quick Actions",
                //     style: TextStyle(
                //         fontSize: 15,
                //         fontWeight: FontWeight.bold,
                //         color: Colors.black87),
                //   ),
                // ),
                // const SizedBox(height: 12),
                // _buildQuickActions(context, controller, primaryColor),
                // const SizedBox(height: 24),

                // 6. Recent Activity log
                _buildRecentActivity(controller, primaryColor),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildOverviewCards(
      BusinessHomeController controller, Color primaryColor) {
    return Obx(() {
      final totalSalesStr =
          "₹${NumberFormat('#,##,###').format(controller.totalSales)}";
      final pendingAmtStr =
          "₹${NumberFormat('#,##,###').format(controller.pendingAmount)}";
      final receivedAmtStr =
          "₹${NumberFormat('#,##,###').format(controller.receivedAmount)}";
      final totalInvoices = controller.totalInvoicesCount;
      final paid = controller.paidInvoicesCount;
      final pending = controller.pendingInvoicesCount;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        child: Row(
          children: [
            _summaryCard(
              title: "Total Sales",
              value: totalSalesStr,
              subtitle: "↑ 18.6% vs last month",
              subtitleColor: const Color(0xFF4CAF50),
              icon: Icons.savings_rounded,
              iconColor: const Color(0xFF4CAF50),
              iconBgColor: const Color(0xFFE8F5E9),
            ),
            const SizedBox(width: 12),
            _summaryCard(
              title: "Total Invoices",
              value: "$totalInvoices",
              subtitle: "$paid Paid  •  $pending Pending",
              subtitleColor: Colors.grey.shade600,
              icon: Icons.description_rounded,
              iconColor: const Color(0xFF2196F3),
              iconBgColor: const Color(0xFFE3F2FD),
              richSubtitle: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: "$paid Paid ",
                        style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                    const TextSpan(
                        text: " •  ",
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                    TextSpan(
                        text: "$pending Pending",
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _summaryCard(
              title: "Pending Amount",
              value: pendingAmtStr,
              subtitle: "$pending Invoices",
              subtitleColor: Colors.orange,
              icon: Icons.access_time_filled_rounded,
              iconColor: Colors.orange,
              iconBgColor: const Color(0xFFFFF3E0),
            ),
            const SizedBox(width: 12),
            _summaryCard(
              title: "Received",
              value: receivedAmtStr,
              subtitle: controller.selectedFilter.value,
              subtitleColor: Colors.grey.shade600,
              icon: Icons.currency_rupee_rounded,
              iconColor: primaryColor,
              iconBgColor: const Color(0xFFF3EFFF),
            ),
          ],
        ),
      );
    });
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Widget? richSubtitle,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration:
                BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          richSubtitle ??
              Text(
                subtitle,
                style: TextStyle(
                    color: subtitleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
        ],
      ),
    );
  }

  Widget _buildModuleSelector(
      BusinessHomeController controller, Color primaryColor) {
    final modules = [
      'Invoices',
      'Quotations',
      'Customers',
      'Products',
      'Payments'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final active = controller.selectedSectionTab.value;
        return Row(
          children: modules.map((mod) {
            final isSel = active == mod;
            IconData mIcon = Icons.receipt_long_rounded;
            if (mod == 'Quotations') mIcon = Icons.request_quote_rounded;
            if (mod == 'Customers') mIcon = Icons.people_alt_rounded;
            if (mod == 'Products') mIcon = Icons.inventory_2_rounded;
            if (mod == 'Payments') mIcon = Icons.payment_rounded;

            return GestureDetector(
              onTap: () {
                controller.selectedSectionTab.value = mod;
                controller.searchController.clear();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFF3EFFF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSel
                          ? primaryColor.withOpacity(0.3)
                          : Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Icon(mIcon,
                        color: isSel ? primaryColor : Colors.grey.shade500,
                        size: 16),
                    const SizedBox(width: 8),
                    Text(
                      mod.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? primaryColor : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildDynamicSection(
      BuildContext context,
      BusinessHomeController controller,
      Color primaryColor,
      Color accentColor) {
    final active = controller.selectedSectionTab.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub bar title and filter pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                active.tr,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              if (active == 'Invoices')
                _buildInvoiceFilterPills(controller, primaryColor, accentColor)
              else if (active == 'Quotations')
                _buildQuotationFilterPills(
                    controller, primaryColor, accentColor)
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Count: ${_getModuleCount(controller, active)}",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextFormField(
            controller: controller.searchController,
            focusNode: controller.searchFocusNode,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            decoration: InputDecoration(
              hintText: active == 'Invoices'
                  ? "Search invoice number or customer..."
                  : active == 'Quotations'
                      ? "Search quote number or customer..."
                      : active == 'Customers'
                          ? "Search customers by name or phone..."
                          : "Search items...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.grey.shade400, size: 20),
              suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => controller.searchController.clear(),
                    )
                  : const SizedBox.shrink()),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor)),
            ),
          ),
          const SizedBox(height: 12),

          // Core dynamic list
          _buildActiveList(context, controller, active, primaryColor),
        ],
      ),
    );
  }

  int _getModuleCount(BusinessHomeController controller, String type) {
    if (type == 'Customers') return controller.customers.length;
    if (type == 'Products') return controller.products.length;
    return 0;
  }

  Widget _buildInvoiceFilterPills(BusinessHomeController controller,
      Color primaryColor, Color accentColor) {
    return Obx(() {
      final cur = controller.activeInvoiceFilter.value;
      final total = controller.invoices.length;
      final paid = controller.paidInvoicesCount;
      final pending = controller.pendingInvoicesCount;

      return Row(
        children: [
          _filterPill(
              ".All ($total)",
              cur == 'All',
              () => controller.activeInvoiceFilter.value = 'All',
              primaryColor,
              accentColor),
          const SizedBox(width: 6),
          _filterPill(
              "Paid ($paid)",
              cur == 'Paid',
              () => controller.activeInvoiceFilter.value = 'Paid',
              const Color(0xFF4CAF50),
              const Color(0xFFE8F5E9)),
          const SizedBox(width: 6),
          _filterPill(
              "Pending ($pending)",
              cur == 'Pending',
              () => controller.activeInvoiceFilter.value = 'Pending',
              Colors.orange,
              const Color(0xFFFFF3E0)),
        ],
      );
    });
  }

  Widget _buildQuotationFilterPills(BusinessHomeController controller,
      Color primaryColor, Color accentColor) {
    return Obx(() {
      final cur = controller.activeQuotationFilter.value;
      final total = controller.quotations.length;
      final accepted = controller.quotations
          .where((q) => q['status'] == 'accepted' || q['status'] == 'converted')
          .length;
      final pending = controller.quotations
          .where((q) =>
              q['status'] == 'pending' ||
              q['status'] == 'sent' ||
              q['status'] == 'draft')
          .length;

      return Row(
        children: [
          _filterPill(
              ".All ($total)",
              cur == 'All',
              () => controller.activeQuotationFilter.value = 'All',
              primaryColor,
              accentColor),
          const SizedBox(width: 6),
          _filterPill(
              "Accepted ($accepted)",
              cur == 'Accepted',
              () => controller.activeQuotationFilter.value = 'Accepted',
              const Color(0xFF4CAF50),
              const Color(0xFFE8F5E9)),
          const SizedBox(width: 6),
          _filterPill(
              "Pending ($pending)",
              cur == 'Pending',
              () => controller.activeQuotationFilter.value = 'Pending',
              Colors.orange,
              const Color(0xFFFFF3E0)),
        ],
      );
    });
  }

  Widget _filterPill(String label, bool isSel, VoidCallback onTap,
      Color primary, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? accent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSel ? primary.withOpacity(0.3) : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSel ? primary : Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildActiveList(BuildContext context,
      BusinessHomeController controller, String type, Color primaryColor) {
    List items = [];
    if (type == 'Invoices') items = controller.filteredInvoices;
    if (type == 'Quotations') items = controller.filteredQuotations;
    if (type == 'Customers') items = controller.filteredCustomers;
    if (type == 'Products') items = controller.filteredProducts;
    if (type == 'Payments') return _buildPaymentsView(controller, primaryColor);

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text("No records found",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      );
    }

    final displayItems = items.take(5).toList();

    return Column(
      children: [
        ...displayItems.map((item) {
          if (type == 'Invoices') return _invoiceRow(item, primaryColor);
          if (type == 'Quotations') return _quotationRow(item, primaryColor);
          if (type == 'Customers') return _customerRow(item, primaryColor);
          return _productRow(item, primaryColor);
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (type == 'Invoices') _safeNavigate(RoutesName.invoiceList);
            if (type == 'Quotations') _safeNavigate(RoutesName.quotationList);
            if (type == 'Customers') _safeNavigate(RoutesName.customersList);
            if (type == 'Products') _safeNavigate(RoutesName.inventoryList);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "View All ${type.tr}",
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: primaryColor),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _invoiceRow(Map<String, dynamic> inv, Color primaryColor) {
    final status = (inv['status'] ?? 'pending').toString().toLowerCase();
    Color statusColor = Colors.orange;
    Color statusBg = const Color(0xFFFFF3E0);

    if (status == 'paid') {
      statusColor = const Color(0xFF4CAF50);
      statusBg = const Color(0xFFE8F5E9);
    } else if (status == 'partial') {
      statusColor = const Color(0xFF2196F3);
      statusBg = const Color(0xFFE3F2FD);
    }

    final double total =
        double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
    final double paid =
        double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;

    String dateStr = 'N/A';
    if (inv['date'] != null) {
      try {
        dateStr = DateFormat('dd MMM yyyy')
            .format(DateTime.parse(inv['date'].toString()));
      } catch (_) {}
    }

    String dueSubtext = '';
    if (status == 'paid') {
      dueSubtext = "Paid on $dateStr";
    } else if (status == 'partial') {
      dueSubtext =
          "Paid ₹${paid.toStringAsFixed(0)} / ₹${total.toStringAsFixed(0)}";
    } else {
      if (inv['due_date'] != null) {
        try {
          final diff = DateTime.parse(inv['due_date'].toString())
              .difference(DateTime.now())
              .inDays;
          dueSubtext =
              diff >= 0 ? "Due in $diff days" : "Overdue by ${diff.abs()} days";
        } catch (_) {
          dueSubtext = "Due";
        }
      } else {
        dueSubtext = "Due in few days";
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: statusBg,
          child: Icon(Icons.description_rounded, color: statusColor, size: 20),
        ),
        title: Row(
          children: [
            Text(inv['invoice_number'] ?? '#INV-???',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: statusBg, borderRadius: BorderRadius.circular(6)),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(inv['customer_name'] ?? 'Unknown Customer',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 1),
            Text(dateStr,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₹${total.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(dueSubtext,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'paid'
                            ? const Color(0xFF4CAF50)
                            : Colors.orange)),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
        onTap: () => Get.toNamed(RoutesName.viewInvoice, arguments: inv),
      ),
    );
  }

  Widget _quotationRow(Map<String, dynamic> q, Color primaryColor) {
    final status = (q['status'] ?? 'pending').toString().toLowerCase();
    Color statusColor = Colors.orange;
    Color statusBg = const Color(0xFFFFF3E0);

    if (status == 'accepted' || status == 'converted') {
      statusColor = const Color(0xFF4CAF50);
      statusBg = const Color(0xFFE8F5E9);
    } else if (status == 'rejected' || status == 'expired') {
      statusColor = const Color(0xFFF44336);
      statusBg = const Color(0xFFFFEBEE);
    }

    final double total = double.tryParse(q['total']?.toString() ?? '0') ?? 0.0;
    String dateStr = 'N/A';
    if (q['date'] != null) {
      try {
        dateStr = DateFormat('dd MMM yyyy')
            .format(DateTime.parse(q['date'].toString()));
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF3EFFF),
          child:
              Icon(Icons.request_quote_rounded, color: primaryColor, size: 20),
        ),
        title: Row(
          children: [
            Text(q['quotation_number'] ?? '#QTN-???',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: statusBg, borderRadius: BorderRadius.circular(6)),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(q['customer_name'] ?? 'Unknown Customer',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 1),
            Text(dateStr,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₹${total.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text("Estimated",
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
        onTap: () => Get.toNamed(RoutesName.viewQuotation, arguments: q),
      ),
    );
  }

  Widget _customerRow(Map<String, dynamic> c, Color primaryColor) {
    final initials =
        (c['name'] ?? 'U').toString().substring(0, 1).toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF3EFFF),
          child: Text(initials,
              style:
                  TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(c['name'] ?? 'Unknown',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87)),
        subtitle: Text(c['phone'] ?? 'No phone number',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.shade400, size: 20),
        onTap: () {
          _safeNavigate(RoutesName.customersList);
        },
      ),
    );
  }

  Widget _productRow(Map<String, dynamic> p, Color primaryColor) {
    final double price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF3E0),
          child:
              Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 20),
        ),
        title: Text(p['name'] ?? 'Product',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87)),
        subtitle: Text("Price: ₹${price.toStringAsFixed(0)}",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.shade400, size: 20),
        onTap: () => Get.toNamed(RoutesName.editProduct, arguments: p),
      ),
    );
  }

  Widget _buildPaymentsView(
      BusinessHomeController controller, Color primaryColor) {
    final paidInvoices = controller.invoices
        .where((inv) =>
            (double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0) > 0)
        .toList();
    if (paidInvoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          children: [
            const Icon(Icons.payment_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text("No payments recorded yet",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: paidInvoices.take(5).map((inv) {
        final double paid =
            double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade100)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child:
                  Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 20),
            ),
            title: Text("Received from ${inv['customer_name']}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
            subtitle: Text("Invoice #${inv['invoice_number']}",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            trailing: Text("+₹${paid.toStringAsFixed(0)}",
                style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context,
      BusinessHomeController controller, Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Row(
        children: [
          _quickActionCard(
            label: "Create Invoice",
            icon: Icons.receipt_long_outlined,
            iconColor: primaryColor,
            bgColor: const Color(0xFFF3EFFF),
            onTap: () => _safeNavigate(RoutesName.createInvoice),
          ),
          const SizedBox(width: 12),
          _quickActionCard(
            label: "Create Quotation",
            icon: Icons.request_quote_outlined,
            iconColor: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
            onTap: () => _safeNavigate(RoutesName.createQuotation),
          ),
          const SizedBox(width: 12),
          _quickActionCard(
            label: "Add Customer",
            icon: Icons.person_add_alt_1_outlined,
            iconColor: const Color(0xFF4CAF50),
            bgColor: const Color(0xFFE8F5E9),
            onTap: () => _showAddCustomerForm(context, controller),
          ),
          const SizedBox(width: 12),
          _quickActionCard(
            label: "Add Product",
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.orange,
            bgColor: const Color(0xFFFFF3E0),
            onTap: () => _safeNavigate(RoutesName.addProduct),
          ),
          const SizedBox(width: 12),
          _quickActionCard(
            label: "Record Payment",
            icon: Icons.credit_card_outlined,
            iconColor: Colors.purple,
            bgColor: const Color(0xFFFCE4EC),
            onTap: () => _showRecordPaymentPicker(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              radius: 20,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
      BusinessHomeController controller, Color primaryColor) {
    return Obx(() {
      final list = controller.invoices;
      if (list.isEmpty) return const SizedBox.shrink();

      final activities = list.take(2).toList();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Activity",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                TextButton(
                  onPressed: () => _safeNavigate(RoutesName.invoiceList),
                  child: Text("View All",
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
            ...activities.map((inv) {
              final double paid =
                  double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
              final double total =
                  double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
              final isPaid =
                  (inv['status'] ?? '').toString().toLowerCase() == 'paid';

              String dateStr = 'N/A';
              if (inv['date'] != null) {
                try {
                  dateStr = DateFormat('dd MMM yyyy')
                      .format(DateTime.parse(inv['date'].toString()));
                } catch (_) {}
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isPaid
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      radius: 18,
                      child: Icon(
                        isPaid
                            ? Icons.check_circle_outline_rounded
                            : Icons.add_circle_outline_rounded,
                        color: isPaid ? const Color(0xFF4CAF50) : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPaid
                                ? "Payment received from ${inv['customer_name']}"
                                : "New invoice created for ${inv['customer_name']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text("Invoice #${inv['invoice_number']}",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPaid
                              ? "+₹${paid.toStringAsFixed(0)}"
                              : "₹${total.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isPaid
                                ? const Color(0xFF4CAF50)
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(dateStr,
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList()
          ],
        ),
      );
    });
  }

  // --- ACTIONS & SHEETS ---

  void _safeNavigate(String route) async {
    final businessService = Get.find<BusinessService>();

    if (businessService.isProfileCreated.value) {
      Get.toNamed(route);
    } else {
      await businessService.checkProfileStatus();
      if (businessService.isProfileCreated.value) {
        Get.toNamed(route);
      } else {
        BusinessDialogs.showProfileRequiredDialog();
      }
    }
  }

  void _showCreateQuickSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Create",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF5F33E1)),
              title: const Text("New Invoice",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Generate a digital invoice for a client"),
              onTap: () {
                Get.back();
                _safeNavigate(RoutesName.createInvoice);
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.request_quote_rounded, color: Colors.blue),
              title: const Text("New Quotation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Create a price quote/estimate for work"),
              onTap: () {
                Get.back();
                _safeNavigate(RoutesName.createQuotation);
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.inventory_2_rounded, color: Colors.orange),
              title: const Text("Add Product",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Add a new product or service to inventory"),
              onTap: () {
                Get.back();
                _safeNavigate(RoutesName.addProduct);
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.person_add_rounded, color: Colors.green),
              title: const Text("Add Customer",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("Add a new customer details"),
              onTap: () {
                Get.back();
                _safeNavigate(RoutesName.addCustomer);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, BusinessHomeController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filter Options",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("Sort By",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 10),
            Row(
              children: [
                _choiceChip("Latest Date", true, () {}),
                const SizedBox(width: 8),
                _choiceChip("Highest Amount", false, () {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("APPLY FILTERS",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool active, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.black87)),
      selected: active,
      onSelected: (v) => onTap(),
      selectedColor: const Color(0xFF5F33E1),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showAddCustomerForm(
      BuildContext context, BusinessHomeController controller) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final k = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Quick Add Customer",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Form(
          key: k,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                decoration: InputDecoration(
                  labelText: "Customer Name",
                  prefixIcon: const Icon(Icons.person_rounded,
                      color: Color(0xFF5F33E1)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon:
                      const Icon(Icons.phone_rounded, color: Color(0xFF5F33E1)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (k.currentState!.validate()) {
                controller.quickAddCustomer(
                    nameCtrl.text.trim(), phoneCtrl.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F33E1)),
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentPicker(
      BuildContext context, BusinessHomeController controller) {
    final list = controller.unpaidInvoices;
    if (list.isEmpty) {
      Utils.showSnackbar("Info", "No unpaid/pending invoices found.");
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Select Unpaid Invoice",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (c, i) {
                  final inv = list[i];
                  final double remaining = (double.tryParse(
                              inv['total']?.toString() ?? '0') ??
                          0.0) -
                      (double.tryParse(inv['paid_amount']?.toString() ?? '0') ??
                          0.0);
                  return ListTile(
                    title: Text(inv['invoice_number'] ?? '#INV-???',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "${inv['customer_name']} | Due: ₹${remaining.toStringAsFixed(0)}"),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF5F33E1)),
                    onTap: () {
                      Get.back(); // close list
                      _showRecordPaymentForm(
                          context, controller, inv, remaining);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentForm(
      BuildContext context,
      BusinessHomeController controller,
      Map<String, dynamic> inv,
      double remaining) {
    final tAmount = TextEditingController(text: remaining.toStringAsFixed(0));
    final tRef = TextEditingController();
    String selectedMethod = "Cash";
    final k = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Record Payment for ${inv['invoice_number']}",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Form(
          key: k,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Remaining Balance: ₹${remaining.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF5F33E1))),
              const SizedBox(height: 16),
              TextFormField(
                controller: tAmount,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  double? val = double.tryParse(v);
                  if (val == null || val <= 0) return "Invalid amount";
                  if (val > (remaining + 0.01)) return "Exceeds remaining";
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: const Icon(Icons.payments_rounded,
                      color: Color(0xFF5F33E1)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: InputDecoration(
                  labelText: "Payment Method",
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded,
                      color: Color(0xFF5F33E1)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: ["Cash", "UPI", "Bank Transfer"]
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => selectedMethod = v!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tRef,
                decoration: InputDecoration(
                  labelText: "Reference ID (Optional)",
                  prefixIcon:
                      const Icon(Icons.tag_rounded, color: Color(0xFF5F33E1)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (k.currentState!.validate()) {
                controller.recordInvoicePayment(
                    inv['id'].toString(),
                    double.parse(tAmount.text),
                    selectedMethod,
                    tRef.text.trim());
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F33E1)),
            child: const Text("Save",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
