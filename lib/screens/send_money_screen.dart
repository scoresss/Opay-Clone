import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

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
        final senderUid = FirebaseAuth.instance.currentUser!.uid;
        final receiverEmail = _receiverEmailController.text.trim();
        final amount = double.parse(_amountController.text.trim());

        // Look up receiver UID
        final usersRef = FirebaseFirestore.instance.collection('users');
        final query = await usersRef.where('email', isEqualTo: receiverEmail).get();

        if (query.docs.isEmpty) {
          Fluttertoast.showToast(msg: 'Receiver not found');
          return;
        }

        final receiverUid = query.docs.first.id;

        if (receiverUid == senderUid) {
          Fluttertoast.showToast(msg: 'Cannot send money to yourself');
          return;
        }

        // Use the service to perform transaction
        await FirestoreService().sendMoney(
          senderUid: senderUid,
          receiverUid: receiverUid,
          amount: amount,
        );

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
      appBar: AppBar(title: const Text('Send Money')),
      body: Padding(
        padding: const EdgeInsets.all(20),
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
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sendMoney,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Send'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
