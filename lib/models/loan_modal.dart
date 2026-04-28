// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';


class Loan {
  String id;
  String userId;
  String personName;
  String? personPhone;
  double amount;
  RxDouble paidAmount;
  RxString status;
  DateTime date;
  DateTime? expectedReturnDate;
  String type;
  String? paymentMode;
  String? creatorName;
  String? reason;
  RxList<Map<String, dynamic>> paymentHistory;

  Loan({
    required this.id,
    required this.userId,
    required this.personName,
    this.personPhone,
    required this.amount,
    required RxDouble paidAmount,
    required RxString status,
    required this.date,
    this.expectedReturnDate,
    required this.type,
    this.paymentMode,
    this.creatorName,
    this.reason,
    RxList<Map<String, dynamic>>? paymentHistory,
  })  : paidAmount = paidAmount,
        status = status,
        paymentHistory = paymentHistory ?? <Map<String, dynamic>>[].obs;

  /// Convert Loan object to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'person_name': personName,
      'person_phone': personPhone,
      'amount': amount,
      'paidAmount': paidAmount.value,
      'status': status.value,
      'date': date.toIso8601String(),
      'expectedReturnDate': expectedReturnDate?.toIso8601String(),
      'type': type,
      'payment_mode': paymentMode,
      'creator_name': creatorName,
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
      if (d is String) {
        try {
          return DateTime.parse(d);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Loan(
      id: id,
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      personName: map['person_name']?.toString() ?? map['personName']?.toString() ?? 'Unknown',
      personPhone: map['person_phone']?.toString() ?? map['personPhone']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num? ?? map['paidAmount'] as num? ?? 0.0).toDouble().obs,
      status: (map['status']?.toString() ?? 'pending').obs,
      date: parseDate(map['date']),
      expectedReturnDate: (map['expected_return_date'] != null || map['expectedReturnDate'] != null)
          ? parseDate(map['expected_return_date'] ?? map['expectedReturnDate'])
          : null,
      type: map['type']?.toString() ?? 'lent',
      paymentMode: map['payment_mode']?.toString(),
      creatorName: map['creator_name']?.toString() ?? map['creatorName']?.toString(),
      reason: map['reason']?.toString(),
      paymentHistory: RxList<Map<String, dynamic>>.from(
        (map['payment_history'] as List<dynamic>? ?? map['paymentHistory'] as List<dynamic>? ?? []).map((e) {
          final entry = e as Map<String, dynamic>;
          return {
            'amount': (entry['amount'] as num?)?.toDouble() ?? 0.0,
            'timestamp': parseDate(entry['timestamp']),
          };
        }),
      ),
    );
  }

}
