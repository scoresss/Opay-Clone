import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/firestore_service.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({Key? key}) : super(key: key);

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;

  Future<void> _buyAirtime() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        final user = FirebaseAuth.instance.currentUser!;
        final uid = user.uid;
        final phone = _phoneController.text.trim();
        final amount = double.parse(_amountController.text.trim());

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        double balance = (doc['balance'] ?? 0).toDouble();

        if (balance < amount) {
          Fluttertoast.showToast(msg: 'Insufficient balance');
          return;
        }

        final newBalance = balance - amount;

        await FirestoreService().updateBalance(uid, newBalance);

        await FirestoreService().addTransaction(uid, {
          'title': 'Airtime to $phone',
          'amount': -amount,
          'date': DateTime.now().toString(),
        });

        Fluttertoast.showToast(msg: '₦$amount airtime bought for $phone');
        _phoneController.clear();
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
      appBar: AppBar(title: const Text('Buy Airtime')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.length < 11 ? 'Enter valid phone number' : null,
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
                    return 'Enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _buyAirtime,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Buy Airtime'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
