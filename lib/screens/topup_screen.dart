import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'wallet'; // or 'card'
  bool _loading = false;

  final user = FirebaseAuth.instance.currentUser;

  void _submitTopUp() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      Fluttertoast.showToast(msg: 'Enter a valid amount');
      return;
    }

    if (user == null) {
      Fluttertoast.showToast(msg: 'User not logged in');
      return;
    }

    setState(() => _loading = true);

    final uid = user.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final snapshot = await userDoc.get();
      final currentBalance = snapshot.data()?['balance'] ?? 0;

      final newBalance = currentBalance + amount;

      await userDoc.update({'balance': newBalance});

      await userDoc.collection('transactions').add({
        'title': 'Top Up via $_selectedMethod',
        'amount': amount,
        'type': 'topup',
        'method': _selectedMethod,
        'status': 'success',
        'date': DateTime.now().toIso8601String(),
      });

      Fluttertoast.showToast(msg: 'Top-up successful!');
      _amountController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Enter Amount', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '₦0.00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choose Method', style: TextStyle(fontSize: 16)),
            ListTile(
              title: const Text('Wallet'),
              leading: Radio<String>(
                value: 'wallet',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
              ),
            ),
            ListTile(
              title: const Text('Card'),
              leading: Radio<String>(
                value: 'card',
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submitTopUp,
              icon: const Icon(Icons.arrow_upward),
              label: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Top Up'),
            ),
          ],
        ),
      ),
    );
  }
}
