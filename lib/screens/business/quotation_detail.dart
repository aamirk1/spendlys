import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/screens/business/quotation_list.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'dart:convert';
import 'package:spendly/utils/business_pdf_helper.dart';

class QuotationDetailView extends StatelessWidget {
  const QuotationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> quot = Get.arguments;
    
    // Safer item handling
    final dynamic itemsData = quot['items'] ?? [];
    final List items = itemsData is String ? jsonDecode(itemsData) : itemsData;

    String formatDate(dynamic d) {
      if (d == null || d.toString().isEmpty || d == 'null') return "N/A";
      try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d.toString())); } 
      catch (_) { return "N/A"; }
    }

    final String dateFormatted = formatDate(quot['date']);

    return Scaffold(
      appBar: AppBar(
        title: Text(quot['quotation_number'] ?? "Quotation Detail"),
        actions: [
          if (quot['status'] != 'converted')
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: "Edit",
              onPressed: () =>
                  Get.toNamed(RoutesName.editQuotation, arguments: quot),
            ),
          if (quot['status'] != 'converted')
            IconButton(
              icon: const Icon(Icons.transform_rounded),
              tooltip: "Convert to Invoice",
              onPressed: () => _showConvertDialog(context, quot),
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Download PDF",
            onPressed: () => _downloadPdf(quot),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share PDF",
            onPressed: () => _sharePdf(quot),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(quot),
            const SizedBox(height: 20),
            _buildSectionTitle("Customer Info"),
            _buildInfoCard([
              _buildInfoRow(
                  "Customer",
                  quot['customer_name'] ??
                      quot['customer']?['name'] ??
                      quot['customer']?['full_name'] ??
                      "Loading..."),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle("Quotation Info"),
            _buildInfoCard([
              _buildInfoRow("Number", quot['quotation_number'] ?? "N/A"),
              _buildInfoRow("Date", dateFormatted),
              _buildInfoRow(
                "Expiry",
                formatDate(quot['expiry_date']),
              ),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle("Items"),
            ...items.map((item) => _buildItemCard(item)),
            const SizedBox(height: 20),
            _buildSummaryCard(quot),
            const SizedBox(height: 30),
            if (quot['status'] != 'converted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showConvertDialog(context, quot),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text("Convert to Invoice"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Map<String, dynamic> quot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.cyan),
          const SizedBox(width: 12),
          Text(
            "Status: ${quot['status']?.toUpperCase() ?? 'DRAFT'}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item['description'] ?? "No Description"),
        subtitle: Text("Qty: ${item['quantity']} \u00d7 \u20b9${item['unit_price']}"),
        trailing: Text(
          "\u20b9${item['amount']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> quot) {
    return Card(
      color: Colors.blueGrey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow("Subtotal", "\u20b9${quot['subtotal']}"),
            _buildInfoRow(
                "Tax (${quot['tax_percent']?.toInt() ?? ((quot['tax'] ?? 0.0) / (quot['subtotal'] ?? 1.0) * 100).toInt()}%)",
                "\u20b9${quot['tax']}"),
            _buildInfoRow(
              "Advance Paid",
              "\u20b9${quot['advance_amount'] ?? '0.00'}",
            ),
            const Divider(),
            _buildInfoRow("Total", "\u20b9${quot['total']}"),
            if ((quot['advance_amount'] ?? 0.0) > 0)
              _buildInfoRow(
                "Remaining Balance",
                "\u20b9${(quot['total'] ?? 0.0) - (quot['advance_amount'] ?? 0.0)}",
              ),
          ],
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext context, Map<String, dynamic> quot) {
    Get.defaultDialog(
      title: "Convert to Invoice",
      middleText:
          "Are you sure you want to convert this quotation to an invoice? This will create a new invoice with the same items.",
      textConfirm: "Convert",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.cyan,
      onConfirm: () async {
        Get.back(); // close dialog
        _convertToInvoice(quot);
      },
    );
  }

  Future<void> _convertToInvoice(Map<String, dynamic> quot) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final response = await ApiService.post(
        '/business/quotations/${quot['id']}/convert-to-invoice',
        headers: {'Content-Type': 'application/json', 'x-user-id': userId},
      );

      Get.back(); // hide loading
      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar(
          "Success",
          "Converted to invoice successfully!",
          isError: false,
        );
        // Refresh quotation list if possible or just go back
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      // 1. Fetch Business Profile
      final busResp = await ApiService.get('/business/profile',
          headers: {'x-user-id': userId});
      if (busResp.statusCode != 200) {
        Get.back();
        Utils.showSnackbar(
            "Error", "Please complete your business profile first.");
        return;
      }
      final businessProfile = jsonDecode(busResp.body);

      // 2. Extract Customer Info
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

      // 3. Generate and Print
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      // 1. Fetch Business Profile
      final busResp = await ApiService.get('/business/profile',
          headers: {'x-user-id': userId});
      if (busResp.statusCode != 200) {
        Get.back();
        Utils.showSnackbar(
            "Error", "Please complete your business profile first.");
        return;
      }
      final businessProfile = jsonDecode(busResp.body);

      // 2. Extract Customer Info
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

      // 3. Generate and Share
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
