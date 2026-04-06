import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class BusinessPdfHelper {
  static Future<void> generateAndPrintPdf({
    required String title,
    required Map<String, dynamic> businessProfile,
    required Map<String, dynamic> customer,
    required Map<String, dynamic> docData,
    required dynamic items,
    bool isInvoice = true,
  }) async {
    final pdf = await _buildPdfDocument(
      title: title,
      businessProfile: businessProfile,
      customer: customer,
      docData: docData,
      items: items,
      isInvoice: isInvoice,
    );

    final String docNumber = isInvoice
        ? (docData['invoice_number'] ?? 'N/A')
        : (docData['quotation_number'] ?? 'N/A');

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${isInvoice ? "Invoice" : "Quotation"}_$docNumber.pdf',
    );
  }

  static Future<void> generateAndSharePdf({
    required String title,
    required Map<String, dynamic> businessProfile,
    required Map<String, dynamic> customer,
    required Map<String, dynamic> docData,
    required dynamic items,
    bool isInvoice = true,
  }) async {
    final pdf = await _buildPdfDocument(
      title: title,
      businessProfile: businessProfile,
      customer: customer,
      docData: docData,
      items: items,
      isInvoice: isInvoice,
    );

    final String docNumber = isInvoice
        ? (docData['invoice_number'] ?? 'N/A')
        : (docData['quotation_number'] ?? 'N/A');

    final bytes = await pdf.save();

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${isInvoice ? "Invoice" : "Quotation"}_$docNumber.pdf',
    );
  }

  static Future<pw.Document> _buildPdfDocument({
    required String title,
    required Map<String, dynamic> businessProfile,
    required Map<String, dynamic> customer,
    required Map<String, dynamic> docData,
    required dynamic items,
    bool isInvoice = true,
  }) async {
    final pdf = pw.Document();

    // Load logo for watermark
    pw.ImageProvider? watermarkImage;
    try {
      final logoBytes =
          (await rootBundle.load('assets/logos/logo.png')).buffer.asUint8List();
      watermarkImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      print("Error loading logo for PDF: $e");
    }

    // Safe Numeric Parsing
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    // Safe JSON Decode for items
    List processedItems = items;
    if (items is String) {
      try {
        processedItems = jsonDecode(items);
      } catch (_) {}
    }

    String getName(Map data, List<String> keys) {
      for (var k in keys) {
        if (data[k] != null &&
            data[k].toString().trim().isNotEmpty &&
            data[k].toString() != 'null') {
          return data[k].toString();
        }
      }
      return "";
    }

    final String finalCustomerName =
        getName(customer, ['name', 'full_name', 'customer_name']).isNotEmpty
            ? getName(customer, ['name', 'full_name', 'customer_name'])
            : getName(docData, ['customer_name', 'name', 'full_name', 'customer'])
                    .isNotEmpty
                ? getName(
                    docData, ['customer_name', 'name', 'full_name', 'customer'])
                : 'Unknown Customer';

    final String docNumber = isInvoice
        ? (docData['invoice_number'] ?? 'N/A')
        : (docData['quotation_number'] ?? 'N/A');

    final String dateStr = docData['date'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(docData['date']))
        : DateFormat('dd MMM yyyy').format(DateTime.now());

    final String dueDateStr = isInvoice
        ? (docData['due_date'] != null &&
                docData['due_date'].toString().isNotEmpty &&
                docData['due_date'] != 'null'
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(docData['due_date']))
            : 'N/A')
        : (docData['expiry_date'] != null &&
                docData['expiry_date'].toString().isNotEmpty &&
                docData['expiry_date'] != 'null'
            ? DateFormat('dd MMM yyyy')
                .format(DateTime.parse(docData['expiry_date']))
            : 'N/A');

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (pw.Context context) {
        if (watermarkImage == null) return pw.SizedBox();
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Opacity(
              opacity: 0.1,
              child: pw.Image(watermarkImage, width: 350),
            ),
          ),
        );
      },
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return [
            // Header: Business Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessProfile['name'] ?? 'Your Business Name',
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(businessProfile['address'] ?? ''),
                    pw.Text('Phone: ${businessProfile['phone'] ?? ''}'),
                    pw.Text('Email: ${businessProfile['email'] ?? ''}'),
                    if (businessProfile['gst_number'] != null &&
                        businessProfile['gst_number'].toString().isNotEmpty)
                      pw.Text('GSTIN: ${businessProfile['gst_number']}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 30,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('No: $docNumber',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: $dateStr'),
                    if (dueDateStr != 'N/A')
                      pw.Text(
                          '${isInvoice ? "Due" : "Expiry"} Date: $dueDateStr'),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300, height: 40),

            // Customer Info & Logo Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey800)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        finalCustomerName,
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      if (customer['address'] != null &&
                          customer['address'].toString().isNotEmpty &&
                          customer['address'] != 'null')
                        pw.Text(customer['address'].toString()),
                      if (customer['phone'] != null &&
                          customer['phone'].toString().isNotEmpty &&
                          customer['phone'] != 'null')
                        pw.Text('Phone: ${customer['phone']}'),
                      if (customer['email'] != null &&
                          customer['email'].toString().isNotEmpty &&
                          customer['email'] != 'null')
                        pw.Text('Email: ${customer['email']}'),
                    ],
                  ),
                ),
                if (watermarkImage != null)
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Image(watermarkImage, fit: pw.BoxFit.contain),
                  ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Items Table
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside:
                    pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FixedColumnWidth(60),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(80),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Unit Price',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Table Body
                ...processedItems.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item['description'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item['quantity']?.toString() ?? '1',
                            textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Rs ${item['unit_price'] ?? '0'}',
                            textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Rs ${item['amount'] ?? '0'}',
                            textAlign: pw.TextAlign.right),
                      ),
                    ],
                  );
                }),
              ],
            ),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildSummaryRow(
                          'Subtotal:', 'Rs ${docData['subtotal'] ?? '0.00'}'),
                      _buildSummaryRow(
                          'Tax (${docData['tax_percent'] != null ? toDouble(docData['tax_percent']).toInt() : (toDouble(docData['tax']) / (toDouble(docData['subtotal']) > 0 ? toDouble(docData['subtotal']) : 1) * 100).toInt()}%):',
                          'Rs ${docData['tax'] ?? '0.00'}'),
                      pw.Divider(color: PdfColors.grey400),
                      _buildSummaryRow(
                          'Grand Total:', 'Rs ${docData['total'] ?? '0.00'}',
                          isTotal: true),
                      if (isInvoice) ...[
                        _buildSummaryRow('Paid Amount:',
                            'Rs ${docData['paid_amount'] ?? '0.00'}'),
                        _buildSummaryRow('Balance Due:',
                            'Rs ${(toDouble(docData['total']) - toDouble(docData['paid_amount'])).toStringAsFixed(2)}',
                            isTotal: true, color: PdfColors.red900),
                      ] else if (toDouble(docData['advance_amount']) > 0) ...[
                        _buildSummaryRow('Advance Paid:',
                            'Rs ${docData['advance_amount'] ?? '0.00'}'),
                        _buildSummaryRow('Remaining:',
                            'Rs ${(toDouble(docData['total']) - toDouble(docData['advance_amount'])).toStringAsFixed(2)}',
                            isTotal: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),

            // Footer: Payment Details
            if (businessProfile['payment_details'] != null &&
                businessProfile['payment_details'] is List &&
                (businessProfile['payment_details'] as List).isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PAYMENT DETAILS',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                'Bank: ${businessProfile['payment_details'][0]['bank_name'] ?? 'N/A'}'),
                            pw.Text(
                                'A/C No: ${businessProfile['payment_details'][0]['account_number'] ?? 'N/A'}'),
                            pw.Text(
                                'IFSC: ${businessProfile['payment_details'][0]['ifsc'] ?? 'N/A'}'),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                                'UPI ID: ${businessProfile['payment_details'][0]['upi_id'] ?? 'N/A'}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: isTotal ? 14 : 12,
                  fontWeight:
                      isTotal ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.SizedBox(width: 20),
          pw.SizedBox(
            width: 100,
            child: pw.Text(value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    fontSize: isTotal ? 14 : 12,
                    fontWeight:
                        isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: color)),
          ),
        ],
      ),
    );
  }
}
