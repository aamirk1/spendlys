import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

enum BusinessExportType { customers, inventory }

class BusinessExportHelper {
  // PDF Generation phase
  static Future<Uint8List> generatePdfData({
    required BusinessExportType type,
    required List data,
  }) async {
    final pdf = pw.Document();
    final String title = type == BusinessExportType.customers ? "CUSTOMER LIST" : "INVENTORY LIST";
    final String dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    pw.ImageProvider? watermarkImage;
    try {
      final logoBytes = (await rootBundle.load('assets/logos/logo.png')).buffer.asUint8List();
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
  static Future<void> showPrintPreview(Uint8List pdfData, BusinessExportType type) async {
    final dateStr = DateFormat('ddMMMyyyy').format(DateTime.now());
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: '${type.name}_export_$dateStr.pdf',
    );
  }

  // CSV Generation phase
  static Future<String> generateCsvFile({
    required BusinessExportType type,
    required List data,
  }) async {
    List<List<dynamic>> csvData = [];
    if (type == BusinessExportType.customers) {
      csvData.add(['Name', 'Phone', 'Email', 'Address', 'Pending Amount']);
      for (var item in data) {
        if (item == null) continue;
        csvData.add([
          (item['name'] ?? 'N/A').toString(),
          (item['phone'] ?? '').toString(),
          (item['email'] ?? '').toString(),
          (item['address'] ?? '').toString(),
          (item['pending_amount'] ?? '0.0').toString()
        ]);
      }
    } else {
      csvData.add(['Product Name', 'Description', 'Price', 'Stock', 'Unit']);
      for (var item in data) {
        if (item == null) continue;
        csvData.add([
          (item['name'] ?? 'N/A').toString(),
          (item['description'] ?? '').toString(),
          (item['price'] ?? '0.0').toString(),
          (item['stock_quantity'] ?? '0').toString(),
          (item['unit'] ?? 'pcs').toString()
        ]);
      }
    }

    String csvString = csvData
        .map((row) => row
            .map((cell) => '"${cell.toString().replaceAll('"', '""')}"')
            .join(','))
        .join('\n');
    
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${type.name}_export.csv');
    await file.writeAsString(csvString);
    return file.path;
  }

  // Share Sheet presentation phase
  static Future<void> showShareSheet(String filePath, BusinessExportType type) async {
    await Share.shareXFiles([XFile(filePath)], text: '${type.name.toUpperCase()} Export');
  }

  static List<List<String>> _getFormattedDataForPdf(BusinessExportType type, List data) {
    List<List<String>> result = [];
    if (type == BusinessExportType.customers) {
      result.add(['Name', 'Phone', 'Email', 'Pending']);
      for (var item in data) {
        if (item == null) continue;
        result.add([
          (item['name'] ?? 'N/A').toString(),
          (item['phone'] ?? '').toString(),
          (item['email'] ?? '').toString(),
          "Rs ${item['pending_amount'] ?? '0.0'}"
        ]);
      }
    } else {
      result.add(['Product', 'Price', 'Stock', 'Unit']);
      for (var item in data) {
        if (item == null) continue;
        result.add([
          (item['name'] ?? 'N/A').toString(),
          "Rs ${item['price'] ?? '0.0'}",
          (item['stock_quantity'] ?? '0').toString(),
          (item['unit'] ?? 'pcs').toString()
        ]);
      }
    }
    return result;
  }
}
