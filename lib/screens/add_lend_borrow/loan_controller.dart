// ignore_for_file: empty_catches

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/screens/add_lend_borrow/loan_modal.dart';

class LoanController extends GetxController {
  final MyUser myUser;

  LoanController({required this.myUser});

  var loans = <Loan>[].obs;

  final _firestore = FirebaseFirestore.instance;

  /// Fetch loans from Firestore for the specific user
  Future<void> fetchLoans() async {
    try {
      final querySnapshot = await _firestore
          .collection('loans')
          .where('userId', isEqualTo: myUser.userId)
          .get();

      loans.value = querySnapshot.docs
          .map((doc) => Loan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {}
  }

  /// Getter for borrowed loans
  List<Loan> get borrowed => loans.where((l) => l.type == 'borrowed').toList();

  /// Getter for lent loans
  List<Loan> get lent => loans.where((l) => l.type == 'lent').toList();

  /// Add a new loan to Firestore
  Future<void> addLoan(Loan loan) async {
    try {
      // Ensure the loan has a userId before adding
      final data = loan.toMap();
      data['userId'] = myUser.userId;

      final loanDocRef =
          await FirebaseFirestore.instance.collection('loans').add(data);
      // Assign the generated ID and add to local list
      loan.id = loanDocRef.id;
      loans.add(loan);
      // ignore: empty_catches
    } catch (e) {}
  }

  /// Update payment status and paid amount in Firestore
  Future<void> updatePayment(String loanId, double paymentAmount) async {
    final loanDoc = FirebaseFirestore.instance.collection('loans').doc(loanId);

    final loan = loans.firstWhere((loan) => loan.id == loanId);

    // Update reactive values properly
    loan.paidAmount.value += paymentAmount;

    final paymentRecord = {
      'amount': paymentAmount,
      'date': DateTime.now().toIso8601String(),
    };
    loan.paymentHistory.add(paymentRecord);

    if (loan.paidAmount.value >= loan.amount) {
      loan.status.value = 'paid';
    } else {
      loan.status.value = 'partially paid';
    }

    loans.refresh();

    try {
      await loanDoc.update({
        'paidAmount': loan.paidAmount.value,
        'status': loan.status.value,
        'paymentHistory': FieldValue.arrayUnion([paymentRecord]),
      });
    } catch (e) {}
  }

  /// Delete a loan from Firestore
  Future<void> deleteLoan(String loanId) async {
    try {
      // Delete the loan from Firestore using the loanId
      await FirebaseFirestore.instance.collection('loans').doc(loanId).delete();

      // After successful deletion, update the local list
      borrowed.removeWhere((loan) => loan.id == loanId);
      lent.removeWhere((loan) => loan.id == loanId);

      // Refresh the list to reflect latest data
      await fetchLoans();

      // Attractive styled SnackBar
      Get.snackbar(
        "Loan Deleted",
        "The loan was removed successfully.",
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(12),
        borderRadius: 12,
        icon: Icon(Icons.check_circle, color: Colors.white),
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete loan. Please try again.",
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(12),
        borderRadius: 12,
        icon: Icon(Icons.error_outline, color: Colors.white),
        duration: Duration(seconds: 2),
      );
    }
  }
}
