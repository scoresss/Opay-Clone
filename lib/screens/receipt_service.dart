import 'dart:typed_data';
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

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Opay Receipt',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 20),
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
