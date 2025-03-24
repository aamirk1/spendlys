class MyUser {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;

  MyUser({required this.userId,required this.name, required this.email, required this.phoneNumber});

  // Empty factory constructor
  static final empty = MyUser(userId: '', name: '', email: '', phoneNumber: '');

  // copyWith method
  MyUser copyWith({String? userId, String? name, String? email, String? phoneNumber}) {
    return MyUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
