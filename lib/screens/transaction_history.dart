import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../services/receipt_service.dart';
import '../screens/receipt_view_screen.dart';
import '../utils/constants.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String selectedType = 'all';
  String searchQuery = '';
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
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredTransactions(uid!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allTx = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .where((tx) {
                      final title = tx['title']?.toString().toLowerCase() ?? '';
                      final amount = tx['amount']?.toString() ?? '';
                      final query = searchQuery.toLowerCase();
                      return title.contains(query) || amount.contains(query);
                    })
                    .toList();

                if (allTx.isEmpty) {
                  return const Center(child: Text('No transactions found'));
                }

                // Group by date
                final grouped = <String, List<Map<String, dynamic>>>{};
                for (var tx in allTx) {
                  final rawDate = tx['date'] ?? '';
                  final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(rawDate));
                  grouped[date] = (grouped[date] ?? [])..add(tx);
                }

                final sortedDates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final dateKey = sortedDates[index];
                    final items = grouped[dateKey]!;
                    final formattedHeader = DateFormat.yMMMMd().format(DateTime.parse(dateKey));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedHeader,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...items.map((tx) => _buildTransactionTile(tx)).toList(),
                        const SizedBox(height: 12),
                      ],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search by title or amount...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final title = tx['title'] ?? 'Transaction';
    final amount = tx['amount'] ?? 0;
    final date = tx['date'] ?? '';
    final type = tx['type'] ?? 'transfer';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(type[0].toUpperCase() + type.substring(1)),
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
                // 📥 Save
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Save Receipt',
                  onPressed: () async {
                    final confirm = await _showConfirmDialog(
                      'Save Receipt', 'Save this receipt as PDF and PNG?',
                    );
                    if (confirm == true) {
                      final pdfData = await ReceiptService.generateReceipt(
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

                // 👁 View
                IconButton(
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View Receipt',
                  onPressed: () async {
                    final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                    final path = '/storage/emulated/0/Download/OpayReceipts/receipt_$now.png';
                    final file = File(path);

                    if (await file.exists()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptViewScreen(imagePath: path),
                        ),
                      );
                    } else {
                      Fluttertoast.showToast(msg: 'Receipt not found. Save it first.');
                    }
                  },
                ),

                // 📤 Share
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Receipt',
                  onPressed: () async {
                    final confirm = await _showConfirmDialog(
                      'Share Receipt', 'Share saved receipt image?',
                    );
                    if (confirm == true) {
                      final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                      final filePath = '/storage/emulated/0/Download/OpayReceipts/receipt_$now.png';
                      final file = File(filePath);

                      if (await file.exists()) {
                        await ReceiptService.shareReceiptImage(file);
                      } else {
                        Fluttertoast.showToast(msg: 'Receipt not found. Save it first.');
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

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredTransactions(String uid) {
    final base = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true);

    return selectedType == 'all'
        ? base.snapshots()
        : base.where('type', isEqualTo: selectedType).snapshots();
  }
}
