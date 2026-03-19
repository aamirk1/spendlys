import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spendly/controllers/ledger_controller.dart';
import 'package:spendly/models/loan_modal.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;

class LedgerExportHelper {
  // PDF Generation phase
  static Future<Uint8List> generatePdfData({
    required LedgerType type,
    required List data,
  }) async {
    final pdf = pw.Document();
    final String title = "${type.name.toUpperCase()} LEDGER";
    final String dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    pw.ImageProvider? watermarkImage;
    try {
      final logoBytes =
          (await rootBundle.load('assets/logos/logo.png')).buffer.asUint8List();
      watermarkImage = pw.MemoryImage(logoBytes);
    } catch (_) {}

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
        header: (pw.Context context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900)),
                pw.Text(dateStr,
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300, height: 20),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo700),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: _getFormattedDataForPdf(type, data),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Print Preview presentation phase
  static Future<void> showPrintPreview(
      Uint8List pdfData, LedgerType type) async {
    final dateStr = DateFormat('ddMMMyyyy').format(DateTime.now());
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: '${type.name}_ledger_$dateStr.pdf',
    );
  }

  // CSV Generation phase
  static Future<String> generateCsvFile({
    required LedgerType type,
    required List data,
  }) async {
    List<List<dynamic>> csvData = [];
    switch (type) {
      case LedgerType.business:
        csvData.add([
          'Invoice Number',
          'Customer',
          'Date',
          'Status',
          'Total Amount',
          'Paid Amount'
        ]);
        for (var item in data) {
          csvData.add([
            item['invoice_number'],
            item['resolved_customer_name'] ?? 'Unknown',
            _formatDate(item['date']),
            item['status'],
            item['total'],
            item['paid_amount']
          ]);
        }
        break;
      case LedgerType.loan:
        csvData.add([
          'Person Name',
          'Type',
          'Date',
          'Due Date',
          'Amount',
          'Paid Amount',
          'Status'
        ]);
        for (var item in data) {
          final loan = item as Loan;
          csvData.add([
            loan.personName,
            loan.type,
            _formatDateObj(loan.date),
            _formatDateObj(loan.expectedReturnDate),
            loan.amount,
            loan.paidAmount.value,
            loan.status.value
          ]);
        }
        break;
      case LedgerType.expense:
        csvData.add(['Description', 'Category', 'Type', 'Date', 'Amount']);
        for (var item in data) {
          csvData.add([
            item['description'],
            item['category'],
            item['type'],
            _formatDateObj(item['date']),
            item['amount']
          ]);
        }
        break;
    }

    String csvString = csvData
        .map((row) => row
            .map((cell) => '"${cell.toString().replaceAll('"', '""')}"')
            .join(','))
        .join('\n');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${type.name}_ledger.csv');
    await file.writeAsString(csvString);
    return file.path;
  }

  // Share Sheet presentation phase
  static Future<void> showShareSheet(String filePath, LedgerType type) async {
    await Share.shareXFiles([XFile(filePath)],
        text: '${type.name.toUpperCase()} Ledger Export');
  }

  static List<List<String>> _getFormattedDataForPdf(
      LedgerType type, List data) {
    List<List<String>> result = [];
    switch (type) {
      case LedgerType.business:
        result.add(['Invoice #', 'Customer', 'Date', 'Status', 'Amount']);
        for (var item in data) {
          result.add([
            item['invoice_number'] ?? 'N/A',
            item['resolved_customer_name']?.toString() ?? 'Unknown',
            _formatDate(item['date']),
            (item['status'] ?? 'pending').toString().toUpperCase(),
            "Rs ${item['total'] ?? '0.00'}"
          ]);
        }
        break;
      case LedgerType.loan:
        result.add(['Person', 'Type', 'Date', 'Due Date', 'Amount']);
        for (var item in data) {
          result.add([
            item.personName,
            item.type ?? 'N/A',
            _formatDateObj(item.date),
            _formatDateObj(item.expectedReturnDate),
            "Rs ${item.amount ?? '0.00'}"
          ]);
        }
        break;
      case LedgerType.expense:
        result.add(['Description', 'Category', 'Type', 'Date', 'Amount']);
        for (var item in data) {
          result.add([
            item['description'] ?? 'N/A',
            item['category'] ?? 'N/A',
            item['type'] ?? 'N/A',
            _formatDateObj(item['date']),
            "Rs ${item['amount'] ?? '0.00'}"
          ]);
        }
        break;
    }
    return result;
  }

  static String _formatDate(dynamic d) {
    if (d == null) return "N/A";
    try {
      if (d is DateTime) return DateFormat('dd MMM yyyy').format(d);
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d.toString()));
    } catch (_) {
      return d.toString();
    }
  }

  static String _formatDateObj(DateTime? d) {
    if (d == null) return "N/A";
    return DateFormat('dd MMM yyyy').format(d);
  }
}
