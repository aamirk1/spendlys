// ignore_for_file: empty_catches

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:spendly/screens/add_lend_borrow/loan_modal.dart';

// class LoanController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Form controllers
//   final amountController = TextEditingController();
//   final descriptionController = TextEditingController();
//   final personController = TextEditingController();
//   final formKey = GlobalKey<FormState>();

//   // Reactive variables
//   var loans = <Loan>[].obs;
//   var isLoading = false.obs;
//   var errorMsg = Rx<String?>(null);

//   StreamSubscription? _loanSubscription;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchLoans();
//   }

//   /// Start listening to loan changes in real-time

//   /// Manually fetch loans
//   Future<void> fetchLoans() async {
//     final userId = _auth.currentUser?.uid;
//     if (userId == null) {
//       errorMsg.value = 'User not logged in';
//       Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
//       return;
//     }

//     isLoading.value = true;
//     try {
//       final querySnapshot = await _firestore
//           .collection('loans')
//           .where('userId', isEqualTo: userId)
//           .orderBy('date', descending: true)
//           .get();

//       List<Loan> tempLoans = [];

//       for (var doc in querySnapshot.docs) {
//         final loan = Loan.fromMap(doc.data(), doc.id);
//         tempLoans.add(loan);
//       }

//       loans.assignAll(tempLoans);
//       errorMsg.value = null;
//     } catch (e) {
//       errorMsg.value = 'Error fetching loans: $e';
//       Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Getter for borrowed loans
//   List<Loan> get borrowed => loans.where((l) => l.type == 'borrowed').toList();

//   /// Getter for lent loans
//   List<Loan> get lent => loans.where((l) => l.type == 'lent').toList();

//   /// Add a new loan
//   Future<void> addLoan(Loan loan) async {
//     final userId = _auth.currentUser?.uid;
//     if (userId == null) {
//       errorMsg.value = 'User not logged in';
//       Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
//       return;
//     }

//     isLoading.value = true;
//     try {
//       final data = loan.toMap();
//       data['userId'] = userId;
//       data['date'] = Timestamp.now();

//       final docRef = await _firestore.collection('loans').add(data);
//       await docRef.update({'id': docRef.id});

//       Get.snackbar(
//         'Success',
//         'Loan added successfully',
//         backgroundColor: Colors.green[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.check_circle, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );

//       // Clear form
//       amountController.clear();
//       descriptionController.clear();
//       personController.clear();
//     } catch (e) {
//       errorMsg.value = 'Error adding loan: $e';
//       Get.snackbar(
//         'Error',
//         errorMsg.value ?? 'Unknown error occurred',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.error_outline, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Update payment status
//   Future<void> updatePayment(String loanId, double paymentAmount) async {
//     isLoading.value = true;
//     try {
//       final loanDoc = _firestore.collection('loans').doc(loanId);
//       final loan = loans.firstWhere((loan) => loan.id == loanId);

//       // Update in-memory values
//       loan.paidAmount.value += paymentAmount;

//       final paymentRecord = {
//         'amount': paymentAmount,
//         'date': DateTime.now().toIso8601String(),
//       };
//       loan.paymentHistory.add(paymentRecord);

//       if (loan.paidAmount.value >= loan.amount) {
//         loan.status.value = 'paid';
//       } else {
//         loan.status.value = 'partially paid';
//       }

//       loans.refresh();

//       // Sync to Firestore
//       await loanDoc.update({
//         'paidAmount': loan.paidAmount.value,
//         'status': loan.status.value,
//         'paymentHistory': FieldValue.arrayUnion([paymentRecord]),
//       });

//       Get.snackbar(
//         'Success',
//         'Payment updated successfully',
//         backgroundColor: Colors.green[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.check_circle, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } catch (e) {
//       errorMsg.value = 'Error updating payment: $e';
//       Get.snackbar(
//         'Error',
//         errorMsg.value ?? 'Unknown error occurred',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.error_outline, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Delete loan
//   Future<void> deleteLoan(String loanId) async {
//     isLoading.value = true;
//     try {
//       await _firestore.collection('loans').doc(loanId).delete();
//       Get.snackbar(
//         'Loan Deleted',
//         'The loan was removed successfully',
//         backgroundColor: Colors.green[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.check_circle, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } catch (e) {
//       errorMsg.value = 'Error deleting loan: $e';
//       Get.snackbar(
//         'Error',
//         errorMsg.value ?? 'Unknown error occurred',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.error_outline, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Edit payment
//   Future<void> editPayment(
//       String loanId, int paymentIndex, double newAmount) async {
//     isLoading.value = true;
//     try {
//       final loan = loans.firstWhere((loan) => loan.id == loanId);
//       final oldAmount = loan.paymentHistory[paymentIndex]['amount'];

//       // Update payment history
//       loan.paymentHistory[paymentIndex]['amount'] = newAmount;

//       // Adjust paid amount
//       loan.paidAmount.value = loan.paidAmount.value - oldAmount + newAmount;

//       // Update status
//       if (loan.paidAmount.value >= loan.amount) {
//         loan.status.value = 'paid';
//       } else if (loan.paidAmount.value > 0) {
//         loan.status.value = 'partially paid';
//       } else {
//         loan.status.value = 'unpaid';
//       }

//       // Sync to Firestore
//       await _firestore.collection('loans').doc(loanId).update({
//         'paidAmount': loan.paidAmount.value,
//         'status': loan.status.value,
//         'paymentHistory': loan.paymentHistory,
//       });

