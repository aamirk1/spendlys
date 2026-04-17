import 'dart:io';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:spendly/core/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Notification ID ranges to avoid collisions:
///   1000–1999  → Loan creation confirmations
///   2000–2999  → Loan due-date reminders (1 day before)
///   3000–5999  → Loan due-date every-2-hour reminders (up to 10 per loan × 3 slots)
///   6000–6999  → Invoice creation confirmations
///   7000–7999  → Invoice due-date reminders (1 day before)
///   8000–9999  → Invoice due-date every-2-hour reminders

const String _channelId = 'reminders_channel';
const String _channelName = 'Payment Reminders';
const String _channelDesc =
    'Loan and invoice due-date reminders for DailyBachat';

class ReminderNotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<ReminderNotificationService> init() async {
    // Init timezones
    tz_data.initializeTimeZones();

    // Initialize plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            Get.find<NotificationService>().handleNavigation(data);
          } catch (e) {
            print("Error parsing payload in ReminderService: $e");
          }
        }
      },
    );

    // Create dedicated reminder channel on Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    return this;
  }

  // ---------------------------------------------------------------------------
  // LOAN NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// Called immediately when a loan is added.
  /// Sends a confirmation notification + schedules due-date reminders.
  Future<void> scheduleLoanNotifications({
    required String loanId,
    required String personName,
    required double amount,
    required String type, // 'lent' or 'borrowed'
    required DateTime dueDate,
  }) async {
    final isLent = type == 'lent';
    final amountStr = '₹${amount.toStringAsFixed(0)}';
    final dueDateStr =
        '${dueDate.day}/${dueDate.month}/${dueDate.year}';

    // 1. Immediate confirmation notification
    await _showImmediate(
      id: _loanConfirmId(loanId),
      title: isLent
          ? '💸 Amount Lent Recorded'
          : '📥 Amount Borrowed Recorded',
      body: isLent
          ? 'You lent $amountStr to $personName. Due: $dueDateStr'
          : 'You borrowed $amountStr from $personName. Due: $dueDateStr',
      payload: jsonEncode({
        'target_screen': 'view_loan',
        'loan_id': loanId,
        'type': 'loan_confirm'
      }),
    );

    // 2. Schedule reminders
    await _scheduleDueDateReminders(
      baseId: _loanReminderBaseId(loanId),
      title: isLent
          ? '🔔 Payment Due — $personName'
          : '⚠️ Repayment Reminder',
      bodyOneDayBefore: isLent
          ? '$personName owes you $amountStr. Due TOMORROW!'
          : 'You owe $amountStr to $personName. Due TOMORROW!',
      bodyOnDueDay: isLent
          ? '$personName hasn\'t paid $amountStr yet. Due TODAY!'
          : 'Today is the last day to repay $amountStr to $personName!',
      dueDate: dueDate,
      payload: jsonEncode({
        'target_screen': 'view_loan',
        'loan_id': loanId,
        'type': 'loan_reminder'
      }),
    );
  }

  /// Cancel all scheduled reminders for a specific loan (e.g., when paid/deleted).
  Future<void> cancelLoanReminders(String loanId) async {
    await _plugin.cancel(_loanConfirmId(loanId));
    await _cancelDueDateReminders(_loanReminderBaseId(loanId));
  }

  // ---------------------------------------------------------------------------
  // INVOICE NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// Called immediately when an invoice is created.
  /// Sends confirmation + schedules due-date reminders if due date exists.
  Future<void> scheduleInvoiceNotifications({
    required String invoiceId,
    required String invoiceNumber,
    required double total,
    required String customerName,
    DateTime? dueDate,
  }) async {
    final totalStr = '₹${total.toStringAsFixed(0)}';

    // 1. Immediate confirmation
    await _showImmediate(
      id: _invoiceConfirmId(invoiceId),
      title: '🧾 Invoice Generated Successfully',
      body:
          'Invoice $invoiceNumber for $customerName — $totalStr created.',
      payload: jsonEncode({
        'target_screen': 'invoice_list',
        'invoice_id': invoiceId,
        'type': 'invoice_confirm'
      }),
    );

    // 2. Schedule reminders only if due date is set
    if (dueDate != null && dueDate.isAfter(DateTime.now())) {
      await _scheduleDueDateReminders(
        baseId: _invoiceReminderBaseId(invoiceId),
        title: '📋 Invoice Payment Reminder',
        bodyOneDayBefore:
            'Invoice $invoiceNumber ($totalStr) from $customerName is due TOMORROW!',
        bodyOnDueDay:
            'Invoice $invoiceNumber ($totalStr) from $customerName is due TODAY! Follow up now.',
        dueDate: dueDate,
        payload: jsonEncode({
          'target_screen': 'invoice_list',
          'invoice_id': invoiceId,
          'type': 'invoice_reminder'
        }),
      );
    }
  }

  /// Cancel all invoice reminders (e.g., when invoice is marked paid).
  Future<void> cancelInvoiceReminders(String invoiceId) async {
    await _plugin.cancel(_invoiceConfirmId(invoiceId));
    await _cancelDueDateReminders(_invoiceReminderBaseId(invoiceId));
  }

  // ---------------------------------------------------------------------------
  // CORE SCHEDULING LOGIC
  // ---------------------------------------------------------------------------

  /// Shows an immediate local notification.
  Future<void> _showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  /// Schedules:
  ///   - 1 notification at 9:00 AM the day before the due date
  ///   - Notifications every 2 hours on the due date (8 AM, 10 AM, 12 PM, 2 PM, 4 PM, 6 PM, 8 PM)
  Future<void> _scheduleDueDateReminders({
    required int baseId,
    required String title,
    required String bodyOneDayBefore,
    required String bodyOnDueDay,
    required DateTime dueDate,
    String? payload,
  }) async {
    final now = DateTime.now();
    final local = tz.local;

    // --- Day Before: 9:00 AM ---
    final dayBefore = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      9,
      0,
    );
    if (dayBefore.isAfter(now)) {
      await _scheduleAt(
        id: baseId,
        scheduledTime: tz.TZDateTime.from(dayBefore, local),
        title: title,
        body: bodyOneDayBefore,
        payload: payload,
      );
    }

    // --- Due Day: every 2 hours from 8 AM to 8 PM ---
    final reminderHours = [8, 10, 12, 14, 16, 18, 20];
    for (int i = 0; i < reminderHours.length; i++) {
      final reminderTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        reminderHours[i],
        0,
      );
      if (reminderTime.isAfter(now)) {
        await _scheduleAt(
          id: baseId + i + 1, // baseId + 1, +2, ... +7
          scheduledTime: tz.TZDateTime.from(reminderTime, local),
          title: title,
          body: bodyOnDueDay,
          payload: payload,
        );
      }
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required tz.TZDateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // If exact alarms not permitted, fall back to inexact
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (_) {}
    }
  }

  Future<void> _cancelDueDateReminders(int baseId) async {
    // Cancel: baseId (day before) + baseId+1 ... baseId+7 (hourly on due day)
    for (int i = 0; i <= 7; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ID computation — uses a stable int derived from the UUID string
  int _loanConfirmId(String loanId) =>
      1000 + loanId.hashCode.abs() % 999;

  int _loanReminderBaseId(String loanId) =>
      2000 + (loanId.hashCode.abs() % 99) * 10;

  int _invoiceConfirmId(String invoiceId) =>
      6000 + invoiceId.hashCode.abs() % 999;

  int _invoiceReminderBaseId(String invoiceId) =>
      7000 + (invoiceId.hashCode.abs() % 99) * 10;
}
