import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/controllers/expenseController.dart';
import 'package:spendly/controllers/incomeController.dart';
import 'package:spendly/models/myuser.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/services/app_update_service.dart';

class SplashController extends GetxController {
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _checkUpdateAndLogin();
  }

  Future<void> _checkUpdateAndLogin() async {
    final updateService = Get.put(AppUpdateService());
    await updateService.checkForUpdate();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 5)); // Simulate splash delay

    bool hasSeenOnboarding = box.read('hasSeenOnboarding') ?? false;
    User? user = FirebaseAuth.instance.currentUser;

    if (!hasSeenOnboarding) {
      if (user != null) {
        MyUser myUser = await _getUserData(user.uid);
        Get.offAllNamed(RoutesName.onboardingView, arguments: myUser);
      } else {
        Get.offAllNamed(RoutesName.onboardingView);
      }
    } else {
      if (user != null) {
        MyUser myUser = await _getUserData(user.uid);
        Get.put(ExpenseController());
        Get.put(IncomeController());
        Get.offAllNamed(RoutesName.homeView, arguments: myUser);
      } else {
        Get.offAllNamed(RoutesName.welcomeView);
      }
    }
  }

// Helper function to convert User to MyUser
  Future<MyUser> _getUserData(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    return MyUser(
      userId: userData['userId'] ?? uid,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
      lastLogin: userData['lastLogin'] ?? Timestamp.now(),
    );
  }
}
