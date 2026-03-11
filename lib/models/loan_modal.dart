// import 'package:cloud_firestore/cloud_firestore.dart';
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
      'date': date.toIso8601String(),
      'expectedReturnDate': expectedReturnDate?.toIso8601String(),
      'type': type,
      'reason': reason,
      'paymentHistory': paymentHistory
          .map((e) => {
                'amount': e['amount'],
                'timestamp': e['timestamp'] is DateTime
                    ? (e['timestamp'] as DateTime).toIso8601String()
                    : e['timestamp'],
              })
          .toList(),
    };
  }


  /// Convert Firestore map to Loan object
  factory Loan.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is String) return DateTime.parse(d);
      // Fallback if somehow it's still a Timestamp in transition (though we commented it)
      // return (d as Timestamp).toDate(); 
      return DateTime.now();
    }

    return Loan(
      id: id,
      userId: map['user_id'] ?? map['userId'] ?? '',
      personName: map['person_name'] ?? map['personName'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] ?? map['paidAmount'] as num).toDouble().obs,
      status: (map['status'] as String).obs,
      date: parseDate(map['date']),
      expectedReturnDate: map['expected_return_date'] != null || map['expectedReturnDate'] != null
          ? parseDate(map['expected_return_date'] ?? map['expectedReturnDate'])
          : null,
      type: map['type'],
      reason: map['reason'],
      paymentHistory: RxList<Map<String, dynamic>>.from(
        (map['payment_history'] ?? map['paymentHistory'] as List<dynamic>? ?? []).map((e) => {
              'amount': (e['amount'] as num).toDouble(),
              'timestamp': parseDate(e['timestamp']),
            }),
      ),
    );
  }

}
