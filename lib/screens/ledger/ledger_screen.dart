import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/controllers/ledger_controller.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/components/customAppBar.dart';
import 'package:spendly/utils/colors.dart';
import 'package:spendly/utils/ledger_export_helper.dart';
import 'package:spendly/utils/utils.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/widgets/premium_dialogs.dart';

class LedgerScreen extends StatelessWidget {
  final MyUser myUser;

  const LedgerScreen({required this.myUser, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LedgerController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        backgroundColor: AppColors.primary,
        title: "global_ledger".tr,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () => _showFilterSheet(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: "export_pdf".tr,
            onPressed: () => _handleExport(controller, isPdf: true),
          ),
          IconButton(
            icon: const Icon(Icons.table_view_rounded, color: Colors.white),
            tooltip: "export_excel".tr,
            onPressed: () => _handleExport(controller, isPdf: false),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeSelector(controller, context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: CupertinoSearchTextField(
              placeholder: "Search transactions...",
              onChanged: (v) => controller.searchQuery.value = v,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              switch (controller.selectedType.value) {
                case LedgerType.business:
                  return _buildBusinessLedger(controller, context);
                case LedgerType.loan:
                  return _buildLoanLedger(controller, context);
                case LedgerType.expense:
                  return _buildExpenseLedger(controller, context);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(LedgerController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      color: AppColors.primary.withOpacity(0.05),
      child: Obx(() => Row(
            children: [
              _typeButton(controller, LedgerType.business, "business".tr,
                  Icons.business_center, context),
              _typeButton(controller, LedgerType.loan, "loans".tr,
                  Icons.handshake, context),
              _typeButton(controller, LedgerType.expense, "expenses".tr,
                  Icons.account_balance_wallet, context),
            ],
          )),
    );
  }

  Widget _typeButton(LedgerController controller, LedgerType type, String label,
      IconData icon, BuildContext context) {
    final isSelected = controller.selectedType.value == type;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setType(type),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessLedger(
      LedgerController controller, BuildContext context) {
    final list = controller.filteredBusiness;
    if (list.isEmpty) return _emptyState("no_business_records".tr, context);
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final inv = list[index];
        return _ledgerCard(
          title: inv['invoice_number'] ?? "INV-???",
          subtitle: inv['resolved_customer_name'] ?? "unknown_customer".tr,
          amount: "₹${inv['total']}",
          date: inv['date'],
          status: inv['status'],
          color: Colors.blue,
          context: context,
        );
      },
    );
  }

  Widget _buildLoanLedger(LedgerController controller, BuildContext context) {
    final allLoans = controller.filteredLoans;
    if (allLoans.isEmpty) return _emptyState("no_loan_records".tr, context);

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: allLoans.length,
      itemBuilder: (context, index) {
        final loan = allLoans[index];
        final isLent = loan.type == 'Lent' || loan.type == 'lent';
        return _ledgerCard(
          title: loan.personName,
          subtitle: isLent ? "lent_money_msg".tr : "borrowed_money_msg".tr,
          amount: "₹${loan.amount}",
          date: loan.date.toIso8601String(),
          status: isLent ? "lent_caps".tr : "borrowed_caps".tr,
          color: isLent ? Colors.orange : Colors.deepPurple,
          context: context,
        );
      },
    );
  }

  Widget _buildExpenseLedger(
      LedgerController controller, BuildContext context) {
    final all = controller.filteredExpenses;

    if (all.isEmpty) return _emptyState("no_transaction_records".tr, context);

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: all.length,
      itemBuilder: (context, index) {
        final item = all[index];
        final isIncome = item['ledgerType'] == 'INCOME';
        return _ledgerCard(
          title: item['description'] ?? item['category'] ?? "Transaction",
          subtitle: item['category'] ?? "",
          amount: "₹${item['amount']}",
          date: item['date'].toString(),
          status: isIncome ? "income_caps".tr : "expense_caps".tr,
          color: isIncome ? Colors.green : Colors.red,
          context: context,
        );
      },
    );
  }

  Widget _ledgerCard(
      {required String title,
      required String subtitle,
      required String amount,
      String? date,
      String? status,
      required Color color,
      required BuildContext context}) {
    String formattedDate = "N/A";
    if (date != null) {
      try {
        formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(date));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                Text(subtitle,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              Text(formattedDate,
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(message,
              style: TextStyle(color: Theme.of(context).disabledColor)),
        ],
      ),
    );
  }

  Future<void> _handleExport(LedgerController controller,
      {required bool isPdf}) async {
    // Premium Check
    final paymentController = Get.put(PaymentController());
    if (!paymentController.isPremium.value) {
      PremiumDialogs.showPremiumRequiredDialog();
      return;
    }

    List data = [];
    switch (controller.selectedType.value) {
      case LedgerType.business:
        data = controller.invoices;
        break;
      case LedgerType.loan:
        data = [
          ...controller.loanController.borrowed,
          ...controller.loanController.lent
        ];
        break;
      case LedgerType.expense:
        final incomes = controller.incomeController.incomeList
            .map((e) => {...e, 'type': 'INCOME'})
            .toList();
        final expenses = controller.expenseController.expensesList
            .map((e) => {...e, 'type': 'EXPENSE'})
            .toList();
        data = [...incomes, ...expenses];
        data.sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        break;
    }

    if (data.isEmpty) {
      Utils.showSnackbar(
          "Export Failed", "No data available to export for this ledger.");
      return;
    }

    // Show loading dialog only during data processing phase
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      if (isPdf) {
        final pdfData = await LedgerExportHelper.generatePdfData(
          type: controller.selectedType.value,
          data: data,
        );
        Get.back(); // Close dialog before opening print preview
        await LedgerExportHelper.showPrintPreview(
            pdfData, controller.selectedType.value);
      } else {
        final csvPath = await LedgerExportHelper.generateCsvFile(
          type: controller.selectedType.value,
          data: data,
        );
        Get.back(); // Close dialog before opening share sheet
        await LedgerExportHelper.showShareSheet(
            csvPath, controller.selectedType.value);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print(e);
      Utils.showSnackbar("Error", "Export failed: $e");
    }
  }

  void _showFilterSheet(BuildContext context, LedgerController controller) {
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
            Text("Global Filters",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color)),
            const SizedBox(height: 20),
            Text("Filter by Date Range",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 10),
            Obx(() => ListTile(
                  leading: const Icon(Icons.calendar_month,
                      color: AppColors.primary),
                  title: Text(controller.dateRange.value == null
                      ? "All Time"
                      : "${DateFormat('dd MMM').format(controller.dateRange.value!.start)} - ${DateFormat('dd MMM yyyy').format(controller.dateRange.value!.end)}"),
                  trailing: controller.dateRange.value != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => controller.dateRange.value = null,
                        )
                      : null,
                  tileColor: AppColors.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now(),
                      initialDateRange: controller.dateRange.value,
                    );
                    if (picked != null) {
                      controller.dateRange.value = picked;
                    }
                  },
                )),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("APPLY FILTERS",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
