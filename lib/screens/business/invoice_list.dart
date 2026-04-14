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

class InvoiceListController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
  final dateRange = Rxn<DateTimeRange>();

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
    setupScrollListener();
  }

  void setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (hasMoreData && !isMoreLoading.value && !isLoading.value) {
          fetchInvoices(loadMore: true);
        }
      }
    });
  }

  Future<void> fetchInvoices(
      {bool loadMore = false, bool refresh = false}) async {
    String? userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    if (refresh) {
      currentPage = 1;
      hasMoreData = true;
    }

    if (loadMore) {
      isMoreLoading.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      final endpoint = '/business/invoices?page=$currentPage&limit=$limit';
      final response =
          await ApiService.get(endpoint, headers: {'x-user-id': userId});

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

      final matchesStatus = selectedStatus.value == 'All' ||
          (inv['status'] ?? '').toString().toLowerCase() ==
              selectedStatus.value.toLowerCase();

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

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class InvoiceListView extends StatelessWidget {
  const InvoiceListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvoiceListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice History",
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
            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
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
                    hintText: "Search Invoice or Customer...",
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
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
                        label:
                            Text("Status: ${controller.selectedStatus.value}"),
                        onDeleted: () =>
                            controller.selectedStatus.value = 'All',
                        backgroundColor: Colors.orange.shade100,
                      ),
                    )
                  : const SizedBox.shrink()),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.orange));
                  }
                  final items = controller.filteredInvoices;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 80, color: Colors.orange.withOpacity(0.5)),
                          const SizedBox(height: 20),
                          const Text("No invoices found.",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.black54)),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => controller.fetchInvoices(refresh: true),
                    color: Colors.orange,
                    child: AnimationLimiter(
                      child: ListView.builder(
                        controller: controller.scrollController,
                        padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)
                            .copyWith(bottom: 20),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length +
                            (controller.isMoreLoading.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == items.length) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(15.0),
                              child: CircularProgressIndicator(
                                  color: Colors.orange),
                            ));
                          }
                          final inv = items[index];
                          String dateFormatted = "Unknown";
                          if (inv['date'] != null) {
                            try {
                              dateFormatted = DateFormat('dd MMM yyyy')
                                  .format(DateTime.parse(inv['date']));
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
                                    Get.toNamed(RoutesName.viewInvoice,
                                        arguments: inv);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 15),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.orange.withOpacity(0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8))
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                  inv['invoice_number'] ??
                                                      '#INV-???',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.blueGrey),
                                                ),
                                                Text(
                                                  inv['customer']?['name'] ??
                                                      'Unknown Customer',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: controller
                                                    .getStatusColor(
                                                        inv['status'] ??
                                                            'pending')
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                (inv['status'] ?? 'pending')
                                                    .toString()
                                                    .toUpperCase()
                                                    .replaceAll('_', ' '),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      controller.getStatusColor(
                                                          inv['status'] ??
                                                              'pending'),
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
                                                        color: Colors
                                                            .grey.shade600,
                                                        fontSize: 12)),
                                                Text(dateFormatted,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text("Amount",
                                                    style: TextStyle(
                                                        color: Colors
                                                            .grey.shade600,
                                                        fontSize: 12)),
                                                Text(
                                                  "₹${inv['total'] ?? '0.00'}",
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.black87),
                                                ),
                                                if ((inv['paid_amount'] ??
                                                            0.0) >
                                                        0 &&
                                                    inv['status'] != 'paid')
                                                  Text(
                                                    "Paid: ₹${inv['paid_amount']}",
                                                    style: const TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold),
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
      BuildContext context, InvoiceListController controller) {
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
              children: ['All', 'Paid', 'Pending', 'Overdue', 'Partially Paid']
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
                      color: Colors.orange),
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
                    backgroundColor: Colors.orange,
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
