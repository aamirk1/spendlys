/// WhatsApp Service (Flutter side)
///
/// This service calls the backend `/api/v1/whatsapp/send` endpoint to trigger
/// WhatsApp utility template messages via the Meta Cloud API.
///
/// All heavy lifting (token, phone-number-ID, template rendering) is done
/// server-side — this file is intentionally thin.
///
/// Usage example:
/// ```dart
/// await WhatsAppService.sendLoanNotification(
///   phone: '+919876543210',
///   lenderName: 'Rahul',
///   borrowerName: 'Amit',
///   amount: 5000,
///   dueDate: '30-04-2026',
///   type: 'lent',
/// );
/// ```
library;

import 'package:spendly/core/services/api_service.dart';

class WhatsAppService {
  // ─────────────────────────────────────────────────────────────────────────
  // Loan notifications
  // ─────────────────────────────────────────────────────────────────────────

  /// Send a WhatsApp notification when a loan is added.
  ///
  /// [type] → 'lent' or 'borrowed'
  ///
  /// The backend decides which template to use based on [type].
  static Future<void> sendLoanNotification({
    required String phone,
    required String lenderName,
    required String borrowerName,
    required double amount,
    String? dueDate,
    required String type, // 'lent' or 'borrowed'
  }) async {
    try {
      await ApiService.post(
        '/whatsapp/loan',
        body: {
          'phone': phone,
          'lender_name': lenderName,
          'borrower_name': borrowerName,
          'amount': amount,
          'due_date': dueDate,
          'type': type,
        },
      );
    } catch (_) {
      // WhatsApp is best-effort — never block the main flow
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Invoice notifications
  // ─────────────────────────────────────────────────────────────────────────

  /// Send a WhatsApp notification when an invoice is created.
  ///
  /// [customerPhone] must be a valid phone number (Indian or E.164).
  static Future<void> sendInvoiceNotification({
    required String customerPhone,
    required String customerName,
    required String businessName,
    required String invoiceNumber,
    required double total,
    String? dueDate,
  }) async {
    try {
      await ApiService.post(
        '/whatsapp/invoice',
        body: {
          'phone': customerPhone,
          'customer_name': customerName,
          'business_name': businessName,
          'invoice_number': invoiceNumber,
          'total': total,
          'due_date': dueDate,
        },
      );
    } catch (_) {
      // Best-effort
    }
  }
}
