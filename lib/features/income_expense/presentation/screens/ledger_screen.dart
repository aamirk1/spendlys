import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:spendly/core/widgets/custom_app_bar.dart';
import 'package:spendly/core/theme/colors.dart';
import 'package:spendly/features/income_expense/data/services/ledger_export_helper.dart';
import 'package:spendly/core/utils/utils.dart';
import 'package:spendly/features/premium/presentation/widgets/premium_dialogs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spendly/features/income_expense/presentation/cubits/ledger_cubit.dart';
import 'package:spendly/features/lend_borrow/presentation/cubits/loan_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/expense_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/income_cubit.dart';
import 'package:spendly/features/premium/presentation/cubits/payment_cubit.dart';

class LedgerScreen extends StatelessWidget {
  final MyUser myUser;

  const LedgerScreen({required this.myUser, super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch data initially on build
    context.read<LedgerCubit>().fetchData();

    return BlocBuilder<LedgerCubit, LedgerState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            backgroundColor: AppColors.primary,
            title: "global_ledger".tr,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                onPressed: () => _showFilterSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                tooltip: "export_pdf".tr,
                onPressed: () => _handleExport(context, state, isPdf: true),
              ),
              IconButton(
                icon: const Icon(Icons.table_view_rounded, color: Colors.white),
                tooltip: "export_excel".tr,
                onPressed: () => _handleExport(context, state, isPdf: false),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildTypeSelector(context, state),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: CupertinoSearchTextField(
                    placeholder: "Search transactions...",
                    onChanged: (v) => context.read<LedgerCubit>().setSearchQuery(v),
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      switch (state.selectedType) {
                        case LedgerType.business:
                          return _buildBusinessLedger(context, state);
                        case LedgerType.loan:
                          return _buildLoanLedger(context, state);
                        case LedgerType.expense:
                          return _buildExpenseLedger(context, state);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector(BuildContext context, LedgerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          _typeButton(context, state, LedgerType.business, "business".tr,
              Icons.business_center),
          _typeButton(context, state, LedgerType.loan, "loans".tr,
              Icons.handshake),
          _typeButton(context, state, LedgerType.expense, "expenses".tr,
              Icons.account_balance_wallet),
        ],
      ),
    );
  }

  Widget _typeButton(BuildContext context, LedgerState state, LedgerType type, String label,
      IconData icon) {
    final isSelected = state.selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => context.read<LedgerCubit>().setType(type),
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
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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

  Widget _buildBusinessLedger(BuildContext context, LedgerState state) {
    final list = state.getFilteredBusiness();
    if (list.isEmpty) return _emptyState("no_business_records".tr, context);
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final inv = list[index];
        return _ledgerCard(
          title: inv['invoice_number'] ?? "INV-???",
          subtitle: inv['resolved_customer_name'] ?? "unknown_customer".tr,
          amount:
              "₹${double.parse((inv['total'] ?? 0).toString()).toStringAsFixed(2)}",
          date: inv['date'],
          status: inv['status'],
          color: Colors.blue,
          context: context,
        );
      },
    );
  }

  Widget _buildLoanLedger(BuildContext context, LedgerState state) {
    final allLoans = state.getFilteredLoans(context.watch<LoanCubit>().state.loans);
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
          amount:
              "₹${loan.amount.toStringAsFixed(2)}",
          date: loan.date.toIso8601String(),
          status: isLent ? "lent_caps".tr : "borrowed_caps".tr,
          color: isLent ? Colors.orange : Colors.deepPurple,
          context: context,
        );
      },
    );
  }

  Widget _buildExpenseLedger(BuildContext context, LedgerState state) {
    final incomeList = context.watch<IncomeCubit>().state.incomeList;
    final expenseList = context.watch<ExpenseCubit>().state.expensesList;
    final all = state.getFilteredExpenses(incomeList, expenseList);

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
          amount:
              "₹${double.parse((item['amount'] ?? 0).toString()).toStringAsFixed(2)}",
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
              color: Colors.black.withValues(alpha: 0.02),
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
                          ?.withValues(alpha: 0.6),
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

  Future<void> _handleExport(BuildContext context, LedgerState ledgerState,
      {required bool isPdf}) async {
    // Premium Check
    final isPremium = context.read<PaymentCubit>().state.isPremium;
    if (!isPremium) {
      PremiumDialogs.showPremiumRequiredDialog();
      return;
    }

    List data = [];
    switch (ledgerState.selectedType) {
      case LedgerType.business:
        data = ledgerState.invoices;
        break;
      case LedgerType.loan:
        final loanState = context.read<LoanCubit>().state;
        data = [
          ...loanState.borrowed,
          ...loanState.lent
        ];
        break;
      case LedgerType.expense:
        final incomeList = context.read<IncomeCubit>().state.incomeList;
        final expenseList = context.read<ExpenseCubit>().state.expensesList;
        final incomes = incomeList
            .map((e) => {...e, 'type': 'INCOME'})
            .toList();
        final expenses = expenseList
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
          type: ledgerState.selectedType,
          data: data,
        );
        Get.back(); // Close dialog before opening print preview
        await LedgerExportHelper.showPrintPreview(
            pdfData, ledgerState.selectedType);
      } else {
        final csvPath = await LedgerExportHelper.generateCsvFile(
          type: ledgerState.selectedType,
          data: data,
        );
        Get.back(); // Close dialog before opening share sheet
        await LedgerExportHelper.showShareSheet(
            csvPath, ledgerState.selectedType);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint(e.toString());
      Utils.showSnackbar("Error", "Export failed: $e");
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<LedgerCubit>()),
        ],
        child: BlocBuilder<LedgerCubit, LedgerState>(
          builder: (context, state) {
            return Padding(
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
                  Text("Quick Date Filters",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickFilterChip(context, state, 'all', 'All Time'),
                      _buildQuickFilterChip(context, state, '1m', '1 Month'),
                      _buildQuickFilterChip(context, state, '3m', '3 Months'),
                      _buildQuickFilterChip(context, state, '6m', '6 Months'),
                      _buildQuickFilterChip(context, state, '1y', '1 Year'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Custom Date Range",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.calendar_month,
                        color: AppColors.primary),
                    title: Text(state.dateRange == null
                        ? "All Time"
                        : "${DateFormat('dd MMM').format(state.dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(state.dateRange!.end)}"),
                    trailing: state.dateRange != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => context.read<LedgerCubit>().applyQuickFilter('all'),
                          )
                        : null,
                    tileColor: AppColors.primary.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2022),
                        lastDate: DateTime.now(),
                        initialDateRange: state.dateRange,
                      );
                      if (picked != null) {
                        if (!context.mounted) return;
                        context.read<LedgerCubit>().setDateRange(picked);
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(
      BuildContext context, LedgerState state, String value, String label) {
    final isSelected = state.selectedQuickFilter == value;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (theme.textTheme.bodyMedium?.color ?? Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: theme.cardColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : theme.dividerColor,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          context.read<LedgerCubit>().applyQuickFilter(value);
        }
      },
    );
  }
}
