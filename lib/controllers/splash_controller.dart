import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/services/app_update_service.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/controllers/sign_in_controller.dart';
import 'package:spendly/controllers/payment_controller.dart';
import 'package:spendly/core/storage/secure_storage_service.dart';

class SplashController extends GetxController {
  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // 1. Mandatory Update Check (Non-blocking if possible, but usually required early)
    final updateService = Get.find<AppUpdateService>();
    bool updateTriggered = await updateService.checkForUpdate();

    if (updateTriggered) return;

    // 2. Check if user is logged in
    bool isLoggedIn = _box.read("isLoggedIn") ?? false;

    if (isLoggedIn) {
      try {
        final signInController = Get.find<SignInController>();

        // Start silent login
        bool success = await _performSilentLogin(signInController);

        if (success) {
          // Initialize payment controller and check premium status in parallel if possible
          final paymentController = Get.put(PaymentController());
          // We don't necessarily need to await this if the home screen can handle it reactively
          paymentController.checkPremiumStatus();

          // Reconstruct MyUser for Home Screen
          MyUser myUser = MyUser.fromStorage();
          Get.offAllNamed(RoutesName.homeView, arguments: myUser);
        } else {
          // If silent login fails, force login
          _box.write("isLoggedIn", false);
          Get.offAllNamed(RoutesName.loginView);
        }
      } catch (e) {
        print("Silent login error: $e");
        Get.offAllNamed(RoutesName.loginView);
      }
    } else {
      Get.offAllNamed(RoutesName.loginView);
    }
  }

  Future<bool> _performSilentLogin(SignInController controller) async {
    try {
      // 1. Check for email/password credentials
      final credentials =
          await Get.find<SecureStorageService>().getCredentials();
      final email = credentials['email'];
      final password = credentials['password'];

      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        controller.emailController.text = email;
        controller.passwordController.text = password;
        await controller.signIn();
        return true;
      }

      // 2. Check for Firebase User
      final firebaseUser = controller.auth.currentUser;
      if (firebaseUser != null) {
        await controller.syncUserByFirebaseToken(firebaseUser);
        return true;
      }

      return false;
    } catch (e) {
      print("Silent login helper failed: $e");
      return false;
    }
  }
}
