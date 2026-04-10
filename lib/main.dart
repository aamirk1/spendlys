import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:spendly/app.dart';
import 'package:spendly/core/services/notification_service.dart';
import 'package:spendly/core/services/local_cache_service.dart';
import 'package:spendly/core/services/connectivity_service.dart';
import 'package:spendly/core/services/sync_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Local Storage
  await GetStorage.init();
  await LocalCacheService.init();

  // Initialize Global Services
  await Get.putAsync(() => NotificationService().init());
  Get.put(SyncService());
  Get.put(ConnectivityService());

  runApp(MyApp());
}
