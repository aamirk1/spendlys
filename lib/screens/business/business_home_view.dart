import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/services/business_service.dart';
import 'package:spendly/widgets/business_dialogs.dart';

class BusinessHomeController extends GetxController {
  final totalRevenue = 0.0.obs;
  final paidAmount = 0.0.obs;
  final pendingAmount = 0.0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    Get.find<BusinessService>().checkProfileStatus();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.get('/business/invoices',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        final List invoices = jsonDecode(response.body);
        double total = 0;
        double paidAcc = 0;
        double pending = 0;
        for (var inv in invoices) {
          double invTotal = (inv['total'] ?? 0.0).toDouble();
          double invPaid = (inv['paid_amount'] ?? 0.0).toDouble();
          total += invTotal;
          paidAcc += invPaid;
          pending += (invTotal - invPaid);
        }
        totalRevenue.value = total;
        paidAmount.value = paidAcc;
        pendingAmount.value = pending;
      }
    } catch (e) {
      debugPrint("Error fetching summary: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

class BusinessHomeView extends StatelessWidget {
  const BusinessHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BusinessHomeController());
    final Color primaryColor = const Color(0xFF5F33E1); // Premium Deep Purple/Indigo
    final Color accentColor = const Color(0xFFF3EFFF); // Light Purple
    final textTheme = Theme.of(context).textTheme;

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
            Text(
              "business_center_title".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage sales, billing & stocks",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => controller.fetchSummary(),
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.fetchSummary(),
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Business Header Profile
                _buildHeader(context, primaryColor),
                const SizedBox(height: 20),

                // 2. Quick Actions
                Text(
                  "Quick Operations",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 10),
                _buildQuickActions(context, primaryColor),
                const SizedBox(height: 24),

                // 3. Analytics Summary (Sales, Paid, Unpaid)
                _buildAnalyticsSummary(context, controller, primaryColor),
                const SizedBox(height: 24),

                // 4. Management Dashboard Grid (Replacing boring list tiles)
                Text(
                  "management".tr,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 10),
                _buildModuleGrid(context, primaryColor),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "business_header_title".tr,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "business_header_subtitle".tr,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.7), size: 14),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        _actionButton(
          context,
          icon: Icons.receipt_long_rounded,
          label: "create_invoice".tr,
          subtitle: "Create digital bills",
          color: Colors.orange,
          onTap: () => _safeNavigate(RoutesName.createInvoice),
        ),
        const SizedBox(width: 14),
        _actionButton(
          context,
          icon: Icons.request_quote_rounded,
          label: "quotation".tr,
          subtitle: "Create estimate quotes",
          color: Colors.teal,
          onTap: () => _safeNavigate(RoutesName.createQuotation),
        ),
      ],
    );
  }

  void _safeNavigate(String route) async {
    final businessService = Get.find<BusinessService>();

    if (businessService.isProfileCreated.value) {
      Get.toNamed(route);
    } else {
      // Try refreshing status once before showing dialog
      await businessService.checkProfileStatus();
      if (businessService.isProfileCreated.value) {
        Get.toNamed(route);
      } else {
        BusinessDialogs.showProfileRequiredDialog();
      }
    }
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary(BuildContext context, BusinessHomeController controller, Color primaryColor) {
    return Obx(() {
      final String monthYear = DateFormat('MMMM yyyy').format(DateTime.now());

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "monthly_revenue".tr,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    monthYear,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (controller.isLoading.value)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Revenue", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      Text(
                        "₹${controller.totalRevenue.value.toStringAsFixed(0)}",
                        style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statItem("paid_label".tr, "₹${controller.paidAmount.value.toStringAsFixed(0)}", Colors.green),
                      ),
                      Container(width: 1, height: 36, color: Colors.grey.shade200),
                      Expanded(
                        child: _statItem("pending".tr, "₹${controller.pendingAmount.value.toStringAsFixed(0)}", Colors.redAccent),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildModuleGrid(BuildContext context, Color primaryColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: [
        _gridTile(
          context,
          icon: Icons.people_outline_rounded,
          title: "customers".tr,
          subtitle: "clients_ledgers".tr,
          color: Colors.indigo,
          onTap: () => _safeNavigate(RoutesName.customersList),
        ),
        _gridTile(
          context,
          icon: Icons.history_rounded,
          title: "invoice_history".tr,
          subtitle: "past_transactions".tr,
          color: Colors.deepPurple,
          onTap: () => _safeNavigate(RoutesName.invoiceList),
        ),
        _gridTile(
          context,
          icon: Icons.request_quote_outlined,
          title: "quotation_history".tr,
          subtitle: "view_past_quotes".tr,
          color: Colors.teal,
          onTap: () => _safeNavigate(RoutesName.quotationList),
        ),
        _gridTile(
          context,
          icon: Icons.inventory_2_outlined,
          title: "Inventory",
          subtitle: "Products & Stock",
          color: Colors.blue,
          onTap: () => _safeNavigate(RoutesName.inventoryList),
        ),
        _gridTile(
          context,
          icon: Icons.settings_suggest_rounded,
          title: "business_profile".tr,
          subtitle: "Profile settings",
          color: Colors.blueGrey,
          onTap: () => Get.toNamed(RoutesName.businessProfile),
        ),
      ],
    );
  }

  Widget _gridTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
