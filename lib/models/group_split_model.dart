import 'package:get/get.dart';

class Member {
  String name;
  String? phone;
  double shareAmount;
  RxDouble paidAmount;
  RxBool isPaid;

  Member({
    required this.name,
    this.phone,
    required this.shareAmount,
    required RxDouble paidAmount,
    required RxBool isPaid,
  })  : paidAmount = paidAmount,
        isPaid = isPaid;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'share_amount': shareAmount,
      'paid_amount': paidAmount.value,
      'is_paid': isPaid.value,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      name: map['name']?.toString() ?? 'Unknown',
      phone: map['phone']?.toString(),
      shareAmount: (map['share_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: ((map['paid_amount'] as num?)?.toDouble() ?? 0.0).obs,
      isPaid: (map['is_paid'] as bool? ?? false).obs,
    );
  }
}

class GroupSplit {
  String id;
  String userId;
  String title;
  double totalAmount;
  String splitType; // equal, unequal, percentage
  DateTime date;
  RxList<Member> members;
  DateTime createdAt;

  GroupSplit({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalAmount,
    required this.splitType,
    required this.date,
    required RxList<Member> members,
    required this.createdAt,
  }) : members = members;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'total_amount': totalAmount,
      'split_type': splitType,
      'date': date.toIso8601String(),
      'members': members.map((e) => e.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroupSplit.fromMap(Map<String, dynamic> map, String id) {
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

    final rawMembers = map['members'] as List<dynamic>? ?? [];
    final parsedMembers = rawMembers
        .map((e) => Member.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return GroupSplit(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      splitType: map['split_type']?.toString() ?? 'equal',
      date: parseDate(map['date']),
      members: RxList<Member>.from(parsedMembers),
      createdAt: parseDate(map['created_at']),
    );
  }
}
