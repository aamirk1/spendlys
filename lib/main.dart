import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:spendly/app/app.dart';
import 'package:spendly/app/data/services/notification_service.dart';
import 'package:spendly/app/data/services/reminder_notification_service.dart';
import 'package:spendly/app/data/services/local_cache_service.dart';
import 'package:spendly/app/data/services/connectivity_service.dart';
import 'package:spendly/app/data/services/sync_service.dart';
import 'package:spendly/app/data/services/security_service.dart';
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

  // Initialize Storage, Local Cache & Firebase core in parallel for fastest startup
  await Future.wait([
    GetStorage.init(),
    LocalCacheService.init(),
    Firebase.initializeApp(),
  ]);

  // Set timezone to India (IST) for correct reminder scheduling
  tz_data.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  } catch (e) {
    debugPrint("Timezone set error: $e");
  }

  // Register core infrastructure services
  Get.put(ConnectivityService(), permanent: true);
  Get.put(SyncService(), permanent: true);

  // Setup Crashlytics error handlers
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());

  // Non-blocking background initialization for heavy notification & security services
  _initDeferredServices();
}

void _initDeferredServices() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint("AppCheck init warning: $e");
  }

  // Initialize notification & security services asynchronously without blocking UI mount
  Future.wait([
    Get.putAsync(() => NotificationService().init()),
    Get.putAsync(() => ReminderNotificationService().init()),
    Get.putAsync(() => SecurityService().init()),
  ]);
}
