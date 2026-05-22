import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';

class ExpenseState extends Equatable {
  final List<Map<String, dynamic>> expensesList;
  final Map<String, double> categoryTotals;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;
  final String selectedPaymentMode;

  const ExpenseState({
    this.expensesList = const [],
    this.categoryTotals = const {},
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = '',
    this.selectedPaymentMode = 'Cash',
  });

  ExpenseState copyWith({
    List<Map<String, dynamic>>? expensesList,
    Map<String, double>? categoryTotals,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? selectedPaymentMode,
  }) {
    return ExpenseState(
      expensesList: expensesList ?? this.expensesList,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedPaymentMode: selectedPaymentMode ?? this.selectedPaymentMode,
    );
  }

  @override
  List<Object?> get props => [
        expensesList,
        categoryTotals,
        isLoading,
        errorMessage,
        selectedCategory,
        selectedPaymentMode,
      ];
}

class ExpenseCubit extends Cubit<ExpenseState> {
  final AuthService _authService;

  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Color(0xFFFFA500)},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Color(0xFF0000FF)},
    {'name': 'Travel', 'icon': Icons.airplanemode_active, 'color': Color(0xFF008080)},
    {'name': 'Groceries', 'icon': Icons.shopping_cart, 'color': Color(0xFF00FF00)},
    {'name': 'Bills', 'icon': Icons.receipt, 'color': Color(0xFFFFC0CB)},
    {'name': 'Rent', 'icon': Icons.home, 'color': Color(0xFFFFD700)},
    {'name': 'Utilities', 'icon': Icons.lightbulb, 'color': Color(0xFF808080)},
    {'name': 'Insurance', 'icon': Icons.security, 'color': Color(0xFF800000)},
    {'name': 'Subscriptions', 'icon': Icons.subscriptions, 'color': Color(0xFF000080)},
    {'name': 'Gifts', 'icon': Icons.card_giftcard, 'color': Color(0xFFFF69B4)},
    {'name': 'Entertainment', 'icon': Icons.videogame_asset, 'color': Color(0xFF00FFFF)},
    {'name': 'Dining Out', 'icon': Icons.restaurant, 'color': Color(0xFFADFF2F)},
    {'name': 'Clothing', 'icon': Icons.checkroom, 'color': Color(0xFFFF4500)},
    {'name': 'Hobbies', 'icon': Icons.sports_baseball, 'color': Color(0xFF8A2BE2)},
    {'name': 'Pets', 'icon': Icons.pets, 'color': Color(0xFF7FFF00)},
    {'name': 'Home Improvement', 'icon': Icons.build, 'color': Color(0xFFB22222)},
    {'name': 'Personal Care', 'icon': Icons.face, 'color': Color(0xFFDAA520)},
    {'name': 'Fitness', 'icon': Icons.fitness_center, 'color': Color(0xFF32CD32)},
    {'name': 'Childcare', 'icon': Icons.child_care, 'color': Color(0xFF4169E1)},
    {'name': 'Charity', 'icon': Icons.favorite, 'color': Color(0xFFFF6347)},
    {'name': 'Medical', 'icon': Icons.local_hospital, 'color': Color(0xFF8B0000)},
    {'name': 'Miscellaneous', 'icon': Icons.category, 'color': Color(0xFF808000)},
    {'name': 'Electronics', 'icon': Icons.electrical_services, 'color': Color(0xFF7B68EE)},
    {'name': 'Sports', 'icon': Icons.sports, 'color': Color(0xFF4682B4)},
    {'name': 'Beauty', 'icon': Icons.brush, 'color': Color(0xFFFF1493)},
    {'name': 'Books', 'icon': Icons.book, 'color': Color(0xFF8B4513)},
    {'name': 'Gardening', 'icon': Icons.grass, 'color': Color(0xFF228B22)},
    {'name': 'Photography', 'icon': Icons.camera_alt, 'color': Color(0xFFDC143C)},
    {'name': 'Music', 'icon': Icons.music_note, 'color': Color(0xFF00FA9A)},
    {'name': 'Events', 'icon': Icons.event, 'color': Color(0xFFB8860B)},
    {'name': 'Streaming', 'icon': Icons.tv, 'color': Color(0xFFADFF2F)},
    {'name': 'Social', 'icon': Icons.people, 'color': Color(0xFF6495ED)},
    {'name': 'Dining', 'icon': Icons.restaurant_menu, 'color': Color(0xFFB22222)},
    {'name': 'Wellness', 'icon': Icons.self_improvement, 'color': Color(0xFF8B0000)},
    {'name': 'Home', 'icon': Icons.home_work, 'color': Color(0xFF8B4513)},
    {'name': 'Family', 'icon': Icons.family_restroom, 'color': Color(0xFF228B22)},
    {'name': 'Friends', 'icon': Icons.group, 'color': Color(0xFFDC143C)},
    {'name': 'Work', 'icon': Icons.work, 'color': Color(0xFF00FA9A)},
    {'name': 'Shopping', 'icon': Icons.local_mall, 'color': Color(0xFF008000)},
    {'name': 'Health', 'icon': Icons.medical_services, 'color': Color(0xFFFF0000)},
    {'name': 'Education', 'icon': Icons.school, 'color': Color(0xFF008080)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF808080)},
  ];

  static const List<String> paymentModes = [
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'UPI',
    'Other'
  ];

  ExpenseCubit(this._authService) : super(const ExpenseState()) {
    fetchExpenses();
  }

  void selectCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void selectPaymentMode(String mode) {
    emit(state.copyWith(selectedPaymentMode: mode));
  }

  Future<void> fetchExpenses() async {
    String? userId = _authService.currentUserId;
    if (userId == null) return;

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.get('/transactions/?user_id=$userId&type=expense');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        Map<String, double> tempTotals = {};
        List<Map<String, dynamic>> tempExpenses = [];

        for (var item in data) {
          String category = item['category'] ?? "Unknown";
          double amount = (item['amount'] as num).toDouble();
          DateTime date = DateTime.parse(item['date']);

          tempTotals[category] = (tempTotals[category] ?? 0) + amount;

          tempExpenses.add({
            'id': item['id'].toString(),
            'description': item['description'] ?? "",
            'category': category,
            'amount': amount,
            'date': date,
          });
        }

        emit(state.copyWith(
          expensesList: tempExpenses,
          categoryTotals: tempTotals,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch expenses: ${response.body}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred: $e',
      ));
    }
  }

  Future<bool> addExpense({
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
        'type': 'expense',
        'payment_mode': paymentMode,
        'date': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(state.copyWith(selectedCategory: ''));
        await fetchExpenses();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add expense: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add expense: $e',
      ));
      return false;
    }
  }

  Future<bool> updateExpense(String docId, Map<String, dynamic> updatedData) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.put('/transactions/$docId', body: updatedData);
      if (response.statusCode == 200) {
        await fetchExpenses();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update expense: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update expense: $e',
      ));
      return false;
    }
  }

  Future<void> deleteExpense(String docId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.delete('/transactions/$docId');
      if (response.statusCode == 200) {
        // Immediate local removal
        final updatedList = List<Map<String, dynamic>>.from(state.expensesList)
          ..removeWhere((e) => e['id'].toString() == docId);
        emit(state.copyWith(expensesList: updatedList));
        await fetchExpenses();
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to delete expense: ${response.body}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete expense: $e',
      ));
    }
  }
}
