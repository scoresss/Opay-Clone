import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({Key? key}) : super(key: key);

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _receiverEmailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;

  Future<void> _sendMoney() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        final sender = FirebaseAuth.instance.currentUser!;
        final senderUid = sender.uid;
        final senderEmail = sender.email!;
        final receiverEmail = _receiverEmailController.text.trim();
        final amount = double.parse(_amountController.text.trim());

        // Find receiver
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: receiverEmail)
            .get();

        if (query.docs.isEmpty) {
          Fluttertoast.showToast(msg: 'Receiver not found');
          return;
        }

        final receiverDoc = query.docs.first;
        final receiverUid = receiverDoc.id;
        final receiverName = receiverDoc['name'];

        if (receiverUid == senderUid) {
          Fluttertoast.showToast(msg: 'Cannot send to yourself');
          return;
        }

        // Transfer
        await FirestoreService().sendMoney(
          senderUid: senderUid,
          receiverUid: receiverUid,
          amount: amount,
        );

        // Log for sender
        await FirestoreService().addTransaction(senderUid, {
          'title': 'Sent to $receiverName',
          'amount': -amount,
          'date': DateTime.now().toString(),
        });

        // Log for receiver
        await FirestoreService().addTransaction(receiverUid, {
          'title': 'Received from $senderEmail',
          'amount': amount,
          'date': DateTime.now().toString(),
        });

        Fluttertoast.showToast(msg: 'Money sent successfully!');
        _receiverEmailController.clear();
        _amountController.clear();
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: AppPadding.screen,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _receiverEmailController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter recipient email' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₦)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  if (double.tryParse(val) == null || double.parse(val) <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: 'Send',
                onPressed: _sendMoney,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
