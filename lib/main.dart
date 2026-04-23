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
import 'package:spendly/core/services/security_service.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    final storage = GetStorage();
    final List<dynamic> stored =
        storage.read<List<dynamic>>('saved_notifications') ?? [];

    final newNotification = {
      'id': Uuid().v4(),
      'title': message.notification?.title ?? "No Title",
      'body': message.notification?.body ?? "No Body",
      'timestamp': DateTime.now().toIso8601String(),
      'data': message.data,
      'isRead': false,
    };

    stored.insert(0, newNotification);
    await storage.write('saved_notifications', stored);
  }
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

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize App Check & Firebase Messaging in background
  FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Storage & Basic Services
  await Future.wait([
    GetStorage.init(),
    LocalCacheService.init(),
  ]);

  // Initialize Global Services in parallel
  await Future.wait([
    Get.putAsync(() => NotificationService().init()),
    Get.putAsync(() => ReminderNotificationService().init()),
    Get.putAsync(() => SecurityService().init()),
  ]);

  Get.put(SyncService());
  Get.put(ConnectivityService());

  runApp(MyApp());
}
