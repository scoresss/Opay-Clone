import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ReceiptService {
  /// ✅ Generate PDF Receipt styled like Opay
  static Future<Uint8List> generateReceipt({
    required String title,
    required double amount,
    required String date,
    required String type,
  }) async {
    final pdf = pw.Document();

    // Load logo from assets
    final ByteData logoData = await rootBundle.load('assets/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final String ref = DateFormat('yyyyMMddHHmmss').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Stack(
          children: [
            // ✅ Watermark
            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: 0.06,
                child: pw.Center(
                  child: pw.Text(
                    'Opay',
                    style: pw.TextStyle(
                      fontSize: 100,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ✅ Main content
            pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Image(logoImage, height: 60)),
                  pw.SizedBox(height: 20),

                  pw.Text(
                    'Transaction Receipt',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _labelRow('Title', title),
                        _labelRow(
                          'Amount',
                          '₦${amount.toStringAsFixed(2)}',
                          valueColor: amount >= 0 ? PdfColors.green800 : PdfColors.red,
                        ),
                        _labelRow('Type', type[0].toUpperCase() + type.substring(1)),
                        _labelRow('Date', date),
                        _labelRow('Reference ID', ref),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 30),
                  pw.Center(
                    child: pw.Text(
                      'Thank you for using Opay Clone',
                      style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// ✅ Save PDF to Downloads folder
  static Future<void> saveReceiptToFile(Uint8List pdfData) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception("Storage permission not granted");
    }

    final directory = Directory('/storage/emulated/0/Download/OpayReceipts');
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/receipt_$now.pdf';

    final file = File(filePath);
    await file.writeAsBytes(pdfData);

    print("✅ Receipt saved to: $filePath");
  }

  /// 🧱 Reusable row builder for layout
  static pw.Widget _labelRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 100, child: pw.Text('$label:')),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: valueColor ?? PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
