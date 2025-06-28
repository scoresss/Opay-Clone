import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final meterController = TextEditingController();
  final amountController = TextEditingController();

  bool underMaintenance = false;
  bool loading = true;

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
      underMaintenance = doc.data()?['electricity'] == true;
      loading = false;
    });
  }

  Future<void> _submit() async {
    final meter = meterController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;

    if (meter.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid details')),
      );
      return;
    }

    // TODO: Deduct balance and log electricity purchase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Electricity token purchased!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (underMaintenance) {
      return Scaffold(
        appBar: AppBar(title: const Text('Electricity')),
        body: const Center(
          child: Text(
            '⚠️ Electricity service is under maintenance.\nPlease try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buy Electricity')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: meterController,
              decoration: const InputDecoration(labelText: 'Meter Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Buy Token'),
            )
          ],
        ),
      ),
    );
  }
}
