import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/res/routes/routes_name.dart';

class BusinessHomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final totalRevenue = 0.0.obs;
  final pendingAmount = 0.0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.get('/business/invoices',
          headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        final List invoices = jsonDecode(response.body);
        double total = 0;
        double pending = 0;
        for (var inv in invoices) {
          double invTotal = (inv['total'] ?? 0.0).toDouble();
          double paid = (inv['paid_amount'] ?? 0.0).toDouble();
          total += invTotal;
          pending += (invTotal - paid);
        }
        totalRevenue.value = total;
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("business_center_title".tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => controller.fetchSummary(),
            icon: const Icon(Icons.refresh_rounded),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchSummary(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 25),
              _buildQuickActions(context),
              const SizedBox(height: 30),
              _buildAnalyticsSummary(context, controller),
              const SizedBox(height: 30),
              Text("management".tr,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(height: 15),
              _buildModuleList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).primaryColor,
          Theme.of(context).primaryColor.withOpacity(0.8),
        ]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.business_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("business_header_title".tr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("business_header_subtitle".tr,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _actionButton(context, Icons.receipt_long_rounded, "create_invoice".tr,
            Colors.orange, () => Get.toNamed(RoutesName.createInvoice)),
        const SizedBox(width: 15),
        _actionButton(context, Icons.request_quote_rounded, "quotation".tr,
            Colors.teal, () => Get.toNamed(RoutesName.createQuotation)),
      ],
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary(
      BuildContext context, BusinessHomeController controller) {
    return Obx(() {
      final String monthYear = DateFormat('MMMM yyyy').format(DateTime.now());

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("monthly_revenue".tr,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color)),
                Text(monthYear,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).disabledColor)),
              ],
            ),
            const SizedBox(height: 20),
            if (controller.isLoading.value)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(10.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                      "pending".tr,
                      "₹${controller.pendingAmount.value.toStringAsFixed(2)}",
                      Colors.redAccent,
                      context),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _statItem(
      String label, String value, Color color, BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12)),
      ],
    );
  }

  Widget _buildModuleList(BuildContext context) {
    return Column(
      children: [
        _luxuryListTile(
            context,
            Icons.group_rounded,
            "customers".tr,
            "clients_ledgers".tr,
            Colors.indigo,
            () => Get.toNamed(RoutesName.customersList)),
        _luxuryListTile(
            context,
            Icons.history_rounded,
            "invoice_history".tr,
            "past_transactions".tr,
            Colors.deepPurple,
            () => Get.toNamed(RoutesName.invoiceList)),
        _luxuryListTile(
            context,
            Icons.request_quote_outlined,
            "quotation_history".tr,
            "view_past_quotes".tr,
            Colors.teal,
            () => Get.toNamed(RoutesName.quotationList)),
        _luxuryListTile(
            context,
            Icons.settings_suggest_rounded,
            "business_profile".tr,
            "account_settings".tr,
            Colors.blueGrey,
            () => Get.toNamed(RoutesName.businessProfile)),
        _luxuryListTile(
            context,
            Icons.inventory_2_rounded,
            "Inventory Management",
            "Products & Stock",
            Colors.teal,
            () => Get.toNamed(RoutesName.inventoryList)),
      ],
    );
  }

  Widget _luxuryListTile(BuildContext context, IconData icon, String title,
      String subtitle, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
