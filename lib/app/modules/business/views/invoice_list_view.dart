import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/modules/profile/controllers/user_info_controller.dart';
import 'package:spendly/app/modules/business/views/business_home_view.dart';

class InvoiceListController extends GetxController {
  final invoices = [].obs;
  final isLoading = true.obs;
  final isMoreLoading = false.obs;

  // Pagination
  int currentPage = 1;
  final int limit = 10;
  bool hasMoreData = true;
  final scrollController = ScrollController();

  // Search and Filter
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final selectedTab = 'All'.obs;
  final dateRange = Rxn<DateTimeRange>();

  final selectedFilter = 'This Month'.obs;

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
          return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
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

  int get totalCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .length;

  int get paidCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'paid')
      .length;

  double get paidAmount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .fold(0.0, (sum, inv) => sum + (double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0));

  int get pendingCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'pending' || (inv['status'] ?? '').toString().toLowerCase() == 'partially_paid')
      .length;

  double get pendingAmount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'pending' || (inv['status'] ?? '').toString().toLowerCase() == 'partially_paid')
      .fold(0.0, (sum, inv) {
        final total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final paid = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return sum + (total - paid);
      });

  int get overdueCount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'overdue')
      .length;

  double get overdueAmount => invoices
      .where((inv) => _isWithinFilter(inv['date'], selectedFilter.value))
      .where((inv) => (inv['status'] ?? '').toString().toLowerCase() == 'overdue')
      .fold(0.0, (sum, inv) {
        final total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final paid = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        return sum + (total - paid);
      });

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
    setupScrollListener();
  }

  void setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (hasMoreData && !isMoreLoading.value && !isLoading.value) {
          fetchInvoices(loadMore: true);
        }
      }
    });
  }

  Future<void> fetchInvoices({bool loadMore = false, bool refresh = false}) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    if (refresh) {
      currentPage = 1;
      hasMoreData = true;
    }

    final endpoint = '/business/invoices?page=$currentPage&limit=$limit';
    final cacheKey = 'GET_$endpoint';

    if (!loadMore && !refresh) {
      final cachedData = LocalCacheService.getCache(cacheKey);
      if (cachedData != null && cachedData is List) {
        invoices.assignAll(cachedData);
        return;
      }
    }

    if (!loadMore) {
      final cachedData = LocalCacheService.getCache(cacheKey);
      if (cachedData != null && cachedData is List) {
        invoices.assignAll(cachedData);
      } else {
        isLoading.value = true;
      }
    } else {
      isMoreLoading.value = true;
    }

    try {
      final response = await ApiService.get(endpoint, headers: {'x-user-id': userId});

      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          final List newData = jsonDecode(response.body);

          if (refresh || !loadMore) {
            invoices.assignAll(newData);
          } else {
            invoices.addAll(newData);
          }

          if (newData.length < limit) {
            hasMoreData = false;
          } else {
            currentPage++;
          }
        }
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load invoices: $e");
    } finally {
      isLoading.value = false;
      isMoreLoading.value = false;
    }
  }

  List get filteredInvoices {
    return invoices.where((inv) {
      final matchesSearch = (inv['invoice_number'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          (inv['customer']?['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());

      final rawStatus = (inv['status'] ?? '').toString().toLowerCase();
      bool matchesStatus = true;
      if (selectedTab.value == 'Paid') {
        matchesStatus = rawStatus == 'paid';
      } else if (selectedTab.value == 'Pending') {
        matchesStatus = rawStatus == 'pending' || rawStatus == 'partially_paid';
      } else if (selectedTab.value == 'Overdue') {
        matchesStatus = rawStatus == 'overdue';
      }

      bool matchesDate = true;
      if (dateRange.value != null && inv['date'] != null) {
        final d = DateTime.parse(inv['date']);
        matchesDate = d.isAfter(
                dateRange.value!.start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(dateRange.value!.end.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  Future<void> deleteInvoice(String invoiceId) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.delete('/business/invoices/$invoiceId',
          headers: {'x-user-id': userId});

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline ? "Invoice deletion scheduled offline. Will sync when online." : "Invoice deleted successfully",
            isError: false);
        invoices.removeWhere((inv) => inv['id'].toString() == invoiceId);
        fetchInvoices(refresh: true);
        if (Get.isRegistered<BusinessHomeController>()) {
          Get.find<BusinessHomeController>().fetchSummary();
        }
      } else {
        Utils.showSnackbar("Error", "Failed to delete invoice: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to delete invoice: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return {
          'label': 'Paid',
          'color': const Color(0xFF4CAF50),
          'bgColor': const Color(0xFFE8F5E9),
          'iconColor': const Color(0xFF4CAF50),
          'iconBgColor': const Color(0xFFE8F5E9),
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'overdue':
        return {
          'label': 'Overdue',
          'color': const Color(0xFFF44336),
          'bgColor': const Color(0xFFFFEBEE),
          'iconColor': const Color(0xFFF44336),
          'iconBgColor': const Color(0xFFFFCDD2).withValues(alpha: 0.5),
          'icon': Icons.warning_amber_rounded,
        };
      case 'partially_paid':
        return {
          'label': 'Partially Paid',
          'color': const Color(0xFF2196F3),
          'bgColor': const Color(0xFFE3F2FD),
          'iconColor': const Color(0xFF2196F3),
          'iconBgColor': const Color(0xFFE3F2FD),
          'icon': Icons.hourglass_bottom_rounded,
        };
      case 'pending':
      default:
        return {
          'label': 'Pending',
          'color': const Color(0xFFFF9800),
          'bgColor': const Color(0xFFFFF3E0),
          'iconColor': const Color(0xFF5F33E1),
          'iconBgColor': const Color(0xFFF3EFFF),
          'icon': Icons.description_rounded,
        };
    }
  }
}

class InvoiceListView extends StatelessWidget {
  const InvoiceListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvoiceListController());
    const Color primaryColor = Color(0xFF5F33E1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Invoices",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage all your invoices",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black87, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.black87, size: 22),
            onPressed: () => _showFilterSheet(context, controller),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(RoutesName.createInvoice),
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text("Create", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.fetchInvoices(refresh: true),
          color: primaryColor,
          child: SingleChildScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // 1. Stats dashboard
                Obx(() => _buildStatsSection(controller)),
                const SizedBox(height: 20),

                // 2. Custom Pill Tabs
                _buildTabsSection(controller),
                const SizedBox(height: 12),

                // 3. Search and Sort Row
                _buildSearchSortRow(controller),
                const SizedBox(height: 16),

                // 4. Invoice cards list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      );
                    }
                    final items = controller.filteredInvoices;
                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              "No invoices found",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }
                    return AnimationLimiter(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length + (controller.isMoreLoading.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(15.0),
                                child: CircularProgressIndicator(color: primaryColor),
                              ),
                            );
                          }
                          final inv = items[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: FadeInAnimation(
                                child: _buildInvoiceItemCard(context, inv, controller),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),
                // 5. Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // 6. Professional Invoice Promo Card
                _buildPromoCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(InvoiceListController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF5F33E1),
            iconBgColor: const Color(0xFFF3EFFF),
            title: "Total Invoices",
            value: "${controller.totalCount}",
            subtitle: PopupMenuButton<String>(
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
                    controller.selectedFilter.value,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 11,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFFE8F5E9),
            title: "Paid",
            value: "${controller.paidCount}",
            subtitle: "₹${_formatPrice(controller.paidAmount)}",
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.hourglass_bottom_rounded,
            iconColor: const Color(0xFFFF9800),
            iconBgColor: const Color(0xFFFFF3E0),
            title: "Pending",
            value: "${controller.pendingCount}",
            subtitle: "₹${_formatPrice(controller.pendingAmount)}",
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFF44336),
            iconBgColor: const Color(0xFFFFEBEE),
            title: "Overdue",
            value: "${controller.overdueCount}",
            subtitle: "₹${_formatPrice(controller.overdueAmount)}",
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required dynamic subtitle,
  }) {
    return Container(
      width: 125,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 2),
          subtitle is Widget
              ? subtitle
              : Text(subtitle.toString(), style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTabsSection(InvoiceListController controller) {
    final tabs = ['All', 'Paid', 'Pending', 'Overdue'];
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: tabs.map((tab) {
          return Obx(() {
            final isSelected = controller.selectedTab.value == tab;
            return GestureDetector(
              onTap: () {
                controller.selectedTab.value = tab;
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF5F33E1) : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    width: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF5F33E1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  Widget _buildSearchSortRow(InvoiceListController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                onChanged: (v) => controller.searchQuery.value = v,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Search by invoice no. or customer...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF5F33E1), width: 1.2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF5F33E1).withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Text(
                  "Sort: Recent",
                  style: TextStyle(
                    color: Color(0xFF5F33E1),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF5F33E1),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItemCard(BuildContext context, Map<String, dynamic> inv, InvoiceListController controller) {
    String dateFormatted = "Unknown";
    if (inv['date'] != null) {
      try {
        dateFormatted = DateFormat('dd Jul yyyy').format(DateTime.parse(inv['date']));
      } catch (_) {}
    }
    
    String dueFormatted = "";
    if (inv['due_date'] != null) {
      try {
        dueFormatted = DateFormat('dd Jul yyyy').format(DateTime.parse(inv['due_date']));
      } catch (_) {}
    }

    final statusDetails = controller.getStatusDetails(inv['status'] ?? 'pending');
    final totalAmount = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
    final paidAmount = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(RoutesName.viewInvoice, arguments: inv);
        },
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusDetails['iconBgColor'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusDetails['icon'],
                color: statusDetails['iconColor'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inv['invoice_number'] ?? '#INV-0000',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inv['customer']?['name'] ?? 'Unknown Customer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusDetails['bgColor'],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusDetails['label'],
                    style: TextStyle(
                      color: statusDetails['color'],
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
                if (dueFormatted.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Due till $dueFormatted",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${_formatPrice(totalAmount)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                if (paidAmount > 0 && inv['status'] != 'paid') ...[
                  const SizedBox(height: 2),
                  Text(
                    "Paid: ₹${_formatPrice(paidAmount)}",
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  "Sent on $dateFormatted",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade300,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildQuickActionCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF5F33E1),
                iconBgColor: const Color(0xFFF3EFFF),
                label: "Create Invoice",
                onTap: () => Get.toNamed(RoutesName.createInvoice),
              ),
              const SizedBox(width: 10),
              _buildQuickActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF4CAF50),
                iconBgColor: const Color(0xFFE8F5E9),
                label: "Share via WhatsApp",
                onTap: () {
                  Utils.showSnackbar("Info", "Select an invoice to share via WhatsApp", isError: false);
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionCard(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF2196F3),
                iconBgColor: const Color(0xFFE3F2FD),
                label: "Share via Email",
                onTap: () {
                  Utils.showSnackbar("Info", "Select an invoice to share via Email", isError: false);
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionCard(
                icon: Icons.payment_rounded,
                iconColor: const Color(0xFFFF9800),
                iconBgColor: const Color(0xFFFFF3E0),
                label: "Record Payment",
                onTap: () {
                  Utils.showSnackbar("Info", "Select an unpaid invoice to record payment", isError: false);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5F33E1).withValues(alpha: 0.06),
            const Color(0xFF5F33E1).withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5F33E1).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF5F33E1),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create Professional Invoices",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Add items, taxes, discount, track due dates and send clean PDF bills directly to your customers.",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(RoutesName.createInvoice),
            icon: const Icon(Icons.add, size: 14, color: Colors.white),
            label: const Text(
              "Create New",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F33E1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(dynamic price) {
    if (price == null || price.toString().isEmpty || price == 'null') {
      return "0.00";
    }
    try {
      return double.parse(price.toString()).toStringAsFixed(2);
    } catch (_) {
      return price.toString();
    }
  }

  void _showFilterSheet(BuildContext context, InvoiceListController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filter by Status",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              children: ['All', 'Paid', 'Pending', 'Overdue']
                  .map((status) => Obx(() => ChoiceChip(
                        label: Text(status),
                        selected: controller.selectedStatus.value == status,
                        selectedColor: const Color(0xFF5F33E1).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: controller.selectedStatus.value == status ? const Color(0xFF5F33E1) : Colors.black87,
                          fontWeight: controller.selectedStatus.value == status ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            controller.selectedStatus.value = status;
                            if (status == 'All') controller.selectedTab.value = 'All';
                            if (status == 'Paid') controller.selectedTab.value = 'Paid';
                            if (status == 'Pending') controller.selectedTab.value = 'Pending';
                            if (status == 'Overdue') controller.selectedTab.value = 'Overdue';
                          }
                        },
                      )))
                  .toList(),
            ),
            const SizedBox(height: 25),
            const Text("Filter by Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Obx(() => ListTile(
                  leading: const Icon(Icons.calendar_today_rounded,
                      color: Color(0xFF5F33E1)),
                  title: Text(controller.dateRange.value == null
                      ? "Select Date Range"
                      : "${DateFormat('dd MMM').format(controller.dateRange.value!.start)} - ${DateFormat('dd MMM yyyy').format(controller.dateRange.value!.end)}"),
                  trailing: controller.dateRange.value != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => controller.dateRange.value = null,
                        )
                      : null,
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: controller.dateRange.value,
                    );
                    if (picked != null) {
                      controller.dateRange.value = picked;
                    }
                  },
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("APPLY FILTERS",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
