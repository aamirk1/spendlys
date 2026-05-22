import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoState extends Equatable {
  final MyUser myUser;
  final String profilePictureBase64;

  const UserInfoState({
    required this.myUser,
    required this.profilePictureBase64,
  });

  @override
  List<Object?> get props => [myUser, profilePictureBase64];
}

class UserInfoCubit extends Cubit<UserInfoState> {
  final GetStorage _box;

  UserInfoCubit(this._box)
      : super(UserInfoState(
          myUser: MyUser(
            userId: '',
            name: '',
            email: '',
            phoneNumber: '',
            lastLogin: Timestamp.now(),
          ),
          profilePictureBase64: '',
        )) {
    refreshUser();
  }

  void refreshUser() {
    final user = MyUser(
      userId: _box.read('userId') ?? '',
      name: _box.read('name') ?? '',
      email: _box.read('email') ?? '',
      phoneNumber: _box.read('phoneNumber') ?? '',
      lastLogin: Timestamp.now(),
      isPremium: _box.read('isPremium') ?? false,
      image: _box.read('profilePicture') ?? '',
    );
    emit(UserInfoState(
      myUser: user,
      profilePictureBase64: user.image ?? '',
    ));
  }

  void updateProfilePicture(String base64) {
    _box.write('profilePicture', base64);
    final updatedUser = state.myUser.copyWith(image: base64);
    emit(UserInfoState(
      myUser: updatedUser,
      profilePictureBase64: base64,
    ));
  }
}
