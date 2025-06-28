import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  bool underMaintenance = false;
  bool loading = true;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

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
      underMaintenance = doc.data()?['airtime'] == true;
      loading = false;
    });
  }

  Future<void> _submit() async {
    final phone = phoneController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;

    if (phone.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid input')));
      return;
    }

    // TODO: Deduct balance, log transaction, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Airtime purchase successful')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (underMaintenance) {
      return Scaffold(
        appBar: AppBar(title: const Text('Airtime')),
        body: const Center(
          child: Text(
            '⚠️ Airtime service is under maintenance.\nPlease try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buy Airtime')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Buy Airtime'),
            )
          ],
        ),
      ),
    );
  }
}
