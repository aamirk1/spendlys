import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/di/service_locator.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();
  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {}
class ForgotPasswordLoading extends ForgotPasswordState {}
class ForgotPasswordOtpSent extends ForgotPasswordState {}
class ForgotPasswordSuccess extends ForgotPasswordState {}
class ForgotPasswordFailure extends ForgotPasswordState {
  final String errorMessage;
  const ForgotPasswordFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ApiClient _apiClient = getIt<ApiClient>();

  ForgotPasswordCubit() : super(ForgotPasswordInitial());

  Future<void> requestPasswordReset(String phone) async {
    emit(ForgotPasswordLoading());
    try {
      final response = await _apiClient.post(
        ApiConstants.forgotPasswordRequest,
        data: {'phone_number': phone.trim()},
      );

      if (response.statusCode == 200) {
        emit(ForgotPasswordOtpSent());
      } else {
        emit(ForgotPasswordFailure(response.data['detail'] ?? 'Failed to request reset'));
      }
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    emit(ForgotPasswordLoading());
    try {
      final response = await _apiClient.post(
        ApiConstants.forgotPasswordReset,
        data: {
          'phone_number': phone.trim(),
          'otp': otp.trim(),
          'new_password': newPassword.trim(),
        },
      );

      if (response.statusCode == 200) {
        emit(ForgotPasswordSuccess());
      } else {
        emit(ForgotPasswordFailure(response.data['detail'] ?? 'Reset failed'));
      }
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }
}
