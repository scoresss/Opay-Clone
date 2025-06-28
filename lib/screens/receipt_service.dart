import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ReceiptService {
  /// ✅ Generate PDF Receipt with logo + watermark
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

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Stack(
          children: [
            // Watermark
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

            // Main content
            pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Image(logoImage, height: 80)),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Transaction Receipt',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text('Title: $title'),
                  pw.Text('Amount: ₦${amount.toStringAsFixed(2)}'),
                  pw.Text('Type: ${type[0].toUpperCase()}${type.substring(1)}'),
                  pw.Text('Date: $date'),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Thank you for using Opay Clone.',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
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

  /// ✅ Save generated PDF to Downloads folder
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
}
