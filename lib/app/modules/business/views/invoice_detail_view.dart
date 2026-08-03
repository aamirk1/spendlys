import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/app/data/services/api_service.dart';
import 'package:spendly/app/data/services/auth_service.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:spendly/app/modules/business/controllers/invoice_list_controller.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'dart:convert';
import 'package:spendly/app/utils/business_pdf_helper.dart';

class InvoiceDetailView extends StatelessWidget {
  const InvoiceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic args = Get.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Utils.showSnackbar("Error", "Invoice data missing.");
      });
      return const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }

    final Map<String, dynamic> inv = args;

    // Safer item handling
    final dynamic itemsData = inv['items'] ?? [];
    final List items = itemsData is String ? jsonDecode(itemsData) : itemsData;

    String formatDate(dynamic d) {
      if (d == null || d.toString().isEmpty || d == 'null') return "N/A";
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(d.toString()));
      } catch (_) {
        return "N/A";
      }
    }

    final String dateFormatted = formatDate(inv['date']);
    final String dueDateFormatted = formatDate(inv['due_date']);
    final Color primaryColor =
        const Color(0xFF5F33E1); // Premium Deep Purple/Indigo

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
              inv['invoice_number'] ?? "Invoice Detail",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              "Invoice summary and details",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.black87, size: 22),
            onPressed: () =>
                Get.toNamed(RoutesName.editInvoice, arguments: inv),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 22),
            tooltip: "Delete Invoice",
            onPressed: () => _deleteInvoice(context, inv),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: Colors.black87, size: 22),
            tooltip: "Print PDF",
            onPressed: () => _downloadPdf(inv),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: Colors.black87, size: 22),
            tooltip: "Share PDF",
            onPressed: () => _sharePdf(inv),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Status Indicator Header
              _buildStatusHeader(inv),
              const SizedBox(height: 16),

              // 2. Physical Document Sheet
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
                    // Invoice Document Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("INVOICE",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: Colors.black87,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(inv['invoice_number'] ?? "N/A",
                                style: TextStyle(
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
                            Text("Due: $dueDateFormatted",
                                style: TextStyle(
                                    color: Colors.red.shade400,
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
                                inv['customer_name'] ??
                                    inv['customer']?['name'] ??
                                    inv['customer']?['full_name'] ??
                                    "N/A",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87),
                              ),
                              if (inv['customer']?['phone'] != null) ...[
                                const SizedBox(height: 4),
                                Text(inv['customer']?['phone'].toString() ?? "",
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                        if (inv['payment_mode'] != null &&
                            inv['payment_mode'].toString().isNotEmpty)
                          Expanded(
                            child: Column(
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
                                  inv['payment_mode'].toString().toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Table items header
                    Row(
                      children: [
                        Expanded(
                            flex: 5,
                            child: Text("ITEM DESCRIPTION",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text("QTY",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                        Expanded(
                            flex: 2,
                            child: Text("RATE",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right)),
                        Expanded(
                            flex: 3,
                            child: Text("AMOUNT",
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Table items body
                    ...items.map((item) => _buildItemTableRow(item)),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Summary details
                    _buildSummaryCard(inv, primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Invoice Payment Actions
              if (inv['status'] != 'paid')
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showPartialPaymentDialog(context, inv),
                        icon: const Icon(Icons.add_card_rounded,
                            color: Colors.white, size: 18),
                        label: const Text("RECORD PARTIAL PAYMENT",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          shadowColor: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _markAsPaid(inv['id']),
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.green, size: 18),
                        label: const Text("MARK AS FULLY PAID",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Colors.green, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Map<String, dynamic> inv) {
    final String status = inv['status'] ?? 'pending';
    Color color = Colors.orange;
    if (status == 'paid') color = Colors.green;
    if (status == 'overdue') color = Colors.red;
    if (status == 'partially_paid') color = Colors.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            "Status: ${status.toUpperCase().replaceAll('_', ' ')}",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTableRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['description'] ?? "No Description",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['quantity']?.toString() ?? "0",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "₹${_formatPrice(item['unit_price'])}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "₹${_formatPrice(item['amount'])}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> inv, Color primaryColor) {
    final double balance = (inv['total'] ?? 0.0).toDouble() -
        (inv['paid_amount'] ?? 0.0).toDouble();

    return Column(
      children: [
        _buildSummaryRow("Subtotal", "₹${_formatPrice(inv['subtotal'])}"),
        const SizedBox(height: 6),
        _buildSummaryRow(
            "Tax (${inv['tax_percent']?.toInt() ?? ((inv['tax'] ?? 0.0) / (inv['subtotal'] ?? 1.0) * 100).toInt()}%)",
            "₹${_formatPrice(inv['tax'])}"),
        const SizedBox(height: 6),
        _buildSummaryRow("Paid Amount", "₹${_formatPrice(inv['paid_amount'])}"),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Grand Total",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.black87),
            ),
            Text(
              "₹${_formatPrice(inv['total'])}",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: primaryColor),
            ),
          ],
        ),
        if (balance > 0) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Balance Due",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.redAccent),
              ),
              Text(
                "₹${_formatPrice(balance)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87)),
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

  Future<void> _downloadPdf(Map<String, dynamic> inv) async {
    final userId = Get.find<AuthService>().currentUserId;
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

      // 2. Extract Customer Info (if not in inv, fetch it)
      dynamic rawCust = inv['customer'];
      Map<String, dynamic> customer = {};
      if (rawCust is String) {
        try {
          customer = jsonDecode(rawCust);
        } catch (_) {}
      } else if (rawCust is Map) {
        customer = Map<String, dynamic>.from(rawCust);
      }

      if ((customer['name'] == null || customer['name'].toString().isEmpty) &&
          inv['customer_id'] != null) {
        final custResp = await ApiService.get(
            '/business/customers/${inv['customer_id']}',
            headers: {'x-user-id': userId});
        if (custResp.statusCode == 200) {
          customer = jsonDecode(custResp.body);
        }
      }

      Get.back(); // hide loading

      // 3. Generate and Print
      await BusinessPdfHelper.generateAndPrintPdf(
        title: "INVOICE",
        businessProfile: businessProfile,
        customer: customer,
        docData: inv,
        items: inv['items'] ?? [],
        isInvoice: true,
      );
    } catch (e) {
      Get.back();
      Utils.showSnackbar("Error", "PDF Generation failed: $e");
    }
  }

  Future<void> _sharePdf(Map<String, dynamic> inv) async {
    final userId = Get.find<AuthService>().currentUserId;
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
      dynamic rawCust = inv['customer'];
      Map<String, dynamic> customer = {};
      if (rawCust is String) {
        try {
          customer = jsonDecode(rawCust);
        } catch (_) {}
      } else if (rawCust is Map) {
        customer = Map<String, dynamic>.from(rawCust);
      }

      if ((customer['name'] == null || customer['name'].toString().isEmpty) &&
          inv['customer_id'] != null) {
        final custResp = await ApiService.get(
            '/business/customers/${inv['customer_id']}',
            headers: {'x-user-id': userId});
        if (custResp.statusCode == 200) {
          customer = jsonDecode(custResp.body);
        }
      }

      Get.back(); // hide loading

      // 3. Generate and Share
      await BusinessPdfHelper.generateAndSharePdf(
        title: "INVOICE",
        businessProfile: businessProfile,
        customer: customer,
        docData: inv,
        items: inv['items'] ?? [],
        isInvoice: true,
      );
    } catch (e) {
      Get.back();
      Utils.showSnackbar("Error", "PDF Share failed: $e");
    }
  }

  // Helper for the UI call

  Future<void> _markAsPaid(String? invoiceId) async {
    if (invoiceId == null) return;
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      final response = await ApiService.post(
        '/business/invoices/$invoiceId/mark-paid',
        headers: {'x-user-id': userId},
      );

      Get.back(); // hide loading
      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Invoice marked as paid!",
            isError: false);
        if (Get.isRegistered<InvoiceListController>()) {
          Get.find<InvoiceListController>().fetchInvoices();
        }
        Get.back();
      } else {
        Utils.showSnackbar("Error", "Failed: ${response.body}");
      }
    } catch (e) {
      Get.back(); // hide loading
      Utils.showSnackbar("Error", "Exception: $e");
    }
  }

  void _showPartialPaymentDialog(
      BuildContext context, Map<String, dynamic> inv) {
    final tAmount = TextEditingController();
    final tRef = TextEditingController();
    String selectedMethod = "Cash";
    final k = GlobalKey<FormState>();

    double total = (inv['total'] ?? 0.0).toDouble();
    double paid = (inv['paid_amount'] ?? 0.0).toDouble();
    double remaining = total - paid;

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text("Record Payment"),
              content: Form(
                key: k,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Remaining: ₹${remaining.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: tAmount,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
                        double? val = double.tryParse(v);
                        if (val == null) return "Invalid";
                        if (val <= 0) return "Must be > 0";
                        if (val > (remaining + 0.01)) {
                          return "Exceeds remaining";
                        }
                        return null;
                      },
                      decoration: _inputDeco("Amount Paid", Icons.payments),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      decoration:
                          _inputDeco("Method", Icons.account_balance_wallet),
                      items: ["Cash", "UPI", "Bank Transfer"]
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => selectedMethod = v!,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: tRef,
                      decoration:
                          _inputDeco("Reference ID (Optional)", Icons.tag),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Get.back(), child: const Text("CANCEL")),
                ElevatedButton(
                  onPressed: () async {
                    if (!k.currentState!.validate()) return;

                    String? userId = Get.find<AuthService>().currentUserId;
                    if (userId == null) return;

                    Get.dialog(const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false);
                    try {
                      final payload = {
                        "amount": double.parse(tAmount.text),
                        "method": selectedMethod,
                        "reference_id": tRef.text
                      };
                      final response = await ApiService.post(
                          '/business/invoices/${inv['id']}/payments',
                          headers: {
                            'Content-Type': 'application/json',
                            'x-user-id': userId
                          },
                          body: payload);

                      Get.back(); // hide loading
                      if (response.statusCode == 200 ||
                          response.statusCode == 201) {
                        Utils.showSnackbar("Success", "Payment recorded!",
                            isError: false);
                        if (Get.isRegistered<InvoiceListController>()) {
                          Get.find<InvoiceListController>().fetchInvoices();
                        }
                        Get.back(); // close dialog
                        Get.back(); // return to list
                      } else {
                        Utils.showSnackbar("Error", "Failed: ${response.body}");
                      }
                    } catch (e) {
                      Get.back(); // hide loading
                      Utils.showSnackbar("Error", "Exception: $e");
                    }
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  child: const Text("SAVE PAYMENT",
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ));
  }

  Future<void> _deleteInvoice(
      BuildContext context, Map<String, dynamic> inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Invoice",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this invoice?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);

    try {
      if (Get.isRegistered<InvoiceListController>()) {
        final listController = Get.find<InvoiceListController>();
        final int initialCount = listController.invoices.length;
        await listController.deleteInvoice(inv['id'].toString());
        Get.back(); // Hide loading dialog

        final bool isDeleted = listController.invoices.length < initialCount ||
            !listController.invoices
                .any((i) => i['id'].toString() == inv['id'].toString());

        if (isDeleted) {
          Get.back(); // Go back to list view
        }
      } else {
        final String? userId = Get.find<AuthService>().currentUserId;
        if (userId == null) {
          Get.back();
          return;
        }

        final response = await ApiService.delete(
            '/business/invoices/${inv['id']}',
            headers: {'x-user-id': userId});
        Get.back(); // Hide loading

        if (response.statusCode == 200 ||
            response.statusCode == 204 ||
            response.statusCode == 202) {
          final isOffline = response.statusCode == 202;
          Utils.showSnackbar(
              isOffline ? "Offline" : "Success",
              isOffline
                  ? "Invoice deletion scheduled offline. Will sync when online."
                  : "Invoice deleted successfully",
              isError: false);
          Get.back(); // Go back to list view
        } else {
          Utils.showSnackbar(
              "Error", "Failed to delete invoice: ${response.body}");
        }
      }
    } catch (e) {
      Get.back(); // Hide loading
      Utils.showSnackbar("Error", "Failed to delete invoice: $e");
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
