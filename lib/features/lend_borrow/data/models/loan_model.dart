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

  /// Convert Loan object to map (for API/Local)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  factory Loan.fromMap(Map<String, dynamic> map, String id) {
    return Loan(
      id: id,
      userId: map['userId'],
      personName: map['personName'],
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble().obs,
      status: (map['status'] as String).obs,
      date: DateTime.parse(map['date']),
      expectedReturnDate: map['expectedReturnDate'] != null
          ? DateTime.parse(map['expectedReturnDate'])
          : null,
      type: map['type'],
      reason: map['reason'],
      paymentHistory: RxList<Map<String, dynamic>>.from(
        (map['paymentHistory'] as List<dynamic>? ?? []).map((e) => {
              'amount': (e['amount'] as num).toDouble(),
              'timestamp': DateTime.parse(e['timestamp']),
            }),
      ),
    );
  }
}
