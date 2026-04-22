import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spendly/features/auth/data/models/my_user_model.dart';
import 'package:spendly/models/notification_model.dart';
import 'package:spendly/res/routes/routes_name.dart';
import 'package:spendly/controllers/loan_controller.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:spendly/core/services/api_service.dart';
import 'package:spendly/services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

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

    // Reconstruct MyUser from storage for screens that need it

    switch (target) {
      case 'invoice_list':
        Get.toNamed(RoutesName.invoiceList);
        break;
      case 'view_invoice':
        if (data.containsKey('invoice_id')) {
          _fetchAndNavigate(
            endpoint: '/business/invoices/${data['invoice_id']}',
            routeName: RoutesName.viewInvoice,
            argKey: 'invoice', // Detail view uses 'inv' but we will pass Map directly as expected by InvoiceDetailView
            isMapDirect: true,
          );
        } else {
          Get.toNamed(RoutesName.invoiceList);
        }
        break;
      case 'quotation_list':
        Get.toNamed(RoutesName.quotationList);
        break;
      case 'view_quotation':
        if (data.containsKey('quotation_id')) {
          _fetchAndNavigate(
            endpoint: '/business/quotations/${data['quotation_id']}',
            routeName: RoutesName.viewQuotation,
            isMapDirect: true,
          );
        } else {
          Get.toNamed(RoutesName.quotationList);
        }
        break;
      case 'loan_list':
        Get.offAllNamed(RoutesName.homeView, arguments: {'index': 2});
        break;
      case 'view_loan':
        if (data.containsKey('loan_id')) {
          _fetchAndNavigate(
            endpoint: '/business/loans/${data['loan_id']}',
            routeName: RoutesName.viewLoan,
            isLoan: true,
          );
        } else {
          Get.offAllNamed(RoutesName.homeView, arguments: {'index': 2});
        }
        break;
      case 'premium':
        Get.toNamed(RoutesName.premiumView);
        break;
      case 'business_home':
        Get.toNamed(RoutesName.businessHome);
        break;
      default:
        Get.toNamed(RoutesName.notificationsScreen);
        break;
    }
  }

  Future<void> _fetchAndNavigate({
    required String endpoint,
    required String routeName,
    bool isMapDirect = false,
    bool isLoan = false,
    String? argKey,
  }) async {
    final userId = Get.find<AuthService>().currentUserId;
    if (userId == null) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.teal)),
      barrierDismissible: false,
    );

    try {
      final response = await ApiService.get(endpoint, headers: {'x-user-id': userId});
      Get.back(); // hide loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (isLoan) {
          final loanController = Get.isRegistered<LoanController>()
              ? Get.find<LoanController>()
              : Get.put(LoanController());
          
          final loan = Loan.fromMap(data, data['id'] ?? '');
          
          // Reconstruct MyUser
          final myUser = MyUser.fromStorage();
          
          Get.toNamed(routeName, arguments: {
            'loan': loan, // Pass actual Loan object
            'controller': loanController,
            'myUser': myUser,
          });
        } else if (isMapDirect) {
          Get.toNamed(routeName, arguments: data);
        } else {
          Get.toNamed(routeName, arguments: {argKey ?? 'data': data});
        }
      } else {
        Get.snackbar("Error", "Failed to fetch details");
      }
    } catch (e) {
      Get.back();
      print("Fetch error: $e");
      Get.snackbar("Error", "An error occurred while fetching details");
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
