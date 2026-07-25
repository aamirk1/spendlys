import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/controllers/user_info_controller.dart';
import 'package:spendly/screens/business/business_home_view.dart';

class QuotationListController extends GetxController {
  final quotations = [].obs;
  final isLoading = true.obs;

  // Search and Filter
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final selectedTab = 'All'.obs;
  final dateRange = Rxn<DateTimeRange>();

  int get totalCount => quotations.length;

  int get acceptedCount => quotations.where((q) {
    final status = (q['status'] ?? '').toString().toLowerCase();
    return status == 'converted' || status == 'accepted';
  }).length;

  double get acceptedAmount => quotations.where((q) {
    final status = (q['status'] ?? '').toString().toLowerCase();
    return status == 'converted' || status == 'accepted';
  }).fold(0.0, (sum, q) => sum + (double.tryParse(q['total']?.toString() ?? '0') ?? 0.0));

  int get pendingCount => quotations.where((q) {
    final status = (q['status'] ?? '').toString().toLowerCase();
    return status == 'sent' || status == 'draft' || status == 'pending';
  }).length;

  double get pendingAmount => quotations.where((q) {
    final status = (q['status'] ?? '').toString().toLowerCase();
    return status == 'sent' || status == 'draft' || status == 'pending';
  }).fold(0.0, (sum, q) => sum + (double.tryParse(q['total']?.toString() ?? '0') ?? 0.0));

  int get rejectedCount => quotations.where((q) {
    final status = (q['status'] ?? '').toString().toLowerCase();
    return status == 'expired' || status == 'rejected';
  }).length;

  double get rejectedAmount => quotations.where((q) {
    final status = (q['status'] ?? '').toString().toLowerCase();
    return status == 'expired' || status == 'rejected';
  }).fold(0.0, (sum, q) => sum + (double.tryParse(q['total']?.toString() ?? '0') ?? 0.0));

