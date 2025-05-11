import 'package:cloud_firestore/cloud_firestore.dart';

class MyUser {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final Timestamp lastLogin;

  MyUser(
      {required this.userId,
      required this.name,
      required this.email,
      required this.phoneNumber,
      required this.lastLogin});

  // Empty factory constructor
  static final empty = MyUser(
      userId: '',
      name: '',
      email: '',
      phoneNumber: '',
      lastLogin: Timestamp.now());

  // copyWith method
  MyUser copyWith(
      {String? userId,
      String? name,
      String? email,
      String? phoneNumber,
      Timestamp? lastLogin}) {
    return MyUser(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email ?? this.email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        lastLogin: lastLogin ?? this.lastLogin);
  }
}
