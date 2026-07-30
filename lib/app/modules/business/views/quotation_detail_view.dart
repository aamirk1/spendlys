import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/modules/business/views/quotation_list_view.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'dart:convert';
import 'package:spendly/app/utils/business_pdf_helper.dart';
import 'package:spendly/app/modules/premium/controllers/payment_controller.dart';
import 'package:spendly/app/common_widgets/premium_dialogs.dart';

class QuotationDetailView extends StatelessWidget {
  const QuotationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Utils.showSnackbar("Error", "Quotation data missing.");
      });
      return const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }

    final Map<String, dynamic> quot = args;

    // Safer item handling
    final dynamic itemsData = quot['items'] ?? [];
    final List items = itemsData is String ? jsonDecode(itemsData) : itemsData;

    String formatDate(dynamic d) {
      if (d == null || d.toString().isEmpty || d == 'null') return "N/A";
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(d.toString()));
      } catch (_) {
        return "N/A";
      }
    }

    final String dateFormatted = formatDate(quot['date']);
    final String expiryFormatted = formatDate(quot['expiry_date']);
    const Color primaryColor = Color(0xFF5F33E1);

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              quot['quotation_number'] ?? "Quotation Detail",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Quotation summary and details",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (quot['status'] != 'converted')
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.black87, size: 22),
              tooltip: "Edit",
              onPressed: () =>
                  Get.toNamed(RoutesName.editQuotation, arguments: quot),
            ),
          if (quot['status'] != 'converted')
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.black87, size: 22),
              tooltip: "Convert to Invoice",
              onPressed: () => _showConvertDialog(context, quot),
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: Colors.black87, size: 22),
            tooltip: "Download PDF",
            onPressed: () => _downloadPdf(quot),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: Colors.black87, size: 22),
            tooltip: "Share PDF",
            onPressed: () => _sharePdf(quot),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(quot),
              const SizedBox(height: 16),

              // Physical Document Sheet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doc Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("QUOTATION",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.black87,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(quot['quotation_number'] ?? "N/A",
                                style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Date: $dateFormatted",
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text("Valid: $expiryFormatted",
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Bill To Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("BILL TO",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              Text(
                                quot['customer_name'] ??
                                    quot['customer']?['name'] ??
                                    quot['customer']?['full_name'] ??
                                    "Unknown Customer",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87),
                              ),
                              if (quot['customer']?['phone'] != null &&
                                  quot['customer']!['phone']
                                      .toString()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                    quot['customer']?['phone'].toString() ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ]
                            ],
                          ),
                        ),
                        if (quot['payment_mode'] != null &&
                            quot['payment_mode'].toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("PAYMENT MODE",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              Text(
                                quot['payment_mode'].toString().toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Items Headers
                    Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text("ITEMS",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5))),
                        Expanded(
                            child: Text("QTY",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5))),
                        Expanded(
                            child: Text("PRICE",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5))),
                        Expanded(
                            child: Text("AMOUNT",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                      item['description'] ?? "No Description",
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600))),
                              Expanded(
                                  child: Text("${item['quantity']}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700))),
                              Expanded(
                                  child: Text(
                                      "₹${_formatPrice(item['unit_price'])}",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700))),
                              Expanded(
                                  child: Text(
                                      "₹${_formatPrice(item['amount'])}",
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Summary
                    _buildSummaryRow(
                        "Subtotal", "₹${_formatPrice(quot['subtotal'])}"),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      "Tax (${quot['tax_percent']?.toInt() ?? ((quot['tax'] ?? 0.0) / (quot['subtotal'] ?? 1.0) * 100).toInt()}%)",
                      "₹${_formatPrice(quot['tax'])}",
                    ),
                    if ((quot['advance_amount'] ?? 0.0) > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow("Advance Paid",
                          "₹${_formatPrice(quot['advance_amount'])}"),
                    ],
                    const SizedBox(height: 12),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                        "Grand Total", "₹${_formatPrice(quot['total'])}",
                        isTotal: true),
                    if ((quot['advance_amount'] ?? 0.0) > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        "Remaining Balance",
                        "₹${_formatPrice((quot['total'] ?? 0.0) - (quot['advance_amount'] ?? 0.0))}",
                        isTotal: true,
                        totalColor: primaryColor,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (quot['status'] != 'converted')
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showConvertDialog(context, quot),
                    icon: const Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 20),
                    label: const Text("Convert to Invoice",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Map<String, dynamic> quot) {
    final status = (quot['status'] ?? 'draft').toString().toLowerCase();
    Color color = Colors.orange;
    Color bgColor = const Color(0xFFFFF3E0);
    IconData icon = Icons.info_outline_rounded;
    String label = "PENDING";

    if (status == 'converted' || status == 'accepted') {
      color = const Color(0xFF4CAF50);
      bgColor = const Color(0xFFE8F5E9);
      icon = Icons.check_circle_outline_rounded;
      label = "ACCEPTED / CONVERTED";
    } else if (status == 'expired' || status == 'rejected') {
      color = const Color(0xFFF44336);
      bgColor = const Color(0xFFFFEBEE);
      icon = Icons.cancel_outlined;
      label = "EXPIRED / REJECTED";
    } else if (status == 'draft') {
      color = const Color(0xFF5F33E1);
      bgColor = const Color(0xFFF3EFFF);
      icon = Icons.edit_note_rounded;
      label = "DRAFT";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            "Status: $label",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, Color? totalColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black87 : Colors.grey.shade500,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color:
                totalColor ?? (isTotal ? Colors.black87 : Colors.grey.shade800),
            fontSize: isTotal ? 15 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null || price.toString().isEmpty || price == 'null') {
      return "0.00";
    }
    try {
      return double.parse(price.toString()).toStringAsFixed(2);
    } catch (_) {
      return price.toString();
    }
  }

  void _showConvertDialog(BuildContext context, Map<String, dynamic> quot) {
    const Color primaryColor = Color(0xFF5F33E1);
    Get.defaultDialog(
      title: "Convert to Invoice",
      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      middleText:
          "Are you sure you want to convert this quotation to an invoice? This will create a new invoice with the same items.",
      middleTextStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      textConfirm: "Convert",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.grey,
      buttonColor: primaryColor,
      radius: 16,
      onConfirm: () async {
        Get.back(); // close dialog
        _convertToInvoice(quot);
      },
    );
  }

  Future<void> _convertToInvoice(Map<String, dynamic> quot) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF5F33E1))),
      barrierDismissible: false,
    );
    try {
      final response = await ApiService.post(
        '/business/quotations/${quot['id']}/convert-to-invoice',
        headers: {'Content-Type': 'application/json', 'x-user-id': userId},
      );

      Get.back(); // hide loading
      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Converted to invoice successfully!",
            isError: false);
        if (Get.isRegistered<QuotationListController>()) {
          Get.find<QuotationListController>().fetchQuotations();
        }
        Get.back(); // back to list
      } else {
        Utils.showSnackbar("Error", "Failed to convert: ${response.body}");
      }
    } catch (e) {
      Get.back(); // hide loading
      Utils.showSnackbar("Error", "An error occurred: $e");
    }
  }

  Future<void> _downloadPdf(Map<String, dynamic> quot) async {
    final paymentController = Get.put(PaymentController());
    if (!paymentController.isPremium.value) {
      PremiumDialogs.showPremiumRequiredDialog();
      return;
    }

    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.dialog(
        const Center(
            child: CircularProgressIndicator(color: Color(0xFF5F33E1))),
        barrierDismissible: false);
    try {
      final busResp = await ApiService.get('/business/profile',
          headers: {'x-user-id': userId});
      if (busResp.statusCode != 200) {
        Get.back();
        Utils.showSnackbar(
            "Error", "Please complete your business profile first.");
        return;
      }
      final businessProfile = jsonDecode(busResp.body);

      dynamic rawCust = quot['customer'];
      Map<String, dynamic> customer = {};
      if (rawCust is String) {
        try {
          customer = jsonDecode(rawCust);
        } catch (_) {}
      } else if (rawCust is Map) {
        customer = Map<String, dynamic>.from(rawCust);
      }

      if ((customer['name'] == null || customer['name'].toString().isEmpty) &&
          quot['customer_id'] != null) {
        final custResp = await ApiService.get(
            '/business/customers/${quot['customer_id']}',
            headers: {'x-user-id': userId});
        if (custResp.statusCode == 200) {
          customer = jsonDecode(custResp.body);
        }
      }

      Get.back(); // hide loading
      await BusinessPdfHelper.generateAndPrintPdf(
        title: "QUOTATION",
        businessProfile: businessProfile,
        customer: customer,
        docData: quot,
        items: quot['items'] ?? [],
        isInvoice: false,
      );
    } catch (e) {
      Get.back();
      Utils.showSnackbar("Error", "PDF Generation failed: $e");
    }
  }

  Future<void> _sharePdf(Map<String, dynamic> quot) async {
    final paymentController = Get.put(PaymentController());
    if (!paymentController.isPremium.value) {
      PremiumDialogs.showPremiumRequiredDialog();
      return;
    }

    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.dialog(
        const Center(
            child: CircularProgressIndicator(color: Color(0xFF5F33E1))),
        barrierDismissible: false);
    try {
      final busResp = await ApiService.get('/business/profile',
          headers: {'x-user-id': userId});
      if (busResp.statusCode != 200) {
        Get.back();
        Utils.showSnackbar(
            "Error", "Please complete your business profile first.");
        return;
      }
      final businessProfile = jsonDecode(busResp.body);

      dynamic rawCust = quot['customer'];
      Map<String, dynamic> customer = {};
      if (rawCust is String) {
        try {
          customer = jsonDecode(rawCust);
        } catch (_) {}
      } else if (rawCust is Map) {
        customer = Map<String, dynamic>.from(rawCust);
      }

      if ((customer['name'] == null || customer['name'].toString().isEmpty) &&
          quot['customer_id'] != null) {
        final custResp = await ApiService.get(
            '/business/customers/${quot['customer_id']}',
            headers: {'x-user-id': userId});
        if (custResp.statusCode == 200) {
          customer = jsonDecode(custResp.body);
        }
      }

      Get.back(); // hide loading
      await BusinessPdfHelper.generateAndSharePdf(
        title: "QUOTATION",
        businessProfile: businessProfile,
        customer: customer,
        docData: quot,
        items: quot['items'] ?? [],
        isInvoice: false,
      );
    } catch (e) {
      Get.back();
      Utils.showSnackbar("Error", "PDF Share failed: $e");
    }
  }
}
