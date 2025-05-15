import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Loan {
  String id;
  String userId;
  String personName;
  double amount;
  RxDouble paidAmount;
  RxString status;
  DateTime date;
  DateTime? expectedReturnDate;
  String type;
  String? reason;
  RxList<Map<String, dynamic>> paymentHistory;

  Loan({
    required this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    required RxDouble paidAmount,
    required RxString status,
    required this.date,
    this.expectedReturnDate,
    required this.type,
    this.reason,
    RxList<Map<String, dynamic>>? paymentHistory,
  })  : paidAmount = paidAmount,
        status = status,
        paymentHistory = paymentHistory ?? <Map<String, dynamic>>[].obs;

  /// Convert Loan object to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount.value,
      'status': status.value,
      'date': Timestamp.fromDate(date), // Correctly converting DateTime to Timestamp
      'expectedReturnDate': expectedReturnDate != null
          ? Timestamp.fromDate(expectedReturnDate!)
          : null,
      'type': type,
      'reason': reason,
      'paymentHistory': paymentHistory
          .map((e) => {
                'amount': e['amount'],
                'timestamp': e['timestamp'] is DateTime
                    ? Timestamp.fromDate(e['timestamp'])
                    : e['timestamp'],
              })
          .toList(),
    };
  }

  /// Convert Firestore map to Loan object
  factory Loan.fromMap(Map<String, dynamic> map, String id) {
    return Loan(
      id: id,
      userId: map['userId'],
      personName: map['personName'],
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble().obs,
      status: (map['status'] as String).obs,
      date: (map['date'] as Timestamp).toDate(), // Converting Timestamp back to DateTime
      expectedReturnDate: map['expectedReturnDate'] != null
          ? (map['expectedReturnDate'] as Timestamp).toDate()
          : null,
      type: map['type'],
      reason: map['reason'],
      paymentHistory: RxList<Map<String, dynamic>>.from(
        (map['paymentHistory'] as List<dynamic>? ?? []).map((e) => {
              'amount': (e['amount'] as num).toDouble(),
              'timestamp': (e['timestamp'] as Timestamp).toDate(), // Convert back to DateTime
            }),
      ),
    );
  }
}
