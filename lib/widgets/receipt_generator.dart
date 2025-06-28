import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<Uint8List> generateReceiptPdf({
  required String userName,
  required double amount,
  required DateTime dateTime,
}) async {
  final pdf = pw.Document();

  // Generate dummy TXN ID
  final txnId = 'TXN-${Random().nextInt(999999).toString().padLeft(6, '0')}';
  final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Center(
          child: pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Opay Transaction Receipt',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Text('👤 Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(userName),
                pw.SizedBox(height: 12),

                pw.Text('💸 Amount:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('₦${amount.toStringAsFixed(2)}'),
                pw.SizedBox(height: 12),

                pw.Text('🧾 Transaction ID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(txnId),
                pw.SizedBox(height: 12),

                pw.Text('🕒 Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(formattedDate),
                pw.SizedBox(height: 24),

                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for using Opay!',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  return pdf.save();
}
