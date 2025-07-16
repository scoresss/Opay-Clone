import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final emailController = TextEditingController();
  final amountController = TextEditingController();
  bool loading = false;

  Future<void> _topUpBalance() async {
    final receiverEmail = emailController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final sender = FirebaseAuth.instance.currentUser;

    if (receiverEmail.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid email and amount')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final receiverQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: receiverEmail)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      final receiverRef = receiverQuery.docs.first.reference;
      final receiverData = receiverQuery.docs.first.data();
      final oldBalance = (receiverData['balance'] ?? 0).toDouble();
      final newBalance = oldBalance + amount;

      await receiverRef.update({'balance': newBalance});

      // Log the top-up transaction
      final txnId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      await receiverRef.collection('transactions').add({
        'type': 'topup',
        'from': sender?.email ?? 'Unknown',
        'amount': amount,
        'date': DateTime.now(),
        'status': 'success',
        'txnId': txnId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('₦$amount added to $receiverEmail')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top-Up Balance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Receiver Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : _topUpBalance,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Top-Up Now'),
            )
          ],
        ),
      ),
    );
  }
}
