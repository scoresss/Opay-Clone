import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../services/receipt_service.dart';
import '../utils/constants.dart';

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
                    final type = tx['type'] ?? 'transfer';

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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Save Receipt',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Save Receipt'),
                                        content: const Text('Do you want to save this receipt as PDF and PNG?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final pdfData =
                                          await ReceiptService.generateReceipt(
                                        title: title,
                                        amount: amount.toDouble(),
                                        date: date,
                                        type: type,
                                      );

                                      await ReceiptService.saveReceiptToFile(pdfData);
                                      await ReceiptService.saveReceiptAsImage(pdfData);

                                      Fluttertoast.showToast(
                                          msg: 'Saved to Download/OpayReceipts');
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  tooltip: 'Share Receipt',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Share Receipt'),
                                        content: const Text('Do you want to share the saved receipt image?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Share'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final now = DateFormat('yyyyMMdd_HHmmss')
                                          .format(DateTime.now());
                                      final filePath =
                                          '/storage/emulated/0/Download/OpayReceipts/receipt_$now.png';
                                      final file = File(filePath);

                                      if (await file.exists()) {
                                        await ReceiptService.shareReceiptImage(file);
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: 'Receipt not found. Please save it first.');
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['all', 'transfer', 'airtime', 'electricity'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: filters.map((type) {
          final isSelected = selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type[0].toUpperCase() + type.substring(1)),
              selected: isSelected,
              onSelected: (_) => setState(() => selectedType = type),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey.shade300,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredTransactions(String uid) {
    final base = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true);

    if (selectedType == 'all') {
      return base.snapshots();
    } else {
      return base.where('type', isEqualTo: selectedType).snapshots();
    }
  }
}
