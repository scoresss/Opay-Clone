import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/firestore_service.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({Key? key}) : super(key: key);

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;

  Future<void> _buyElectricity() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        final user = FirebaseAuth.instance.currentUser!;
        final uid = user.uid;
        final meter = _meterController.text.trim();
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
          'title': 'Electricity for meter $meter',
          'amount': -amount,
          'date': DateTime.now().toString(),
        });

        Fluttertoast.showToast(msg: '₦$amount paid for meter $meter');
        _meterController.clear();
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
      appBar: AppBar(title: const Text('Pay Electricity')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _meterController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meter Number',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.length < 5 ? 'Enter valid meter number' : null,
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
                      onPressed: _buyElectricity,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Pay Electricity'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
