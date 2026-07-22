import 'dart:convert';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/core/services/reminder_notification_service.dart';
import 'package:get/get.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/controllers/user_info_controller.dart';
import 'package:spendly/utils/utils.dart';
import 'package:uuid/uuid.dart';

class LoanController extends GetxController {
  var loans = <Loan>[].obs;
  var isLoading = false.obs;
  var errorMsg = Rx<String?>(null);

  @override
  void onInit() {
    fetchLoans();
    super.onInit();
  }

  Future<void> fetchLoans({bool forceRefresh = false}) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    final cacheKey = 'GET_/loans/?user_id=$userId';
    final cachedData = LocalCacheService.getCache(cacheKey);
    if (!forceRefresh && cachedData != null && cachedData is List) {
      _parseAndSetLoans(cachedData);
      return;
    }

    if (cachedData != null && cachedData is List) {
      _parseAndSetLoans(cachedData);
    } else {
      isLoading.value = true;
    }

    try {
      final response = await ApiService.get('/loans/?user_id=$userId');
      if (response.statusCode == 200 || response.statusCode == 202) {
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          _parseAndSetLoans(data);
        }
      } else {
        errorMsg.value = 'Failed to fetch loans: ${response.body}';
      }
    } catch (e) {
      errorMsg.value = 'Error fetching loans: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _parseAndSetLoans(List<dynamic> data) {
    final fetchedLoans = (data).map((item) {
      final map = item as Map<String, dynamic>;
      final id = map['id']?.toString() ?? '';
      return Loan.fromMap(map, id);
    }).toList();

    // Sort by date descending (latest first)
    fetchedLoans.sort((a, b) {
      return b.date.compareTo(a.date);
    });

    loans.value = fetchedLoans;
    errorMsg.value = null;
  }

  List<Loan> get borrowed =>
      loans.where((loan) => loan.type == 'borrowed').toList();
  List<Loan> get lent => loans.where((loan) => loan.type == 'lent').toList();

  double get totalLent =>
      lent.fold(0, (sum, item) => sum + (item.amount - item.paidAmount.value));
  double get totalBorrowed => borrowed.fold(
      0, (sum, item) => sum + (item.amount - item.paidAmount.value));

  /// Update existing loan details
  Future<void> updateLoan(Loan loan) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response =
          await ApiService.put('/loans/${loan.id}?user_id=$userId', body: {
        'person_name': loan.personName,
        'person_phone': loan.personPhone,
        'amount': loan.amount,
        'type': loan.type,
        'payment_mode': loan.paymentMode,
        'reason': loan.reason,
        'expected_return_date': loan.expectedReturnDate?.toIso8601String(),
        'date': loan.date.toIso8601String(),
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
      });

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Success',
            isOffline
                ? 'Loan update saved offline. Will sync when online.'
                : 'Loan updated successfully!',
            isError: false);

        // ── Reschedule notifications ─────────────────
        if (!isOffline && loan.expectedReturnDate != null) {
          try {
            final reminderSvc = Get.find<ReminderNotificationService>();
            await reminderSvc.scheduleLoanNotifications(
              loanId: loan.id,
              personName: loan.personName,
              amount: loan.amount,
              type: loan.type,
              dueDate: loan.expectedReturnDate!,
            );
          } catch (_) {}
        }

        fetchLoans(forceRefresh: true);
        Get.offAllNamed(RoutesName.addLendBorrowView, arguments: {'index': 0});
      } else {
        Utils.showSnackbar('Error', 'Failed to update loan: ${response.body}');
      }
    } catch (e) {
      Utils.showSnackbar('Error', 'Error updating loan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a new loan
  Future<void> addLoan(Loan loan) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) {
      errorMsg.value = 'User not logged in';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
      return;
    }

    isLoading.value = true;
    try {
      final uuid = const Uuid().v4();
      final creatorName = Get.find<UserInfoController>().myUser.value.name;
      final response = await ApiService.post('/loans/', body: {
        'id': uuid,
        'user_id': userId,
        'creator_name': creatorName,
        'person_name': loan.personName,
        'person_phone': loan.personPhone,
        'amount': loan.amount,
        'type': loan.type,
        'payment_mode': loan.paymentMode,
        'reason': loan.reason,
        'expected_return_date': loan.expectedReturnDate?.toIso8601String(),
        'date': DateTime.now().toIso8601String(),
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory
            .map((e) => {
                  'amount': e['amount'],
                  'timestamp': (e['timestamp'] as DateTime).toIso8601String(),
                })
            .toList(),
      });

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Success',
            isOffline
                ? 'Loan added offline. Will sync when online.'
                : 'Loan added successfully!',
            isError: false);
        fetchLoans(forceRefresh: true); // Refresh list
        Get.offAllNamed(RoutesName.homeView, arguments: {'index': 2});

        // ── Local push notification + due-date reminders ─────────────────
        if (!isOffline && loan.expectedReturnDate != null) {
          try {
            final reminderSvc = Get.find<ReminderNotificationService>();
            await reminderSvc.scheduleLoanNotifications(
              loanId: uuid,
              personName: loan.personName,
              amount: loan.amount,
              type: loan.type,
              dueDate: loan.expectedReturnDate!,
            );
          } catch (_) {}
        }
      } else {
        Utils.showSnackbar('Error', 'Failed to add loan: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error adding loan: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update payment status
  Future<void> updatePayment(String loanId, double paymentAmount) async {
    isLoading.value = true;
    try {
      final loan = loans.firstWhere((loan) => loan.id == loanId);

      // Update in-memory values
      loan.paidAmount.value += paymentAmount;

      final paymentRecord = {
        'amount': paymentAmount,
        'timestamp': DateTime.now().toIso8601String(),
      };
      loan.paymentHistory.add(paymentRecord);

      if (loan.paidAmount.value >= loan.amount) {
        loan.status.value = 'paid';
      } else {
        loan.status.value = 'partially paid';
      }

      final userId = Get.find<AuthService>().currentUserId;
      final response =
          await ApiService.put('/loans/$loanId?user_id=$userId', body: {
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory
            .map((e) => {
                  'amount': e['amount'],
                  'timestamp': e['timestamp'] is DateTime
                      ? (e['timestamp'] as DateTime).toIso8601String()
                      : e['timestamp'].toString(),
                })
            .toList(),
      });

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Success',
            isOffline
                ? 'Payment update saved offline. Will sync when online.'
                : 'Payment updated successfully',
            isError: false);
        // If fully paid, cancel all reminders
        if (!isOffline && loan.status.value == 'paid') {
          try {
            final reminderSvc = Get.find<ReminderNotificationService>();
            await reminderSvc.cancelLoanReminders(loanId);
          } catch (_) {}
        }
        fetchLoans(forceRefresh: true); // Refresh list to be sure
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to update payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error updating payment: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete loan from Firestore and local list
  Future<void> deleteLoan(String loanId) async {
    isLoading.value = true;
    try {
      final userId = Get.find<AuthService>().currentUserId;
      final response =
          await ApiService.delete('/loans/$loanId?user_id=$userId');
      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Loan Deleted',
            isOffline
                ? 'Loan deletion scheduled offline. Will sync when online.'
                : 'The loan was removed successfully',
            isError: false);
        // Cancel any scheduled reminders for this loan
        if (!isOffline) {
          try {
            final reminderSvc = Get.find<ReminderNotificationService>();
            await reminderSvc.cancelLoanReminders(loanId);
          } catch (_) {}
        }
        // Immediate local removal for cross-screen reactivity
        loans.removeWhere((l) => l.id == loanId);
        fetchLoans(forceRefresh: true); // Refresh list from server
        Get.offAllNamed(RoutesName.addLendBorrowView, arguments: {'index': 0});
      } else {
        Utils.showSnackbar('Error', 'Failed to delete loan: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error deleting loan: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  /// Edit payment
  Future<void> editPayment(
      String loanId, int paymentIndex, double newAmount) async {
    isLoading.value = true;
    try {
      final loan = loans.firstWhere((loan) => loan.id == loanId);
      final oldAmount = loan.paymentHistory[paymentIndex]['amount'];

      // Update payment history
      loan.paymentHistory[paymentIndex]['amount'] = newAmount;

      // Adjust paid amount
      loan.paidAmount.value = loan.paidAmount.value - oldAmount + newAmount;

      // Update status
      if (loan.paidAmount.value >= loan.amount) {
        loan.status.value = 'paid';
      } else if (loan.paidAmount.value > 0) {
        loan.status.value = 'partially paid';
      } else {
        loan.status.value = 'unpaid';
      }

      final userId = Get.find<AuthService>().currentUserId;
      final response =
          await ApiService.put('/loans/$loanId?user_id=$userId', body: {
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory
            .map((e) => {
                  'amount': e['amount'],
                  'timestamp': e['timestamp'] is DateTime
                      ? (e['timestamp'] as DateTime).toIso8601String()
                      : e['timestamp'].toString(),
                })
            .toList(),
      });

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Success',
            isOffline
                ? 'Payment edit saved offline. Will sync when online.'
                : 'Payment updated successfully',
            isError: false);
        fetchLoans(forceRefresh: true); // Refresh list
        Get.offAllNamed(RoutesName.homeView, arguments: {'index': 2});
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to update payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error editing payment: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete payment
  Future<void> deletePayment(String loanId, int paymentIndex) async {
    isLoading.value = true;
    try {
      final loan = loans.firstWhere((loan) => loan.id == loanId);
      final deletedAmount = loan.paymentHistory[paymentIndex]['amount'];

      // Remove from payment history
      loan.paymentHistory.removeAt(paymentIndex);

      // Update paid amount
      loan.paidAmount.value -= deletedAmount;

      // Update status
      if (loan.paidAmount.value >= loan.amount) {
        loan.status.value = 'paid';
      } else if (loan.paidAmount.value > 0) {
        loan.status.value = 'partially paid';
      } else {
        loan.status.value = 'unpaid';
      }

      final userId = Get.find<AuthService>().currentUserId;
      final response =
          await ApiService.put('/loans/$loanId?user_id=$userId', body: {
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory
            .map((e) => {
                  'amount': e['amount'],
                  'timestamp': e['timestamp'] is DateTime
                      ? (e['timestamp'] as DateTime).toIso8601String()
                      : e['timestamp'].toString(),
                })
            .toList(),
      });

      if (response.statusCode == 200 || response.statusCode == 202) {
        final isOffline = response.statusCode == 202;
        Utils.showSnackbar(
            isOffline ? 'Offline' : 'Success',
            isOffline
                ? 'Payment deletion saved offline. Will sync when online.'
                : 'Payment deleted successfully',
            isError: false);
        fetchLoans(forceRefresh: true); // Refresh list
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to delete payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error deleting payment: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    } finally {
      isLoading.value = false;
    }
  }
}
