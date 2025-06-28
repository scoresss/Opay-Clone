import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:printing/printing.dart';
import '../services/receipt_service.dart';
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String selectedType = 'all';
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredTransactions(uid!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data!.docs;

                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index].data() as Map<String, dynamic>;
                    final title = tx['title'] ?? 'Transaction';
                    final amount = tx['amount'] ?? 0;
                    final date = tx['date'] ?? '';

                    return Card(
  margin: const EdgeInsets.symmetric(vertical: 6),
  child: ListTile(
    title: Text(title),
    subtitle: Text(date),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '₦${amount.toString()}',
          style: TextStyle(
            color: amount >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Download Receipt',
          onPressed: () async {
            final pdfData = await ReceiptService.generateReceipt(
              title: title,
              amount: amount.toDouble(),
              date: date,
              type: tx['type'] ?? 'transfer',
            );
            await Printing.layoutPdf(onLayout: (format) async => pdfData);
          },
        ),
      ],
    ),
  ),
);
final pdfData = await ReceiptService.generateReceipt(
  title: tx['title'],
  amount: tx['amount'],
  date: tx['date'],
  type: tx['type'],
);

await ReceiptService.saveReceiptToFile(pdfData);
Fluttertoast.showToast(msg: 'Receipt saved to Downloads/OpayReceipts');

await Printing.layoutPdf(onLayout: (format) async => pdfData);
