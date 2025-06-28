import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();

  bool _resetMode = false;
  bool _loading = false;
  String? _storedPin;

  @override
  void initState() {
    super.initState();
    _loadStoredPin();
  }

  Future<void> _loadStoredPin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _storedPin = doc.data()?['pin'];
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text == _storedPin) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
    }
  }

  Future<void> _startReset() async {
    setState(() => _resetMode = true);
  }

  Future<void> _submitResetRequest() async {
    final email = _resetEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMsg('Email sent. Please check and reset your Firebase password.');

      // After confirming email, allow setting new PIN
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Set New PIN'),
          content: TextField(
            controller: _newPinController,
            decoration: const InputDecoration(labelText: 'New PIN'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && _newPinController.text.length >= 4) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'pin': _newPinController.text});
                  _showMsg('PIN updated successfully');
                  Navigator.pop(context);
                  setState(() => _resetMode = false);
                }
              },
              child: const Text('Save PIN'),
            )
          ],
        ),
      );
    } catch (e) {
      _showMsg('Error: ${e.toString()}');
    }

    setState(() => _loading = false);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔒 Locked'), backgroundColor: Colors.green),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _resetMode ? _buildResetForm() : _buildPinForm(),
        ),
      ),
    );
  }

  Widget _buildPinForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock, size: 60),
        const SizedBox(height: 20),
        TextField(
          controller: _pinController,
          decoration: const InputDecoration(labelText: 'Enter PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _verifyPin,
          child: const Text('Unlock'),
        ),
        TextButton(
          onPressed: _startReset,
          child: const Text('Forgot PIN?'),
        )
      ],
    );
  }

  Widget _buildResetForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.email, size: 60),
        const SizedBox(height: 20),
        TextField(
          controller: _resetEmailController,
          decoration: const InputDecoration(labelText: 'Enter your email'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _submitResetRequest,
          child: _loading ? const CircularProgressIndicator() : const Text('Send Reset Link'),
        ),
        TextButton(
          onPressed: () => setState(() => _resetMode = false),
          child: const Text('Back to PIN'),
        ),
      ],
    );
  }
}
