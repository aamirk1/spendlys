import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:spendly/features/lend_borrow/data/models/loan_model.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/reminder_notification_service.dart';
import 'package:spendly/core/di/service_locator.dart';
import 'package:uuid/uuid.dart';

class LoanState extends Equatable {
  final List<Loan> loans;
  final bool isLoading;
  final String? errorMessage;

  const LoanState({
    this.loans = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<Loan> get borrowed => loans.where((loan) => loan.type == 'borrowed').toList();
  List<Loan> get lent => loans.where((loan) => loan.type == 'lent').toList();

  double get totalLent => lent.fold(0.0, (sum, item) => sum + (item.amount - item.paidAmount));
  double get totalBorrowed => borrowed.fold(0.0, (sum, item) => sum + (item.amount - item.paidAmount));

  LoanState copyWith({
    List<Loan>? loans,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoanState(
      loans: loans ?? this.loans,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [loans, isLoading, errorMessage];
}

class LoanCubit extends Cubit<LoanState> {
  final AuthService _authService;

  LoanCubit(this._authService) : super(const LoanState()) {
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.get('/loans/?user_id=$userId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final fetchedLoans = data.map((item) {
          final map = item as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          return Loan.fromMap(map, id);
        }).toList();

        fetchedLoans.sort((a, b) => b.date.compareTo(a.date));

        emit(state.copyWith(
          loans: fetchedLoans,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch loans: ${response.body}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching loans: $e',
      ));
    }
  }

  Future<bool> addLoan({
    required String personName,
    required String? personPhone,
    required double amount,
    required String type,
    required String? paymentMode,
    required String? reason,
    required DateTime? expectedReturnDate,
    required String? creatorName,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      emit(state.copyWith(errorMessage: 'User not logged in'));
      return false;
    }

    emit(state.copyWith(isLoading: true));
    try {
      final uuid = const Uuid().v4();
      final body = {
        'id': uuid,
        'user_id': userId,
        'creator_name': creatorName ?? 'Unknown',
        'person_name': personName,
        'person_phone': personPhone,
        'amount': amount,
        'type': type,
        'payment_mode': paymentMode,
        'reason': reason,
        'expected_return_date': expectedReturnDate?.toIso8601String(),
        'date': DateTime.now().toIso8601String(),
        'paid_amount': 0.0,
        'status': 'pending',
        'payment_history': [],
      };

      final response = await ApiService.post('/loans/', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Schedule reminder if expectedReturnDate exists
        if (expectedReturnDate != null) {
          try {
            final reminderSvc = getIt<ReminderNotificationService>();
            await reminderSvc.scheduleLoanNotifications(
              loanId: uuid,
              personName: personName,
              amount: amount,
              type: type,
              dueDate: expectedReturnDate,
            );
          } catch (_) {}
        }

        await fetchLoans();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to add loan: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error adding loan: $e',
      ));
      return false;
    }
  }

  Future<bool> updateLoan(Loan loan) async {
    final userId = _authService.currentUserId;
    if (userId == null) return false;

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.put('/loans/${loan.id}?user_id=$userId', body: {
        'person_name': loan.personName,
        'person_phone': loan.personPhone,
        'amount': loan.amount,
        'type': loan.type,
        'payment_mode': loan.paymentMode,
        'reason': loan.reason,
        'expected_return_date': loan.expectedReturnDate?.toIso8601String(),
        'date': loan.date.toIso8601String(),
        'paid_amount': loan.paidAmount,
        'status': loan.status,
      });

      if (response.statusCode == 200) {
        if (loan.expectedReturnDate != null) {
          try {
            final reminderSvc = getIt<ReminderNotificationService>();
            await reminderSvc.scheduleLoanNotifications(
              loanId: loan.id,
              personName: loan.personName,
              amount: loan.amount,
              type: loan.type,
              dueDate: loan.expectedReturnDate!,
            );
          } catch (_) {}
        }
        await fetchLoans();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update loan: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error updating loan: $e',
      ));
      return false;
    }
  }

