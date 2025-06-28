import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dashboard_screen.dart'; // Change this to your dashboard screen path

class LockScreen extends StatefulWidget {
  const LockScreen({Key? key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _checkIfPinExists();
  }

  Future<void> _checkIfPinExists() async {
    final pin = await _storage.read(key: 'user_pin');
    setState(() {
      _hasPin = pin != null;
    });
  }

  Future<void> _submitPin() async {
    final entered = _pinController.text;
    if (entered.length != 4) {
      _showMsg('Enter a 4-digit PIN');
      return;
    }

    final savedPin = await _storage.read(key: 'user_pin');
    if (savedPin == null) {
      // Set new PIN
      await _storage.write(key: 'user_pin', value: entered);
      _showMsg('PIN set. Welcome!');
      _goToDashboard();
    } else {
      if (entered == savedPin) {
        _goToDashboard();
      } else {
        _showMsg('Incorrect PIN');
      }
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        _showMsg('Biometric not available');
        return;
      }

      final success = await _localAuth.authenticate(
        localizedReason: 'Use fingerprint to unlock',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (success) _goToDashboard();
    } catch (e) {
      _showMsg('Biometric error: $e');
    }
  }

  Future<void> _resetPin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text('Authenticate with fingerprint to reset your PIN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );

    if (confirm == true) {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Fingerprint required to reset PIN',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuth) {
        final newPin = await _askNewPin();
        if (newPin != null && newPin.length == 4) {
          await _storage.write(key: 'user_pin', value: newPin);
          _showMsg('PIN reset successful!');
        }
      }
    }
  }

  Future<String?> _askNewPin() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter New PIN'),
        content: TextField(
          controller: controller,
          maxLength: 4,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New 4-digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  void _goToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                _hasPin ? 'Enter your PIN to unlock' : 'Create a 4-digit PIN',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                maxLength: 4,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter PIN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitPin,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock'),
              ),
              const SizedBox(height: 10),

              if (_hasPin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Fingerprint unlock',
                      icon: const Icon(Icons.fingerprint, size: 36),
                      onPressed: _authenticateBiometric,
                    ),
                    IconButton(
                      tooltip: 'Reset PIN',
                      icon: const Icon(Icons.refresh, size: 32),
                      onPressed: _resetPin,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
