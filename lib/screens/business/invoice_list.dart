import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/res/routes/routes_name.dart';

class InvoiceListController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final invoices = [].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    isLoading.value = true;
    try {
      final response = await ApiService.get('/business/invoices', headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        invoices.value = jsonDecode(response.body);
      }
    } catch (e) {
      Utils.showSnackbar("Error", "Failed to load invoices: $e");
    } finally {
      isLoading.value = false;
    }
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
        title: const Text("Invoice History", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
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
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }
            if (controller.invoices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 80, color: Colors.orange.withOpacity(0.5)),
                    const SizedBox(height: 20),
                    const Text("No invoices generated yet.", style: TextStyle(fontSize: 18, color: Colors.black54)),
                  ],
                ),
              );
            }
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10).copyWith(bottom: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.invoices.length,
                itemBuilder: (context, index) {
                  final inv = controller.invoices[index];
                  String dateFormatted = "Unknown";
                  if (inv['date'] != null) {
                    try {
                      dateFormatted = DateFormat('dd MMM yyyy').format(DateTime.parse(inv['date']));
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
                            Get.toNamed(RoutesName.viewInvoice, arguments: inv);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inv['invoice_number'] ?? '#INV-???',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                                        ),
                                        Text(
                                          inv['customer']?['name'] ?? 'Unknown Customer',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: controller.getStatusColor(inv['status'] ?? 'pending').withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        (inv['status'] ?? 'pending').toString().toUpperCase().replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: controller.getStatusColor(inv['status'] ?? 'pending'),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Date", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        Text(dateFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("Amount", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        Text(
                                          "₹${inv['total'] ?? '0.00'}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                        ),
                                        if ((inv['paid_amount'] ?? 0.0) > 0 && inv['status'] != 'paid')
                                          Text(
                                            "Paid: ₹${inv['paid_amount']}",
                                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