  List get filteredQuotations {
    return quotations.where((q) {
      final matchesSearch = (q['quotation_number'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          (q['customer']?['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());

      final rawStatus = (q['status'] ?? '').toString().toLowerCase();
      bool matchesStatus = true;
      if (selectedTab.value == 'Accepted') {
        matchesStatus = rawStatus == 'converted' || rawStatus == 'accepted';
      } else if (selectedTab.value == 'Pending') {
        matchesStatus = rawStatus == 'sent' || rawStatus == 'draft' || rawStatus == 'pending';
      } else if (selectedTab.value == 'Rejected') {
        matchesStatus = rawStatus == 'expired' || rawStatus == 'rejected';
      }

      bool matchesDate = true;
      if (dateRange.value != null && q['date'] != null) {
        final d = DateTime.parse(q['date']);
        matchesDate = d.isAfter(
                dateRange.value!.start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(dateRange.value!.end.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchQuotations();
  }

  Future<void> fetchQuotations({bool forceRefresh = false}) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    final cacheKey = 'GET_/business/quotations';
    final cachedData = LocalCacheService.getCache(cacheKey);
    if (!forceRefresh && cachedData != null && cachedData is List) {
      quotations.value = List<Map<String, dynamic>>.from(cachedData);
      return;
    }

    if (cachedData != null && cachedData is List) {
      quotations.value = List<Map<String, dynamic>>.from(cachedData);
    } else {
      isLoading.value = true;
    }

    try {
      final response = await ApiService.get('/business/quotations',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          quotations.value = jsonDecode(response.body);
        }
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load quotations: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteQuotation(String quotationId) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.delete(
          '/business/quotations/$quotationId',
          headers: {'x-user-id': userId});

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? "Offline" : "Success",
            isOffline ? "Quotation deletion scheduled offline. Will sync when online." : "Quotation deleted successfully",
            isError: false);
        quotations.removeWhere((q) => q['id'].toString() == quotationId);
        fetchQuotations(forceRefresh: true);
        if (Get.isRegistered<BusinessHomeController>()) {
          Get.find<BusinessHomeController>().fetchSummary();
        }
      } else {
        Utils.showSnackbar("Error", "Failed to delete quotation: ${response.body}");
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to delete quotation: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'converted':
      case 'accepted':
        return {
          'label': 'Accepted',
          'color': const Color(0xFF4CAF50),
          'bgColor': const Color(0xFFE8F5E9),
          'iconColor': const Color(0xFF4CAF50),
          'iconBgColor': const Color(0xFFE8F5E9),
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'expired':
      case 'rejected':
        return {
          'label': 'Rejected',
          'color': const Color(0xFFF44336),
          'bgColor': const Color(0xFFFFEBEE),
          'iconColor': const Color(0xFFF44336),
          'iconBgColor': const Color(0xFFFFCDD2).withOpacity(0.5),
          'icon': Icons.cancel_outlined,
        };
      case 'sent':
      case 'draft':
      case 'pending':
      default:
        return {
          'label': status.toLowerCase() == 'draft' ? 'Draft' : 'Pending',
          'color': const Color(0xFFFF9800),
          'bgColor': const Color(0xFFFFF3E0),
          'iconColor': const Color(0xFF5F33E1),
          'iconBgColor': const Color(0xFFF3EFFF),
          'icon': Icons.description_rounded,
        };
    }
  }
}

class QuotationListView extends StatelessWidget {
  const QuotationListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuotationListController());
    const Color primaryColor = Color(0xFF5F33E1);
    const Color accentColor = Color(0xFFF3EFFF);

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
              "Quotations",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage all your quotations",
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
              onPressed: () => Get.toNamed(RoutesName.createQuotation),
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
          onRefresh: () => controller.fetchQuotations(forceRefresh: true),
          color: primaryColor,
          child: SingleChildScrollView(
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

                // 4. Quotation cards list
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
                    final items = controller.filteredQuotations;
                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.request_quote_rounded, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              "No quotations found",
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
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final quot = items[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: FadeInAnimation(
                                child: _buildQuotationItemCard(context, quot, controller),
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

                // 6. Professional Quotation Promo Card
                _buildPromoCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(QuotationListController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.description_rounded,
            iconColor: const Color(0xFF5F33E1),
            iconBgColor: const Color(0xFFF3EFFF),
            title: "Total Quotations",
            value: "${controller.totalCount}",
            subtitle: "This Month",
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF4CAF50),
            iconBgColor: const Color(0xFFE8F5E9),
            title: "Accepted",
            value: "${controller.acceptedCount}",
            subtitle: "₹${_formatPrice(controller.acceptedAmount)}",
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFFFF9800),
            iconBgColor: const Color(0xFFFFF3E0),
            title: "Pending",
            value: "${controller.pendingCount}",
            subtitle: "₹${_formatPrice(controller.pendingAmount)}",
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFF44336),
            iconBgColor: const Color(0xFFFFEBEE),
            title: "Rejected",
            value: "${controller.rejectedCount}",
            subtitle: "₹${_formatPrice(controller.rejectedAmount)}",
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
    required String subtitle,
  }) {
    return Container(
      width: 125,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
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
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTabsSection(QuotationListController controller) {
    final tabs = ['All', 'Accepted', 'Pending', 'Rejected'];
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

  Widget _buildSearchSortRow(QuotationListController controller) {
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
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                onChanged: (v) => controller.searchQuery.value = v,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Search by quotation no. or customer...",
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
              border: Border.all(color: const Color(0xFF5F33E1).withOpacity(0.1)),
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

  Widget _buildQuotationItemCard(BuildContext context, Map<String, dynamic> quot, QuotationListController controller) {
    String dateFormatted = "Unknown";
    if (quot['date'] != null) {
      try {
        dateFormatted = DateFormat('dd Jul yyyy').format(DateTime.parse(quot['date']));
      } catch (_) {}
    }
    
    String expiryFormatted = "";
    if (quot['expiry_date'] != null) {
      try {
        expiryFormatted = DateFormat('dd Jul yyyy').format(DateTime.parse(quot['expiry_date']));
      } catch (_) {}
    }

    final statusDetails = controller.getStatusDetails(quot['status'] ?? 'draft');
    final totalAmount = double.tryParse(quot['total']?.toString() ?? '0') ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(RoutesName.viewQuotation, arguments: quot);
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
                    quot['quotation_number'] ?? '#QT-0000',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quot['customer']?['name'] ?? 'Unknown Customer',
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
                if (expiryFormatted.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Valid till $expiryFormatted",
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
                const SizedBox(height: 4),
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
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF5F33E1),
                iconBgColor: const Color(0xFFF3EFFF),
                label: "Create Quotation",
                onTap: () => Get.toNamed(RoutesName.createQuotation),
              ),
              const SizedBox(width: 10),
              _buildQuickActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF4CAF50),
                iconBgColor: const Color(0xFFE8F5E9),
                label: "Share via WhatsApp",
                onTap: () {
                  Utils.showSnackbar("Info", "Select a quotation to share via WhatsApp", isError: false);
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionCard(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF2196F3),
                iconBgColor: const Color(0xFFE3F2FD),
                label: "Share via Email",
                onTap: () {
                  Utils.showSnackbar("Info", "Select a quotation to share via Email", isError: false);
                },
              ),
              const SizedBox(width: 10),
              _buildQuickActionCard(
                icon: Icons.swap_horiz_rounded,
                iconColor: const Color(0xFFFF9800),
                iconBgColor: const Color(0xFFFFF3E0),
                label: "Convert to Invoice",
                onTap: () {
                  Utils.showSnackbar("Info", "Select a quotation from the list to convert", isError: false);
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
                color: Colors.black.withOpacity(0.01),
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
            const Color(0xFF5F33E1).withOpacity(0.06),
            const Color(0xFF5F33E1).withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF5F33E1).withOpacity(0.15)),
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
              Icons.design_services_outlined,
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
                  "Create Professional Quotations",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Add items, taxes, terms & conditions and send professional quotations to your customers.",
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
            onPressed: () => Get.toNamed(RoutesName.createQuotation),
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

  void _showFilterSheet(BuildContext context, QuotationListController controller) {
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
              children: ['All', 'Draft', 'Sent', 'Converted', 'Expired']
                  .map((status) => Obx(() => ChoiceChip(
                        label: Text(status),
                        selected: controller.selectedStatus.value == status,
                        selectedColor: const Color(0xFF5F33E1).withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: controller.selectedStatus.value == status ? const Color(0xFF5F33E1) : Colors.black87,
                          fontWeight: controller.selectedStatus.value == status ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) {
                            controller.selectedStatus.value = status;
                            // Map selectedStatus to selectedTab
                            if (status == 'All') controller.selectedTab.value = 'All';
                            if (status == 'Converted') controller.selectedTab.value = 'Accepted';
                            if (status == 'Sent' || status == 'Draft') controller.selectedTab.value = 'Pending';
                            if (status == 'Expired') controller.selectedTab.value = 'Rejected';
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
