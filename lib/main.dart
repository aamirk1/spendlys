import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:spendly/app.dart';
import 'package:spendly/core/services/notification_service.dart';
import 'package:spendly/core/services/reminder_notification_service.dart';
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

  // Smooth edge-to-edge rendering
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Set timezone to India (IST) for correct reminder scheduling
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  await Firebase.initializeApp();
  
  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Local Storage
  await GetStorage.init();
  await LocalCacheService.init();

  // Initialize Global Services
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => ReminderNotificationService().init());
  Get.put(SyncService());
  Get.put(ConnectivityService());

  runApp(MyApp());
}
