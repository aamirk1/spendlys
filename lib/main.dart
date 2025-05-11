import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await GetStorage.init(); // ✅ Initialize GetStorage
  // Get.put(ExpenseController());
  // Get.put(IncomeController());

  runApp(MyApp());
}
