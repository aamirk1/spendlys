import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:spendly/res/routes/routes_name.dart';

class QuotationListController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final quotations = [].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchQuotations();
  }

  Future<void> fetchQuotations() async {
    String? userId = _auth.currentUser?.uid;
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
        title: const Text("Quotation History", style: TextStyle(fontWeight: FontWeight.bold)),
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
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyan));
            }
            if (controller.quotations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.request_quote_rounded, size: 80, color: Colors.cyan.withOpacity(0.5)),
                    const SizedBox(height: 20),
                    const Text("No quotations generated yet.", style: TextStyle(fontSize: 18, color: Colors.black54)),
                  ],
                ),
              );
            }
            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10).copyWith(bottom: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.quotations.length,
                itemBuilder: (context, index) {
                  final quot = controller.quotations[index];
                  String dateFormatted = "Unknown";
                  if (quot['date'] != null) {
                    try {
                      dateFormatted = DateFormat('dd MMM yyyy').format(DateTime.parse(quot['date']));
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
                            Get.toNamed(RoutesName.viewQuotation, arguments: quot);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      quot['quotation_number'] ?? '#QUO-???',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: controller.getStatusColor(quot['status'] ?? 'draft').withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        (quot['status'] ?? 'draft').toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: controller.getStatusColor(quot['status'] ?? 'draft'),
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
                                        Text("Total Amount", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        Text(
                                          "₹${quot['total'] ?? '0.00'}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
