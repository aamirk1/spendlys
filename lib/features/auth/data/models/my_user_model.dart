import 'package:get_storage/get_storage.dart';

class MyUser {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final DateTime lastLogin;
  final String? image;
  final bool isPremium;
  final String? referralCode;
  final String? referredById;
  final int referralCount;

  MyUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.lastLogin,
    this.image,
    required this.isPremium,
    this.referralCode,
    this.referredById,
    this.referralCount = 0,
  });

  static final empty = MyUser(
    userId: '',
    name: '',
    email: '',
    phoneNumber: '',
    lastLogin: DateTime.now(),
    image: null,
    isPremium: false,
    referralCode: null,
    referredById: null,
    referralCount: 0,
  );

  MyUser copyWith({
    String? userId,
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? lastLogin,
    String? image,
    bool? isPremium,
    String? referralCode,
    String? referredById,
    int? referralCount,
  }) {
    return MyUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastLogin: lastLogin ?? this.lastLogin,
      image: image ?? this.image,
      isPremium: isPremium ?? this.isPremium,
      referralCode: referralCode ?? this.referralCode,
      referredById: referredById ?? this.referredById,
      referralCount: referralCount ?? this.referralCount,
    );
  }

  factory MyUser.fromMap(Map<String, dynamic> map) {
    return MyUser(
      userId: map['userId'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone_number'] ?? '',
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'].toString())
          : DateTime.now(),
      image: map['image'],
      isPremium: map['isPremium'] ?? map['is_premium'] ?? false,
      referralCode: map['referralCode'] ?? map['referral_code'],
      referredById: map['referredById'] ?? map['referred_by_id'],
      referralCount: map['referralCount'] ?? map['referral_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'lastLogin': lastLogin.toIso8601String(),
      'image': image,
      'isPremium': isPremium,
      'referralCode': referralCode,
      'referredById': referredById,
      'referralCount': referralCount,
    };
  }

  factory MyUser.fromStorage() {
    final box = GetStorage();
    return MyUser(
      userId: box.read("userId") ?? '',
      name: box.read("name") ?? '',
      email: box.read("email") ?? '',
      phoneNumber: box.read("phoneNumber") ?? '',
      lastLogin: DateTime.now(),
      isPremium: box.read("isPremium") ?? false,
      referralCode: box.read("referralCode"),
      referredById: box.read("referredById"),
      referralCount: box.read("referralCount") ?? 0,
    );
  }
}
