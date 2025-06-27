import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _loading = false;

  Future<void> _topUpBalance() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        final email = _emailController.text.trim();
        final amount = double.parse(_amountController.text.trim());

        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (userQuery.docs.isEmpty) {
          Fluttertoast.showToast(msg: 'User not found');
          return;
        }

        final userDoc = userQuery.docs.first;
        final uid = userDoc.id;
        final name = userDoc['name'];
        final currentBalance = (userDoc['balance'] ?? 0).toDouble();
        final newBalance = currentBalance + amount;

        await FirestoreService().updateBalance(uid, newBalance);

        // Log top-up transaction
        await FirestoreService().addTransaction(uid, {
          'title': 'Top-up from Admin',
          'amount': amount,
          'date': DateTime.now().toString(),
        });

        Fluttertoast.showToast(msg: '₦$amount added to $name');
        _emailController.clear();
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
      appBar: AppBar(title: const Text('Admin Panel'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: AppPadding.screen,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'User Email',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount to Add',
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
              CustomButton(
                text: 'Top Up',
                onPressed: _topUpBalance,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
