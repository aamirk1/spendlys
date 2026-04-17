import 'package:get_storage/get_storage.dart';

class MyUser {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final DateTime lastLogin;
  final String? image;
  final bool isPremium;

  MyUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.lastLogin,
    this.image,
    required this.isPremium,
  });

  static final empty = MyUser(
    userId: '',
    name: '',
    email: '',
    phoneNumber: '',
    lastLogin: DateTime.now(),
    image: null,
    isPremium: false,
  );

  MyUser copyWith({
    String? userId,
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? lastLogin,
    String? image,
    bool? isPremium,
  }) {
    return MyUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastLogin: lastLogin ?? this.lastLogin,
      image: image ?? this.image,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  factory MyUser.fromMap(Map<String, dynamic> map) {
    return MyUser(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'].toString())
          : DateTime.now(),
      image: map['image'],
      isPremium: map['isPremium'] ?? false,
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
    );
  }
}