//       loans.refresh();
//       Get.snackbar(
//         'Success',
//         'Payment updated successfully',
//         backgroundColor: Colors.green[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.check_circle, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } catch (e) {
//       errorMsg.value = 'Error editing payment: $e';
//       Get.snackbar(
//         'Error',
//         errorMsg.value ?? 'Unknown error occurred',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.error_outline, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Delete payment
//   Future<void> deletePayment(String loanId, int paymentIndex) async {
//     isLoading.value = true;
//     try {
//       final loan = loans.firstWhere((loan) => loan.id == loanId);
//       final deletedAmount = loan.paymentHistory[paymentIndex]['amount'];

//       // Remove from payment history
//       loan.paymentHistory.removeAt(paymentIndex);

//       // Update paid amount
//       loan.paidAmount.value -= deletedAmount;

//       // Update status
//       if (loan.paidAmount.value >= loan.amount) {
//         loan.status.value = 'paid';
//       } else if (loan.paidAmount.value > 0) {
//         loan.status.value = 'partially paid';
//       } else {
//         loan.status.value = 'unpaid';
//       }

//       // Sync to Firestore
//       await _firestore.collection('loans').doc(loanId).update({
//         'paidAmount': loan.paidAmount.value,
//         'status': loan.status.value,
//         'paymentHistory': loan.paymentHistory,
//       });

//       loans.refresh();
//       Get.snackbar(
//         'Success',
//         'Payment deleted successfully',
//         backgroundColor: Colors.green[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.check_circle, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } catch (e) {
//       errorMsg.value = 'Error deleting payment: $e';
//       Get.snackbar(
//         'Error',
//         errorMsg.value ?? 'Unknown error occurred',
//         backgroundColor: Colors.red[600],
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         margin: EdgeInsets.all(12),
//         borderRadius: 12,
//         icon: const Icon(Icons.error_outline, color: Colors.white),
//         duration: const Duration(seconds: 2),
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   @override
//   void onClose() {
//     _loanSubscription?.cancel();
//     amountController.dispose();
//     descriptionController.dispose();
//     personController.dispose();
//     super.onClose();
//   }
// }
// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:spendly/core/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/utils/colors.dart';


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
        final fetchedLoans = data
            .map((item) => Loan.fromMap(item as Map<String, dynamic>, item['id'].toString()))
            .toList();

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

  /// Add a new loan
  Future<void> addLoan(Loan loan) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      errorMsg.value = 'User not logged in';
      Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.post('/loans/', body: {
        'user_id': userId,
        'person_name': loan.personName,
        'amount': loan.amount,
        'type': loan.type,
        'reason': loan.reason,
        'expected_return_date': loan.expectedReturnDate?.toIso8601String(),
        'date': DateTime.now().toIso8601String(),
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory.map((e) => {
          'amount': e['amount'],
          'timestamp': (e['timestamp'] as DateTime).toIso8601String(),
        }).toList(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Loan added successfully!');
        fetchLoans(); // Refresh list
      } else {
        Get.snackbar('Error', 'Failed to add loan: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error adding loan: $e';
      Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
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

      final response = await ApiService.put('/loans/$loanId', body: {
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory.map((e) => {
          'amount': e['amount'],
          'timestamp': e['timestamp'] is DateTime 
              ? (e['timestamp'] as DateTime).toIso8601String() 
              : e['timestamp'].toString(),
        }).toList(),
      });

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Payment updated successfully');
        fetchLoans(); // Refresh list to be sure
      } else {
        Get.snackbar('Error', 'Failed to update payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error updating payment: $e';
      Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    }
  }


  /// Delete loan from Firestore and local list
  Future<void> deleteLoan(String loanId) async {
    try {
      final response = await ApiService.delete('/loans/$loanId');
      if (response.statusCode == 200) {
        Get.snackbar('Loan Deleted', 'The loan was removed successfully');
        fetchLoans(); // Refresh list
      } else {
        Get.snackbar('Error', 'Failed to delete loan: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error deleting loan: $e';
      Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
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

      final response = await ApiService.put('/loans/$loanId', body: {
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory.map((e) => {
          'amount': e['amount'],
          'timestamp': e['timestamp'] is DateTime 
              ? (e['timestamp'] as DateTime).toIso8601String() 
              : e['timestamp'].toString(),
        }).toList(),
      });

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Payment updated successfully');
        fetchLoans(); // Refresh list
      } else {
        Get.snackbar('Error', 'Failed to update payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error editing payment: $e';
      Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
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

      final response = await ApiService.put('/loans/$loanId', body: {
        'paid_amount': loan.paidAmount.value,
        'status': loan.status.value,
        'payment_history': loan.paymentHistory.map((e) => {
          'amount': e['amount'],
          'timestamp': e['timestamp'] is DateTime 
              ? (e['timestamp'] as DateTime).toIso8601String() 
              : e['timestamp'].toString(),
        }).toList(),
      });

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Payment deleted successfully');
        fetchLoans(); // Refresh list
      } else {
        Get.snackbar('Error', 'Failed to delete payment: ${response.body}');
      }
    } catch (e) {
      errorMsg.value = 'Error deleting payment: $e';
      Get.snackbar('Error', errorMsg.value ?? 'Unknown error occurred');
    }
  }


  @override
  void onClose() {
    super.onClose();
  }

}
