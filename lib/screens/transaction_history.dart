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

                final allTx = snapshot.data!.docs;

                if (allTx.isEmpty) {
                  return const Center(child: Text('No transactions found'));
                }

                final grouped = <String, List<QueryDocumentSnapshot>>{};
                for (var doc in allTx) {
                  final tx = doc.data() as Map<String, dynamic>;
                  final rawDate = tx['date'] ?? '';
                  final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(rawDate));
                  grouped[dateKey] = (grouped[dateKey] ?? [])..add(doc);
                }

                final sortedDates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final dateKey = sortedDates[index];
                    final docs = grouped[dateKey]!;
                    final header = DateFormat.yMMMMd().format(DateTime.parse(dateKey));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          header,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        ...docs.map((doc) => _buildTransactionTile(doc)).toList(),
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

  Widget _buildTransactionTile(QueryDocumentSnapshot doc) {
    final tx = doc.data() as Map<String, dynamic>;
    final title = tx['title'] ?? 'Transaction';
    final amount = tx['amount'] ?? 0;
    final date = tx['date'] ?? '';
    final type = tx['type'] ?? 'transfer';
    final status = tx['status'] ?? 'success';

    if (!title.toLowerCase().contains(searchQuery.toLowerCase()) &&
        !amount.toString().contains(searchQuery)) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () async {
        if (status == 'success') {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .doc(doc.id)
              .update({'status': 'failed'});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Marked as failed'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('transactions')
                      .doc(doc.id)
                      .update({'status': 'success'});
                  Fluttertoast.showToast(msg: 'Reverted to success');
                },
              ),
            ),
          );
        }
      },
      child: Card(
        color: status == 'failed' ? Colors.red.shade100 : null,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          title: Text(title),
          subtitle: Text('$type • Status: ${status.toUpperCase()}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₦$amount',
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
                      final confirm = await _showConfirmDialog('Save Receipt', 'Save this receipt as PDF and PNG?');
                      if (confirm == true) {
                        final pdf = await ReceiptService.generateReceipt(
                          title: title,
                          amount: amount.toDouble(),
                          date: date,
                          type: type,
                        );
                        await ReceiptService.saveReceiptToFile(pdf);
                        await ReceiptService.saveReceiptAsImage(pdf);
                        Fluttertoast.showToast(msg: 'Saved to Download/OpayReceipts');
                      }
                    },
                  ),
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
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Receipt',
                    onPressed: () async {
                      final confirm = await _showConfirmDialog('Share Receipt', 'Share saved receipt image?');
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
