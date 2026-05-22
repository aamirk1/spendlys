import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:spendly/core/services/app_update_service.dart';
import 'package:spendly/features/auth/presentation/cubits/sign_in_cubit.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';
import 'package:spendly/features/auth/data/services/auth_service.dart';

abstract class SplashState extends Equatable {
  const SplashState();
  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}
class SplashLoading extends SplashState {}
class SplashUpdateRequired extends SplashState {}
class SplashAuthenticated extends SplashState {
  final MyUser user;
  const SplashAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class SplashUnauthenticated extends SplashState {}

class SplashCubit extends Cubit<SplashState> {
  final GetStorage _box;
  final AppUpdateService _updateService;
  final SignInCubit _signInCubit;
  final SecureStorageService _secureStorage;
  final AuthService _authService;

  SplashCubit(
    this._box,
    this._updateService,
    this._signInCubit,
    this._secureStorage,
    this._authService,
  ) : super(SplashInitial());

  Future<void> checkAuthStatus() async {
    emit(SplashLoading());
    try {
      // 1. Start the update check and silent login in parallel
      final updateFuture = _updateService.checkForUpdate();

      // 2. Check if user is logged in
      final bool isLoggedIn = _box.read("isLoggedIn") ?? false;
      
      bool isAuthed = false;
      if (isLoggedIn) {
        isAuthed = await _performSilentLogin();
      }

      // 3. Await the update check result
      final bool updateTriggered = await updateFuture;
      if (updateTriggered) {
        emit(SplashUpdateRequired());
        return;
      }

      if (isLoggedIn && isAuthed) {
        MyUser myUser = MyUser.fromStorage();
        emit(SplashAuthenticated(myUser));
      } else {
        if (isLoggedIn) {
          _box.write("isLoggedIn", false);
        }
        emit(SplashUnauthenticated());
      }
    } catch (e) {
      debugPrint("Splash silent login error: $e");
      emit(SplashUnauthenticated());
    }
  }

  Future<bool> _performSilentLogin() async {
    try {
      final credentials = await _secureStorage.getCredentials();
      final email = credentials['email'];
      final password = credentials['password'];

      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        // Perform email/password login
        final user = await _signInCubit.signInWithEmailAndPassword(email, password);
        return user != null;
      }

      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        final user = await _signInCubit.syncUserByFirebaseToken(firebaseUser);
        return user != null;
      }

      return false;
    } catch (e) {
      debugPrint("Silent login helper failed: $e");
      return false;
    }
  }
}
