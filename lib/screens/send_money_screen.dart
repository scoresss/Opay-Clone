import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({Key? key}) : super(key: key);

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = false;

  Future<void> _sendMoney() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    final senderEmail = currentUser?.email;
    final receiverEmail = _emailController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (senderEmail == receiverEmail) {
      Fluttertoast.showToast(msg: "You can't send money to yourself.");
      setState(() => _loading = false);
      return;
    }

    try {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final senderData = senderDoc.data()!;
      final senderBalance = (senderData['balance'] ?? 0).toDouble();

      if (senderBalance < amount) {
        Fluttertoast.showToast(msg: "Insufficient balance.");
        return;
      }

      final receiverQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: receiverEmail)
          .get();

      if (receiverQuery.docs.isEmpty) {
        Fluttertoast.showToast(msg: "Receiver not found.");
        return;
      }

      final receiverDoc = receiverQuery.docs.first;
      final receiverId = receiverDoc.id;
      final receiverData = receiverDoc.data();
      final receiverBalance = (receiverData['balance'] ?? 0).toDouble();

      // Update balances
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'balance': senderBalance - amount});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .update({'balance': receiverBalance + amount});

      // Log transaction
      await FirebaseFirestore.instance.collection('transactions').add({
        'from': senderEmail,
        'to': receiverEmail,
        'amount': amount,
        'type': 'transfer',
        'timestamp': Timestamp.now(),
      });

      // 🔔 Push Notification
      await NotificationService.sendPushNotification(
        title: 'Money Sent',
        body: 'You sent ₦$amount to $receiverEmail',
      );

      Fluttertoast.showToast(msg: "Transfer successful!");
      _emailController.clear();
      _amountController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Money")),
      body: Padding(
        padding: defaultPadding,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Receiver Email'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter amount' : null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _loading ? 'Sending...' : 'Send',
                onPressed: _loading ? null : _sendMoney,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
