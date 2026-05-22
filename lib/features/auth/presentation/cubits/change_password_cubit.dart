import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/core/network/api_client.dart';
import 'package:spendly/core/network/api_constants.dart';
import 'package:spendly/core/di/service_locator.dart';

abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();
  @override
  List<Object?> get props => [];
}

class ChangePasswordInitial extends ChangePasswordState {}
class ChangePasswordLoading extends ChangePasswordState {}
class ChangePasswordSuccess extends ChangePasswordState {}
class ChangePasswordFailure extends ChangePasswordState {
  final String errorMessage;
  const ChangePasswordFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ApiClient _apiClient = getIt<ApiClient>();

  ChangePasswordCubit() : super(ChangePasswordInitial());

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    emit(ChangePasswordLoading());
    try {
      final response = await _apiClient.post(
        ApiConstants.changePassword,
        data: {
          'old_password': oldPassword.trim(),
          'new_password': newPassword.trim(),
        },
      );

      if (response.statusCode == 200) {
        emit(ChangePasswordSuccess());
      } else {
        emit(ChangePasswordFailure(response.data['detail'] ?? 'Password change failed'));
      }
    } catch (e) {
      emit(ChangePasswordFailure(e.toString()));
    }
  }
}
