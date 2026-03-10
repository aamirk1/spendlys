class MyUser {
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final DateTime lastLogin;
  final String? image;

  MyUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.lastLogin,
    this.image,
  });

  static final empty = MyUser(
    userId: '',
    name: '',
    email: '',
    phoneNumber: '',
    lastLogin: DateTime.now(),
    image: null,
  );

  MyUser copyWith({
    String? userId,
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? lastLogin,
    String? image,
  }) {
    return MyUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastLogin: lastLogin ?? this.lastLogin,
      image: image ?? this.image,
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
    };
  }
}
