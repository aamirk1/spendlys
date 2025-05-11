import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Loan {
  String id;
  String userId;
  String personName;
  double amount;
  RxDouble paidAmount;
  RxString status;
  DateTime dateBorrowed;
  DateTime? expectedReturnDate;
  String type;
  String? reason;
  RxList<Map<String, dynamic>> paymentHistory;

  Loan({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required double paidAmount,
    required String status,
    required this.dateBorrowed,
    this.expectedReturnDate,
    required this.type,
    this.reason,
    List<Map<String, dynamic>>? paymentHistory,
  })  : paidAmount = paidAmount.obs,
        status = status.obs,
        paymentHistory = (paymentHistory ?? []).obs;

  // Map data to save in Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount.value,
      'status': status.value,
      'dateBorrowed': dateBorrowed,
      'expectedReturnDate': expectedReturnDate,
      'type': type,
      'reason': reason,
      'paymentHistory': paymentHistory,
    };
  }

  // Convert Firestore data to Loan object
  factory Loan.fromMap(Map<String, dynamic> map, String id) {
    return Loan(
      id: id,
      userId: map['userId'],
      personName: map['personName'],
      amount: map['amount'],
      paidAmount: map['paidAmount'],
      status: map['status'],
      dateBorrowed: (map['dateBorrowed'] as Timestamp).toDate(),
      expectedReturnDate: map['expectedReturnDate'] != null
          ? (map['expectedReturnDate'] as Timestamp).toDate()
          : null,
      type: map['type'],
      reason: map['reason'],
      paymentHistory:
          List<Map<String, dynamic>>.from(map['paymentHistory'] ?? []),
    );
  }
}
