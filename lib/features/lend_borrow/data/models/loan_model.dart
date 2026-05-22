class Loan {
  final String id;
  final String userId;
  final String personName;
  final String? personPhone;
  final double amount;
  final double paidAmount;
  final String status;
  final DateTime date;
  final DateTime? expectedReturnDate;
  final String type;
  final String? paymentMode;
  final String? creatorName;
  final String? reason;
  final List<Map<String, dynamic>> paymentHistory;

  Loan({
    required this.id,
    required this.userId,
    required this.personName,
    this.personPhone,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.date,
    this.expectedReturnDate,
    required this.type,
    this.paymentMode,
    this.creatorName,
    this.reason,
    this.paymentHistory = const [],
  });

  Loan copyWith({
    String? id,
    String? userId,
    String? personName,
    String? personPhone,
    double? amount,
    double? paidAmount,
    String? status,
    DateTime? date,
    DateTime? expectedReturnDate,
    String? type,
    String? paymentMode,
    String? creatorName,
    String? reason,
    List<Map<String, dynamic>>? paymentHistory,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      personPhone: personPhone ?? this.personPhone,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      date: date ?? this.date,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      type: type ?? this.type,
      paymentMode: paymentMode ?? this.paymentMode,
      creatorName: creatorName ?? this.creatorName,
      reason: reason ?? this.reason,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'person_name': personName,
      'person_phone': personPhone,
      'amount': amount,
      'paidAmount': paidAmount,
      'status': status,
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
                    : e['timestamp'].toString(),
              })
          .toList(),
    };
  }

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
      personName: map['person_name']?.toString() ??
          map['personName']?.toString() ??
          'Unknown',
      personPhone:
          map['person_phone']?.toString() ?? map['personPhone']?.toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num? ?? map['paidAmount'] as num? ?? 0.0)
          .toDouble(),
      status: map['status']?.toString() ?? 'pending',
      date: parseDate(map['date']),
      expectedReturnDate: (map['expected_return_date'] != null ||
              map['expectedReturnDate'] != null)
          ? parseDate(map['expected_return_date'] ?? map['expectedReturnDate'])
          : null,
      type: map['type']?.toString() ?? 'lent',
      paymentMode: map['payment_mode']?.toString(),
      creatorName:
          map['creator_name']?.toString() ?? map['creatorName']?.toString(),
      reason: map['reason']?.toString(),
      paymentHistory: List<Map<String, dynamic>>.from(
        (map['payment_history'] as List<dynamic>? ??
                map['paymentHistory'] as List<dynamic>? ??
                [])
            .map((e) {
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
