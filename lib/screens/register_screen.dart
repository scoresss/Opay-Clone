import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  bool _loading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final referralCode = _referralController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      Fluttertoast.showToast(msg: 'All fields are required');
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final userCred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCred.user!.uid;
      double startingBalance = 0;

      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'balance': startingBalance,
        'createdAt': DateTime.now().toIso8601String(),
        'referralUsed': referralCode.isNotEmpty ? referralCode : null,
      };

      // Apply referral bonus if valid
      if (referralCode.isNotEmpty) {
        final refUser = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: referralCode)
            .get();

        if (refUser.docs.isNotEmpty && referralCode != uid) {
          // Reward referrer
          final refDoc = refUser.docs.first;
          final refBalance = refDoc.data()['balance'] ?? 0;
          final refId = refDoc.id;

          await FirebaseFirestore.instance.collection('users').doc(refId).update({
            'balance': refBalance + 100,
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(refId)
              .collection('transactions')
              .add({
            'title': 'Referral Bonus',
            'amount': 100,
            'type': 'referral',
            'status': 'success',
            'date': DateTime.now().toIso8601String(),
          });

          // Reward new user too
          startingBalance = 50;
          userData['balance'] = startingBalance;
        }
      }

      // Save new user
      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      Fluttertoast.showToast(msg: 'Registration successful!');

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referralController,
              decoration: const InputDecoration(
                labelText: 'Referral Code (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
