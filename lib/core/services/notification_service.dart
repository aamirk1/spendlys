import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/models/notification_model.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:uuid/uuid.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _storage = GetStorage();
  final String _storageKey = 'saved_notifications';

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  Future<NotificationService> init() async {
    _loadNotifications();
    await _initializeLocalNotifications();
    await _requestPermissions();
    _configureFCM();
    return this;
  }

  void _loadNotifications() {
    final List<dynamic>? stored = _storage.read<List<dynamic>>(_storageKey);
    if (stored != null) {
      notifications.assignAll(
        stored.map((e) => NotificationModel.fromJson(e)).toList(),
      );
    }
  }

  Future<void> saveNotification(NotificationModel notification) async {
    notifications.insert(0, notification);
    await _storage.write(
      _storageKey,
      notifications.map((e) => e.toJson()).toList(),
    );
  }

  void markAsRead(String id) {
    int index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = true;
      notifications.refresh();
      _storage.write(
        _storageKey,
        notifications.map((e) => e.toJson()).toList(),
      );
    }
  }

  void clearAll() {
    notifications.clear();
    _storage.remove(_storageKey);
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            handleNavigation(data);
          } catch (e) {
            print("Error parsing payload: $e");
          }
        }
      },
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _configureFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.notification?.title}");
      _processIncomingMessage(message);
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened via notification: ${message.data}");
      handleNavigation(message.data);
    });

    // Check for initial message (if app was terminated)
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        handleNavigation(message.data);
      }
    });
  }

  void _processIncomingMessage(RemoteMessage message) {
    if (message.notification != null) {
      final notification = NotificationModel(
        id: Uuid().v4(),
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
        timestamp: DateTime.now(),
        data: message.data,
      );
      saveNotification(notification);
    }
  }

  void handleNavigation(Map<String, dynamic> data) {
    final target = data['target_screen'];
    print("Navigating to target: $target");

    switch (target) {
      case 'invoice_list':
        Get.toNamed(RoutesName.invoiceList);
        break;
      case 'quotation_list':
        Get.toNamed(RoutesName.quotationList);
        break;
      case 'loan_list':
        Get.toNamed(RoutesName.addLendBorrowView);
        break;
      case 'view_loan':
        // Try to find the loan in LoanController if it exists
        if (data.containsKey('loan_id')) {
          try {
            final loanController = Get.find<LoanController>();
            final loan = loanController.loans.firstWhere(
              (l) => l.id == data['loan_id'],
            );
            Get.toNamed(RoutesName.viewLoan, arguments: {
              'loan': loan,
              'controller': loanController,
            });
          } catch (e) {
            // If loan not found or controller not initialized, fall back to list
            Get.toNamed(RoutesName.addLendBorrowView);
          }
        } else {
          Get.toNamed(RoutesName.addLendBorrowView);
        }
        break;
      case 'premium':
        Get.toNamed(RoutesName.premiumView);
        break;
      case 'business_home':
        Get.toNamed(RoutesName.businessHome);
        break;
      default:
        // By default go to main view or notifications screen
        Get.toNamed(RoutesName.notificationsScreen);
        break;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
