import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptService {
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
    final image = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Image(image, height: 80), // ✅ Logo shown here
              ),
              pw.SizedBox(height: 20),
              pw.Text('Opay Receipt',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 16),
              pw.Text('Title: $title'),
              pw.Text('Amount: ₦${amount.toStringAsFixed(2)}'),
              pw.Text('Type: ${type[0].toUpperCase()}${type.substring(1)}'),
              pw.Text('Date: $date'),
              pw.SizedBox(height: 30),
              pw.Text('Thank you for using Opay Clone.'),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }
}
