import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';

class IncomeState extends Equatable {
  final List<Map<String, dynamic>> incomeList;
  final Map<String, double> categoryTotals;
  final double totalIncome;
  final List<Map<String, dynamic>> chartData;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;
  final String selectedPaymentMode;

  const IncomeState({
    this.incomeList = const [],
    this.categoryTotals = const {},
    this.totalIncome = 0.0,
    this.chartData = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = '',
    this.selectedPaymentMode = 'Cash',
  });

  IncomeState copyWith({
    List<Map<String, dynamic>>? incomeList,
    Map<String, double>? categoryTotals,
    double? totalIncome,
    List<Map<String, dynamic>>? chartData,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? selectedPaymentMode,
  }) {
    return IncomeState(
      incomeList: incomeList ?? this.incomeList,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      totalIncome: totalIncome ?? this.totalIncome,
      chartData: chartData ?? this.chartData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedPaymentMode: selectedPaymentMode ?? this.selectedPaymentMode,
    );
  }

  @override
  List<Object?> get props => [
        incomeList,
        categoryTotals,
        totalIncome,
        chartData,
        isLoading,
        errorMessage,
        selectedCategory,
        selectedPaymentMode,
      ];
}

class IncomeCubit extends Cubit<IncomeState> {
  final AuthService _authService;

  static const List<Map<String, dynamic>> incomeCategories = [
    {
      'name': 'Salary',
      'icon': CupertinoIcons.money_dollar_circle_fill,
      'color': Color(0xFF4CAF50),
    },
    {
      'name': 'Business',
      'icon': CupertinoIcons.briefcase_fill,
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Gift',
      'icon': CupertinoIcons.gift_fill,
      'color': Color(0xFFE91E63),
    },
    {
      'name': 'Loan',
      'icon': CupertinoIcons.creditcard_fill,
      'color': Color(0xFFFF9800),
    },
    {
      'name': 'Sales',
      'icon': CupertinoIcons.cart_fill,
      'color': Color(0xFF00BCD4),
    },
    {
      'name': 'Investment',
      'icon': CupertinoIcons.chart_bar_alt_fill,
      'color': Color(0xFF673AB7),
    },
    {
      'name': 'Rental Income',
      'icon': CupertinoIcons.house_fill,
      'color': Color(0xFF3F51B5),
    },
    {
      'name': 'Freelance',
      'icon': CupertinoIcons.device_laptop,
      'color': Color(0xFF009688),
    },
    {
      'name': 'Bonus',
      'icon': CupertinoIcons.star_circle_fill,
      'color': Color(0xFFFFC107),
    },
    {
      'name': 'Royalty',
      'icon': CupertinoIcons.music_note_2,
      'color': Color(0xFF9C27B0),
    },
    {
      'name': 'Dividend',
      'icon': CupertinoIcons.arrowtriangle_up_circle_fill,
      'color': Color(0xFF4DB6AC),
    },
    {
      'name': 'Refund',
      'icon': CupertinoIcons.arrow_2_squarepath,
      'color': Color(0xFF607D8B),
    },
    {
      'name': 'Other',
      'icon': CupertinoIcons.question_circle_fill,
      'color': Color(0xFF9E9E9E),
    },
  ];

  static const List<String> paymentModes = [
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'UPI',
    'Other'
  ];

  IncomeCubit(this._authService) : super(const IncomeState()) {
    fetchIncomes();
  }

  void selectCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void selectPaymentMode(String mode) {
    emit(state.copyWith(selectedPaymentMode: mode));
  }

  Future<void> fetchIncomes() async {
    String? userId = _authService.currentUserId;
    if (userId == null) return;

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.get('/transactions/?user_id=$userId&type=income');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> tempIncomes = [];
        Map<String, double> tempTotals = {};
        double total = 0;

        for (var item in data) {
          String category = item['category'] ?? 'Unknown';
          double amount = (item['amount'] as num).toDouble();
          DateTime date = DateTime.parse(item['date']);

          tempTotals[category] = (tempTotals[category] ?? 0) + amount;
          total += amount;

          tempIncomes.add({
            'id': item['id'].toString(),
            'description': item['description'] ?? '',
            'category': category,
            'amount': amount,
            'date': date,
          });
        }

        final Map<String, double> dataMap = {};
        for (var income in tempIncomes) {
          final dateKey = income['date'].toIso8601String().substring(0, 10);
          dataMap[dateKey] = (dataMap[dateKey] ?? 0) + income['amount'];
        }
        final chartDataList = dataMap.entries.map((e) => {'date': e.key, 'amount': e.value}).toList();

        emit(state.copyWith(
          incomeList: tempIncomes,
          categoryTotals: tempTotals,
          totalIncome: total,
          chartData: chartDataList,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch incomes: ${response.body}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred: $e',
      ));
    }
  }

  Future<bool> addIncome({
    required double amount,
    required String description,
    required String category,
    required String paymentMode,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      emit(state.copyWith(errorMessage: 'User not logged in.'));
      return false;
    }

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.post('/transactions/', body: {
        'user_id': userId,
        'amount': amount,
        'description': description.trim(),
        'category': category,
        'type': 'income',
        'payment_mode': paymentMode,
        'date': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(state.copyWith(selectedCategory: ''));
        await fetchIncomes();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add income: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add income: $e',
      ));
      return false;
    }
  }

  Future<bool> updateIncome(String docId, Map<String, dynamic> updatedData) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.put('/transactions/$docId', body: updatedData);
      if (response.statusCode == 200) {
        await fetchIncomes();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update income: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update income: $e',
      ));
      return false;
    }
  }

  Future<void> deleteIncome(String docId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.delete('/transactions/$docId');
      if (response.statusCode == 200) {
        final updatedList = List<Map<String, dynamic>>.from(state.incomeList)
          ..removeWhere((e) => e['id'].toString() == docId);
        emit(state.copyWith(incomeList: updatedList));
        await fetchIncomes();
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to delete income: ${response.body}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete income: $e',
      ));
    }
  }
}
