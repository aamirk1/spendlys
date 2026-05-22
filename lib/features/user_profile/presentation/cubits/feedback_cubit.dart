import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';

class FeedbackState extends Equatable {
  final int rating;
  final String category;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const FeedbackState({
    this.rating = 5,
    this.category = 'General',
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  FeedbackState copyWith({
    int? rating,
    String? category,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return FeedbackState(
      rating: rating ?? this.rating,
      category: category ?? this.category,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [rating, category, isLoading, errorMessage, isSuccess];
}

class FeedbackCubit extends Cubit<FeedbackState> {
  final AuthService _authService;
  final ApiClient _apiClient;

  FeedbackCubit(this._authService, this._apiClient) : super(const FeedbackState());

  void setRating(int value) {
    emit(state.copyWith(rating: value));
  }

  void setCategory(String value) {
    emit(state.copyWith(category: value));
  }

  Future<bool> submitFeedback(String message) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please enter your feedback message'));
      return false;
    }

    final userId = _authService.currentUserId;
    if (userId == null || userId.isEmpty) {
      emit(state.copyWith(errorMessage: 'User ID not found. Please log in again.'));
      return false;
    }

    emit(state.copyWith(isLoading: true, isSuccess: false));
    try {
      await _apiClient.post(ApiConstants.feedback, data: {
        'user_id': userId,
        'rating': state.rating,
        'category': state.category,
        'message': cleanMessage,
      });

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        rating: 5,
        category: 'General',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit feedback: $e',
      ));
      return false;
    }
  }
}
