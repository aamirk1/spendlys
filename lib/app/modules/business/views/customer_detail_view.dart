import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spendly/app/routes/app_pages.dart';
import 'package:spendly/app/modules/business/controllers/customers_controller.dart';
import 'package:spendly/app/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spendly/app/modules/business/controllers/customer_detail_controller.dart';

class CustomerDetailView extends StatelessWidget {
  final Map<String, dynamic> customer;
  const CustomerDetailView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final detailController = Get.put(CustomerDetailController(customer));
    final Color primaryColor = const Color(0xFF5F33E1);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            "Customer Details",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black87, size: 22),
              onPressed: () => Get.toNamed(RoutesName.addCustomer, arguments: Map<String, dynamic>.from(detailController.customer)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => _confirmDeleteCustomer(context, detailController),
            ),
          ],
        ),
        body: Obx(() {
          if (detailController.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final currentCust = detailController.customer;
          final String name = currentCust['name'] ?? 'Unknown';
          final int hash = name.codeUnits.fold(0, (sum, code) => sum + code);
          final List<Color> colorsList = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.red];
          final Color avatarColor = colorsList[hash % colorsList.length];

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 1. Customer profile card
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: avatarColor.withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: avatarColor),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (detailController.totalSalesAmount > 0 || detailController.pendingDuesAmount > 0) 
                                            ? Colors.green.withValues(alpha: 0.1) 
                                            : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (detailController.totalSalesAmount > 0 || detailController.pendingDuesAmount > 0) ? "Active" : "Inactive",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                          color: (detailController.totalSalesAmount > 0 || detailController.pendingDuesAmount > 0) ? Colors.green : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (currentCust['phone'] != null)
                                  Text(
                                    currentCust['phone'],
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                if (currentCust['email'] != null && currentCust['email'].toString().trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    currentCust['email'],
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                                if (currentCust['address'] != null && currentCust['address'].toString().trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          currentCust['address'],
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Action Links (Call, WhatsApp, Email, Share)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _profileActionItem(
                            icon: Icons.phone_rounded,
                            label: "Call",
                            onTap: () => _makePhoneCall(currentCust['phone']),
                          ),
                          _profileActionItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: "WhatsApp",
                            onTap: () => _openWhatsApp(currentCust['phone']),
                          ),
                          _profileActionItem(
                            icon: Icons.mail_outline_rounded,
                            label: "Email",
                            onTap: () => _sendEmail(currentCust['email']),
                          ),
                          _profileActionItem(
                            icon: Icons.share_outlined,
                            label: "Share",
                            onTap: () => _shareDetails(currentCust),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Financial Summary Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        childAspectRatio: 1.6,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatBox(
                            title: "Total Sales",
                            value: "₹${detailController.totalSalesAmount.toStringAsFixed(0)}",
                            icon: Icons.wallet_outlined,
                            color: Colors.indigo,
                          ),
                          _buildStatBox(
                            title: "Pending Dues",
                            value: "₹${detailController.pendingDuesAmount.toStringAsFixed(0)}",
                            icon: Icons.error_outline_rounded,
                            color: detailController.pendingDuesAmount > 0 ? Colors.redAccent : Colors.green,
                          ),
                          _buildStatBox(
                            title: "Total Paid",
                            value: "₹${detailController.totalPaidAmount.toStringAsFixed(0)}",
                            icon: Icons.check_circle_outline_rounded,
                            color: Colors.green,
                          ),
                          _buildStatBox(
                            title: "Transactions",
                            value: "${detailController.invoices.length + detailController.quotations.length}",
                            icon: Icons.history_rounded,
                            color: Colors.amber.shade800,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Activity header & tabs
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      child: const TabBar(
                        indicatorColor: Color(0xFF5F33E1),
                        labelColor: Color(0xFF5F33E1),
                        unselectedLabelColor: Colors.grey,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        tabs: [
                          Tab(text: "Invoices"),
                          Tab(text: "Quotations"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _buildInvoicesList(detailController.invoices, primaryColor),
                _buildQuotationsList(detailController.quotations, primaryColor),
              ],
            ),
          );
        }),
        bottomNavigationBar: Obx(() => _buildBottomActions(detailController.customer, primaryColor)),
      ),
    );
  }

  Widget _profileActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF5F33E1).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF5F33E1), size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(List invoices, Color primaryColor) {
    if (invoices.isEmpty) {
      return _buildEmptyState(Icons.description_outlined, "No Invoices Found", "Create an invoice to bill this customer.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final inv = invoices[index];
        final number = inv['invoice_number'] ?? 'No Code';
        final double total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0.0;
        final double paid = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
        final double due = total - paid;
        final String date = inv['created_at'] != null 
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(inv['created_at'])) 
            : 'Unknown';
        final status = (inv['status'] ?? '').toString().toLowerCase();

        Color statusColor = Colors.orange;
        String statusLabel = 'Pending';
        if (status == 'paid') {
          statusColor = Colors.green;
          statusLabel = 'Paid';
        } else if (status == 'overdue') {
          statusColor = Colors.redAccent;
          statusLabel = 'Overdue';
        } else if (status == 'partially_paid') {
          statusColor = Colors.blue;
          statusLabel = 'Partial';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: statusColor),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(date, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (due > 0)
                      Text("₹${due.toStringAsFixed(0)} Due", style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ],
            ),
            onTap: () => Get.toNamed(RoutesName.viewInvoice, arguments: inv),
          ),
        );
      },
    );
  }

  Widget _buildQuotationsList(List quotations, Color primaryColor) {
    if (quotations.isEmpty) {
      return _buildEmptyState(Icons.request_page_outlined, "No Quotations Found", "Create a quotation to pitch a deal to this customer.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotations.length,
      itemBuilder: (context, index) {
        final q = quotations[index];
        final number = q['quotation_number'] ?? 'No Code';
        final double total = double.tryParse(q['total']?.toString() ?? '0') ?? 0.0;
        final String date = q['created_at'] != null 
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(q['created_at'])) 
            : 'Unknown';
        final status = (q['status'] ?? '').toString().toLowerCase();

        Color statusColor = Colors.orange;
        String statusLabel = 'Pending';
        if (status == 'accepted' || status == 'converted') {
          statusColor = Colors.green;
          statusLabel = 'Accepted';
        } else if (status == 'rejected' || status == 'expired') {
          statusColor = Colors.redAccent;
          statusLabel = 'Rejected';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            title: Row(
              children: [
                Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: statusColor),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(date, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("₹${total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
              ],
            ),
            onTap: () => Get.toNamed(RoutesName.viewQuotation, arguments: q),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade400, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBottomActions(Map<String, dynamic> cust, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(RoutesName.createQuotation, arguments: cust),
              icon: const Icon(Icons.request_page_outlined, size: 16),
              label: const Text("ESTIMATE"),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(RoutesName.createInvoice, arguments: cust),
              icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
              label: const Text("BILL INVOICE", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _confirmDeleteCustomer(BuildContext context, CustomerDetailController detailController) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Customer", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete ${detailController.customer['name']}? This action cannot be undone and will delete their customer profile."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // close dialog
              Get.back(); // close customer detail view
              Get.find<CustomersController>().deleteCustomer(detailController.customer['id'].toString());
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Communications helpers
  void _makePhoneCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      Utils.showSnackbar("No Phone", "This customer does not have a phone number.");
      return;
    }
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Utils.showSnackbar("Error", "Could not place phone call.");
    }
  }

  void _openWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      Utils.showSnackbar("No Phone", "This customer does not have a phone number.");
      return;
    }
    // Format phone to make sure it has country code, default to Indian (+91) if 10 digits
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.length == 10) {
      formattedPhone = "91$formattedPhone";
    }
    final url = Uri.parse("https://wa.me/$formattedPhone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Utils.showSnackbar("Error", "Could not launch WhatsApp.");
    }
  }

  void _sendEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      Utils.showSnackbar("No Email", "This customer does not have an email address.");
      return;
    }
    final url = Uri.parse("mailto:$email");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Utils.showSnackbar("Error", "Could not open email application.");
    }
  }

  void _shareDetails(Map<String, dynamic> cust) {
    final text = "Customer Details:\n"
        "Name: ${cust['name']}\n"
        "${cust['phone'] != null ? 'Phone: ' + cust['phone'] + '\n' : ''}"
        "${cust['email'] != null ? 'Email: ' + cust['email'] + '\n' : ''}"
        "${cust['address'] != null ? 'Address: ' + cust['address'] + '\n' : ''}";
    Share.share(text);
  }
}
