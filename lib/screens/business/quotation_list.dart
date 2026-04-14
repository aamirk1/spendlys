import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/res/routes/routes_name.dart';

class QuotationListController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final quotations = [].obs;
  final isLoading = true.obs;

  // Search and Filter
  final searchQuery = ''.obs;
  final selectedStatus = 'All'.obs;
  final dateRange = Rxn<DateTimeRange>();

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

      final matchesStatus = selectedStatus.value == 'All' ||
          (q['status'] ?? '').toString().toLowerCase() ==
              selectedStatus.value.toLowerCase();

      bool matchesDate = true;
      if (dateRange.value != null && q['date'] != null) {
        final d = DateTime.parse(q['date']);
        matchesDate = d.isAfter(dateRange.value!.start
                .subtract(const Duration(seconds: 1))) &&
            d.isBefore(
                dateRange.value!.end.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchQuotations();
  }

  Future<void> fetchQuotations() async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;
    
    isLoading.value = true;
    try {
      final response = await ApiService.get('/business/quotations', headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        quotations.value = jsonDecode(response.body);
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load quotations: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'converted':
        return Colors.blue;
      case 'sent':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class QuotationListView extends StatelessWidget {
  const QuotationListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuotationListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quotation History",
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, controller),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  onChanged: (v) => controller.searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: "Search Quotation or Customer...",
                    prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Obx(() => controller.selectedStatus.value != 'All'
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Chip(
                        label: Text("Status: ${controller.selectedStatus.value}"),
                        onDeleted: () => controller.selectedStatus.value = 'All',
                        backgroundColor: Colors.cyan.shade100,
                      ),
                    )
                  : const SizedBox.shrink()),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.cyan));
                  }
                  final items = controller.filteredQuotations;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.request_quote_rounded,
                              size: 80, color: Colors.cyan.withOpacity(0.5)),
                          const SizedBox(height: 20),
                          const Text("No quotations found.",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.black54)),
                        ],
                      ),
                    );
                  }
                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                          .copyWith(bottom: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final quot = items[index];
                        String dateFormatted = "Unknown";
                        if (quot['date'] != null) {
                          try {
                            dateFormatted = DateFormat('dd MMM yyyy')
                                .format(DateTime.parse(quot['date']));
                          } catch (e) {}
                        }

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: GestureDetector(
                                onTap: () {
                                  Get.toNamed(RoutesName.viewQuotation,
                                      arguments: quot);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.cyan.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                quot['quotation_number'] ??
                                                    '#QUO-???',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.blueGrey),
                                              ),
                                              Text(
                                                quot['customer']?['name'] ??
                                                    'Unknown Customer',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: controller
                                                  .getStatusColor(
                                                      quot['status'] ?? 'draft')
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              (quot['status'] ?? 'draft')
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: controller.getStatusColor(
                                                    quot['status'] ?? 'draft'),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("Date",
                                                  style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 12)),
                                              Text(dateFormatted,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text("Total Amount",
                                                  style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 12)),
                                              Text(
                                                "₹${quot['total'] ?? '0.00'}",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, QuotationListController controller) {
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              children: ['All', 'Draft', 'Sent', 'Converted', 'Expired']
                  .map((status) => Obx(() => ChoiceChip(
                        label: Text(status),
                        selected: controller.selectedStatus.value == status,
                        onSelected: (val) {
                          if (val) controller.selectedStatus.value = status;
                        },
                      )))
                  .toList(),
            ),
            const SizedBox(height: 25),
            const Text("Filter by Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Obx(() => ListTile(
                  leading: const Icon(Icons.calendar_today_rounded,
                      color: Colors.cyan),
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
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("APPLY FILTERS",
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
