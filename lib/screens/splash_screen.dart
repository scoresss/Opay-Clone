import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), _checkLogin);
  }

  void _checkLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.primary,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          const Text(
            'Opay Clone',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Secure Mobile Payments for Everyone',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 30),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    ),
  );
}
