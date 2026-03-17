import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendly/screens/business/invoice_list.dart';
import 'package:spendly/res/routes/routes_name.dart';

class InvoiceDetailView extends StatelessWidget {
  const InvoiceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> inv = Get.arguments;
    final List items = inv['items'] ?? [];
    final String dateFormatted = inv['date'] != null 
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(inv['date']))
        : "N/A";
    final String dueDateFormatted = inv['due_date'] != null 
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(inv['due_date']))
        : "N/A";

    return Scaffold(
      appBar: AppBar(
        title: Text(inv['invoice_number'] ?? "Invoice Detail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.toNamed(RoutesName.editInvoice, arguments: inv),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _downloadPdf(inv['id']),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(inv),
            const SizedBox(height: 20),
            _buildSectionTitle("Invoice Info"),
            _buildInfoCard([
              _buildInfoRow("Number", inv['invoice_number'] ?? "N/A"),
              _buildInfoRow("Date", dateFormatted),
              _buildInfoRow("Due Date", dueDateFormatted),
            ]),
            const SizedBox(height: 20),
            _buildSectionTitle("Items"),
            ...items.map((item) => _buildItemCard(item)).toList(),
            const SizedBox(height: 20),
            _buildSummaryCard(inv),
            const SizedBox(height: 30),
            if (inv['status'] != 'paid')
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPartialPaymentDialog(context, inv),
                      icon: const Icon(Icons.add_card_rounded),
                      label: const Text("RECORD PARTIAL PAYMENT"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsPaid(inv['id']),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("MARK AS FULLY PAID"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green, width: 2),
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Text(
            "Status: ${status.toUpperCase().replaceAll('_', ' ')}",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
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
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
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
        subtitle: Text("Qty: ${item['quantity']} × ₹${item['unit_price']}"),
        trailing: Text(
          "₹${item['amount']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> inv) {
    return Card(
      color: Colors.blueGrey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow("Subtotal", "₹${inv['subtotal']}"),
            _buildInfoRow("Tax", "₹${inv['tax']}"),
            _buildInfoRow("Paid Amount", "₹${inv['paid_amount'] ?? '0.00'}"),
            const Divider(),
            _buildInfoRow("Grand Total", "₹${inv['total']}"),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(String? invoiceId) async {
    if (invoiceId == null) return;
    Utils.showSnackbar("Info", "PDF download feature coming soon", isError: false);
  }

  Future<void> _markAsPaid(String? invoiceId) async {
    if (invoiceId == null) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final response = await ApiService.post(
        '/business/invoices/$invoiceId/mark-paid',
        headers: {'x-user-id': userId},
      );
      
      Get.back(); // hide loading
      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar("Success", "Invoice marked as paid!", isError: false);
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

  void _showPartialPaymentDialog(BuildContext context, Map<String, dynamic> inv) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Record Payment"),
        content: Form(
          key: k,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Remaining: ₹${remaining.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 20),
              TextFormField(
                controller: tAmount,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  double? val = double.tryParse(v);
                  if (val == null) return "Invalid";
                  if (val <= 0) return "Must be > 0";
                  if (val > (remaining + 0.01)) return "Exceeds remaining";
                  return null;
                },
                decoration: _inputDeco("Amount Paid", Icons.payments),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: _inputDeco("Method", Icons.account_balance_wallet),
                items: ["Cash", "UPI", "Bank Transfer"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => selectedMethod = v!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: tRef,
                decoration: _inputDeco("Reference ID (Optional)", Icons.tag),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (!k.currentState!.validate()) return;
              
              String? userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null) return;

              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
              try {
                final payload = {
                  "amount": double.parse(tAmount.text),
                  "method": selectedMethod,
                  "reference_id": tRef.text
                };
                final response = await ApiService.post(
                  '/business/invoices/${inv['id']}/payments',
                  headers: {'Content-Type': 'application/json', 'x-user-id': userId},
                  body: payload
                );
                
                Get.back(); // hide loading
                if (response.statusCode == 200 || response.statusCode == 201) {
                  Utils.showSnackbar("Success", "Payment recorded!", isError: false);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text("SAVE PAYMENT", style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
