import 'dart:convert';
import 'package:spendly/core/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/utils/utils.dart';
import 'package:uuid/uuid.dart';

class LoanController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var loans = <Loan>[].obs;
  var isLoading = false.obs;
  var errorMsg = Rx<String?>(null);

  @override
  void onInit() {
    fetchLoans();
    super.onInit();
  }

  Future<void> fetchLoans() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final response = await ApiService.get('/loans/?user_id=$userId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
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
      } else {
        errorMsg.value = 'Failed to fetch loans: ${response.body}';
      }
    } catch (e) {
      errorMsg.value = 'Error fetching loans: $e';
    } finally {
      isLoading.value = false;
    }
  }

  List<Loan> get borrowed =>
      loans.where((loan) => loan.type == 'borrowed').toList();
  List<Loan> get lent => loans.where((loan) => loan.type == 'lent').toList();

  double get totalLent =>
      lent.fold(0, (sum, item) => sum + (item.amount - item.paidAmount.value));
  double get totalBorrowed =>
      borrowed.fold(0, (sum, item) => sum + (item.amount - item.paidAmount.value));

  /// Add a new loan
  Future<void> addLoan(Loan loan) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      errorMsg.value = 'User not logged in';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
      return;
    }

    isLoading.value = true;
    try {
      final uuid = const Uuid().v4();
      final response = await ApiService.post('/loans/', body: {
        'id': uuid,
        'user_id': userId,
        'person_name': loan.personName,
        'amount': loan.amount,
        'type': loan.type,
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        Utils.showSnackbar('Success', 'Loan added successfully!',
            isError: false);
        fetchLoans(); // Refresh list
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

      final userId = _auth.currentUser?.uid;
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

      if (response.statusCode == 200) {
        Utils.showSnackbar('Success', 'Payment updated successfully',
            isError: false);
        fetchLoans(); // Refresh list to be sure
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to update payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error updating payment: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    }
  }

  /// Delete loan from Firestore and local list
  Future<void> deleteLoan(String loanId) async {
    try {
      final userId = _auth.currentUser?.uid;
      final response =
          await ApiService.delete('/loans/$loanId?user_id=$userId');
      if (response.statusCode == 200) {
        Utils.showSnackbar('Loan Deleted', 'The loan was removed successfully',
            isError: false);
        fetchLoans(); // Refresh list
      } else {
        Utils.showSnackbar('Error', 'Failed to delete loan: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error deleting loan: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    }
  }

  /// Edit payment
  Future<void> editPayment(
      String loanId, int paymentIndex, double newAmount) async {
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

      final userId = _auth.currentUser?.uid;
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

      if (response.statusCode == 200) {
        Utils.showSnackbar('Success', 'Payment updated successfully',
            isError: false);
        fetchLoans(); // Refresh list
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to update payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error editing payment: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    }
  }

  /// Delete payment
  Future<void> deletePayment(String loanId, int paymentIndex) async {
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

      final userId = _auth.currentUser?.uid;
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

      if (response.statusCode == 200) {
        Utils.showSnackbar('Success', 'Payment deleted successfully',
            isError: false);
        fetchLoans(); // Refresh list
      } else {
        Utils.showSnackbar(
            'Error', 'Failed to delete payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error deleting payment: $e';
      Utils.showSnackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    }
  }
}