  Future<bool> updatePayment(String loanId, double paymentAmount) async {
    emit(state.copyWith(isLoading: true));
    try {
      final loan = state.loans.firstWhere((loan) => loan.id == loanId);
      final newPaidAmount = loan.paidAmount + paymentAmount;
      final newStatus = newPaidAmount >= loan.amount ? 'paid' : 'partially paid';

      final paymentRecord = {
        'amount': paymentAmount,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final newPaymentHistory = List<Map<String, dynamic>>.from(loan.paymentHistory)..add(paymentRecord);

      final userId = _authService.currentUserId;
      final response = await ApiService.put('/loans/$loanId?user_id=$userId', body: {
        'paid_amount': newPaidAmount,
        'status': newStatus,
        'payment_history': newPaymentHistory,
      });

      if (response.statusCode == 200) {
        if (newStatus == 'paid') {
          try {
            final reminderSvc = getIt<ReminderNotificationService>();
            await reminderSvc.cancelLoanReminders(loanId);
          } catch (_) {}
        }
        await fetchLoans();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update payment: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error updating payment: $e',
      ));
      return false;
    }
  }

  Future<bool> editPayment(String loanId, int paymentIndex, double newAmount) async {
    emit(state.copyWith(isLoading: true));
    try {
      final loan = state.loans.firstWhere((loan) => loan.id == loanId);
      final oldAmount = loan.paymentHistory[paymentIndex]['amount'];
      final newPaidAmount = loan.paidAmount - oldAmount + newAmount;

      final newStatus = newPaidAmount >= loan.amount
          ? 'paid'
          : (newPaidAmount > 0 ? 'partially paid' : 'unpaid');

      final newPaymentHistory = List<Map<String, dynamic>>.from(loan.paymentHistory);
      newPaymentHistory[paymentIndex] = {
        'amount': newAmount,
        'timestamp': newPaymentHistory[paymentIndex]['timestamp'],
      };

      final userId = _authService.currentUserId;
      final response = await ApiService.put('/loans/$loanId?user_id=$userId', body: {
        'paid_amount': newPaidAmount,
        'status': newStatus,
        'payment_history': newPaymentHistory,
      });

      if (response.statusCode == 200) {
        await fetchLoans();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update payment: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error editing payment: $e',
      ));
      return false;
    }
  }

  Future<bool> deletePayment(String loanId, int paymentIndex) async {
    emit(state.copyWith(isLoading: true));
    try {
      final loan = state.loans.firstWhere((loan) => loan.id == loanId);
      final deletedAmount = loan.paymentHistory[paymentIndex]['amount'];
      final newPaidAmount = loan.paidAmount - deletedAmount;

      final newStatus = newPaidAmount >= loan.amount
          ? 'paid'
          : (newPaidAmount > 0 ? 'partially paid' : 'unpaid');

      final newPaymentHistory = List<Map<String, dynamic>>.from(loan.paymentHistory)..removeAt(paymentIndex);

      final userId = _authService.currentUserId;
      final response = await ApiService.put('/loans/$loanId?user_id=$userId', body: {
        'paid_amount': newPaidAmount,
        'status': newStatus,
        'payment_history': newPaymentHistory,
      });

      if (response.statusCode == 200) {
        await fetchLoans();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to delete payment: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error deleting payment: $e',
      ));
      return false;
    }
  }

  Future<bool> deleteLoan(String loanId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final userId = _authService.currentUserId;
      final response = await ApiService.delete('/loans/$loanId?user_id=$userId');
      if (response.statusCode == 200) {
        try {
          final reminderSvc = getIt<ReminderNotificationService>();
          await reminderSvc.cancelLoanReminders(loanId);
        } catch (_) {}
        await fetchLoans();
        return true;
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to delete loan: ${response.body}',
        ));
        return false;
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error deleting loan: $e',
      ));
      return false;
    }
  }
}
