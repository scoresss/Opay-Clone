import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class ReceiptService {
  static Future<Uint8List> generateReceipt({
    required String title,
    required double amount,
    required String date,
    required String type,
  }) async {
    final pdf = pw.Document();

    // Load your logo
    final ByteData logoData = await rootBundle.load('assets/logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Stack(
          children: [
            // ✅ Watermark (faint Opay)
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

            // ✅ Main receipt content
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
}
