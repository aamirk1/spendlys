import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';

class CategoryState extends Equatable {
  final List<Map<String, dynamic>> categories;
  final IconData selectedIcon;
  final Color selectedColor;
  final bool isLoading;
  final String? errorMessage;

  const CategoryState({
    this.categories = const [],
    this.selectedIcon = Icons.shopping_cart,
    this.selectedColor = const Color(0xFFFFA500),
    this.isLoading = false,
    this.errorMessage,
  });

  CategoryState copyWith({
    List<Map<String, dynamic>>? categories,
    IconData? selectedIcon,
    Color? selectedColor,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      selectedColor: selectedColor ?? this.selectedColor,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        selectedIcon,
        selectedColor,
        isLoading,
        errorMessage,
      ];
}

class CategoryCubit extends Cubit<CategoryState> {
  final AuthService _authService;

  static const List<IconData> availableIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.home,
    Icons.car_repair,
    Icons.flight,
    Icons.medical_services,
    Icons.movie,
    Icons.savings,
    Icons.fitness_center,
    Icons.directions_bus,
    Icons.school,
    Icons.local_grocery_store,
  ];

  CategoryCubit(this._authService) : super(const CategoryState()) {
    fetchCategories();
  }

  void selectIcon(IconData icon) {
    emit(state.copyWith(selectedIcon: icon));
  }

  void selectColor(Color color) {
    emit(state.copyWith(selectedColor: color));
  }

  Future<void> fetchCategories() async {
    String? userId = _authService.currentUserId;
    if (userId == null) return;

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.get('/categories/?user_id=$userId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        emit(state.copyWith(
          categories: data.map((item) => item as Map<String, dynamic>).toList(),
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch categories: ${response.body}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred: $e',
      ));
    }
  }

  Future<bool> addCategory(String categoryName) async {
    String? userId = _authService.currentUserId;
    if (userId == null) {
      emit(state.copyWith(errorMessage: 'User not logged in.'));
      return false;
    }

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.post('/categories/', body: {
        'user_id': userId,
        'name': categoryName.trim(),
        'icon': state.selectedIcon.codePoint,
        'color': state.selectedColor.toARGB32().toRadixString(16),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(state.copyWith(
          selectedIcon: Icons.shopping_cart,
          selectedColor: const Color(0xFFFFA500),
        ));
        await fetchCategories();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add category: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add category: $e',
      ));
      return false;
    }
  }

  Future<bool> editCategory(String categoryId, String categoryName) async {
    String? userId = _authService.currentUserId;
    if (userId == null) {
      emit(state.copyWith(errorMessage: 'User not logged in.'));
      return false;
    }

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.put('/categories/$categoryId', body: {
        'name': categoryName.trim(),
        'icon': state.selectedIcon.codePoint,
        'color': state.selectedColor.toARGB32().toRadixString(16),
      });

      if (response.statusCode == 200) {
        emit(state.copyWith(
          selectedIcon: Icons.shopping_cart,
          selectedColor: const Color(0xFFFFA500),
        ));
        await fetchCategories();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update category: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update category: $e',
      ));
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.delete('/categories/$categoryId');
      if (response.statusCode == 200) {
        await fetchCategories();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to delete category: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete category: $e',
      ));
      return false;
    }
  }
}
