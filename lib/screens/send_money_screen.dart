import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final emailController = TextEditingController();
  final amountController = TextEditingController();
  bool loading = true;
  bool underMaintenance = false;

  @override
  void initState() {
    super.initState();
    _checkMaintenance();
  }

  Future<void> _checkMaintenance() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('maintenance')
        .get();

    setState(() {
      underMaintenance = doc.data()?['transfer'] == true;
      loading = false;
    });
  }

  Future<void> _sendMoney() async {
    final receiverEmail = emailController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;
    final sender = FirebaseAuth.instance.currentUser;

    if (receiverEmail.isEmpty || amount <= 0 || sender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid input')),
      );
      return;
    }

    try {
      final receiverQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: receiverEmail)
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receiver not found')),
        );
        return;
      }

      final senderDoc =
          FirebaseFirestore.instance.collection('users').doc(sender.uid);
      final receiverDoc = receiverQuery.docs.first.reference;

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final senderSnap = await txn.get(senderDoc);
        final receiverSnap = await txn.get(receiverDoc);

        final senderBal = (senderSnap.data()?['balance'] ?? 0).toDouble();
        if (senderBal < amount) {
          throw Exception('Insufficient balance');
        }

        txn.update(senderDoc, {'balance': senderBal - amount});
        txn.update(receiverDoc, {
          'balance': (receiverSnap.data()?['balance'] ?? 0) + amount,
        });

        final now = DateTime.now();
        final txId = 'TXN-${now.microsecondsSinceEpoch}';

        txn.set(
          senderDoc.collection('transactions').doc(),
          {
            'type': 'transfer',
            'to': receiverEmail,
            'amount': amount,
            'date': now,
            'status': 'success',
            'txnId': txId,
          },
        );

        txn.set(
          receiverDoc.collection('transactions').doc(),
          {
            'type': 'received',
            'from': sender.email,
            'amount': amount,
            'date': now,
            'status': 'success',
            'txnId': txId,
          },
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer successful')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (underMaintenance) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send Money')),
        body: const Center(
          child: Text(
            '⚠️ Transfer service is under maintenance.\nPlease try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
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
              onPressed: _sendMoney,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
