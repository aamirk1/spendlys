import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/features/lend_borrow/data/models/loan_model.dart';
import 'package:spendly/features/income_expense/presentation/cubits/expense_cubit.dart';
import 'package:spendly/features/income_expense/presentation/cubits/income_cubit.dart';
import 'package:spendly/features/lend_borrow/presentation/cubits/loan_cubit.dart';

enum LedgerType { business, loan, expense }

class LedgerState extends Equatable {
  final LedgerType selectedType;
  final String searchQuery;
  final DateTimeRange? dateRange;
  final String selectedQuickFilter;
  final List<dynamic> invoices;
  final Map<String, String> customers;
  final bool isLoading;
  final String? errorMessage;

  const LedgerState({
    this.selectedType = LedgerType.loan,
    this.searchQuery = '',
    this.dateRange,
    this.selectedQuickFilter = 'all',
    this.invoices = const [],
    this.customers = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  LedgerState copyWith({
    LedgerType? selectedType,
    String? searchQuery,
    DateTimeRange? dateRange,
    String? selectedQuickFilter,
    List<dynamic>? invoices,
    Map<String, String>? customers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LedgerState(
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange, // Allows passing null to clear dateRange
      selectedQuickFilter: selectedQuickFilter ?? this.selectedQuickFilter,
      invoices: invoices ?? this.invoices,
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // Getters for filtered items
  List<dynamic> getFilteredBusiness() {
    return invoices.where((inv) {
      if (searchQuery.isEmpty) return true;
      final name = (inv['resolved_customer_name'] ?? '').toString().toLowerCase();
      final id = (inv['invoice_number'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(searchQuery.toLowerCase()) ||
          id.contains(searchQuery.toLowerCase());

      bool matchesDate = true;
      if (dateRange != null && inv['date'] != null) {
        final d = DateTime.parse(inv['date']);
        matchesDate = d.isAfter(dateRange!.start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }
      return matchesSearch && matchesDate;
    }).toList();
  }

  List<Loan> getFilteredLoans(List<Loan> allLoans) {
    List<Loan> all = allLoans.where((l) => l.type == 'borrowed' || l.type == 'lent').toList();
    all.sort((a, b) => b.date.compareTo(a.date));

    if (dateRange != null) {
      all = all.where((l) {
        return l.date.isAfter(dateRange!.start.subtract(const Duration(seconds: 1))) &&
            l.date.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (searchQuery.isEmpty) return all;
    return all.where((l) => l.personName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  List<dynamic> getFilteredExpenses(List<Map<String, dynamic>> allIncomes, List<Map<String, dynamic>> allExpenses) {
    final incomes = allIncomes.map((e) => {...e, 'ledgerType': 'INCOME'}).toList();
    final expenses = allExpenses.map((e) => {...e, 'ledgerType': 'EXPENSE'}).toList();
    List<dynamic> all = [...incomes, ...expenses];
    all.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (dateRange != null) {
      all = all.where((item) {
        final d = item['date'] as DateTime;
        return d.isAfter(dateRange!.start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (searchQuery.isEmpty) return all;
    return all.where((item) {
      final desc = (item['description'] ?? item['category'] ?? "Transaction").toString().toLowerCase();
      return desc.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  List<Object?> get props => [
        selectedType,
        searchQuery,
        dateRange,
        selectedQuickFilter,
        invoices,
        customers,
        isLoading,
        errorMessage,
      ];
}

class LedgerCubit extends Cubit<LedgerState> {
  final AuthService _authService;
  final ExpenseCubit _expenseCubit;
  final IncomeCubit _incomeCubit;
  final LoanCubit _loanCubit;

  LedgerCubit(
    this._authService,
    this._expenseCubit,
    this._incomeCubit,
    this._loanCubit,
  ) : super(const LedgerState()) {
    fetchData();
  }

  void setType(LedgerType type) {
    emit(state.copyWith(selectedType: type));
    fetchData();
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setDateRange(DateTimeRange? range) {
    emit(state.copyWith(dateRange: range, selectedQuickFilter: range == null ? 'all' : 'custom'));
  }

  void applyQuickFilter(String filter) {
    final now = DateTime.now();
    DateTimeRange? range;
    switch (filter) {
      case '1m':
        range = DateTimeRange(
          start: DateTime(now.year, now.month - 1, now.day),
          end: now,
        );
        break;
      case '3m':
        range = DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
        break;
      case '6m':
        range = DateTimeRange(
          start: DateTime(now.year, now.month - 6, now.day),
          end: now,
        );
        break;
      case '1y':
        range = DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
        break;
      case 'all':
      default:
        range = null;
        break;
    }
    emit(state.copyWith(
      selectedQuickFilter: filter,
      dateRange: range,
    ));
  }

  Future<void> fetchData() async {
    emit(state.copyWith(isLoading: true));
    try {
      switch (state.selectedType) {
        case LedgerType.business:
          await _fetchCustomerMap();
          await _fetchInvoices();
          break;
        case LedgerType.loan:
          await _loanCubit.fetchLoans();
          break;
        case LedgerType.expense:
          await _expenseCubit.fetchExpenses();
          await _incomeCubit.fetchIncomes();
          break;
      }
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch data: $e',
      ));
    }
  }

  Future<void> _fetchCustomerMap() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/customers', headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        final List allCust = jsonDecode(response.body);
        final Map<String, String> mapping = {};
        for (var c in allCust) {
          if (c['id'] != null) {
            mapping[c['id'].toString()] = c['name']?.toString() ?? "Unknown";
          }
        }
        emit(state.copyWith(customers: mapping));
      }
    } catch (_) {}
  }

  Future<void> _fetchInvoices() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;
    try {
      final response = await ApiService.get('/business/invoices?page=1&limit=100', headers: {'x-user-id': userId});
      if (response.statusCode == 200) {
        final List rawInvoices = jsonDecode(response.body);
        final resolvedInvoices = rawInvoices.map((inv) {
          final name = getCustomerName(inv);
          return {...inv as Map<String, dynamic>, 'resolved_customer_name': name};
        }).toList();
        emit(state.copyWith(invoices: resolvedInvoices));
      }
    } catch (_) {}
  }

  String getCustomerName(dynamic invoice) {
    if (invoice['customer'] != null && invoice['customer']['name'] != null) {
      return invoice['customer']['name'];
    }
    if (invoice['customer_name'] != null && invoice['customer_name'].toString().isNotEmpty) {
      return invoice['customer_name'];
    }
    final String? custId = invoice['customer_id']?.toString();
    if (custId != null && state.customers.containsKey(custId)) {
      return state.customers[custId]!;
    }
    return "Unknown Customer";
  }
}
