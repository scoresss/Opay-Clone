import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:opay_clone/screens/login_screen.dart';
import 'package:opay_clone/screens/register_screen.dart';
import 'package:opay_clone/screens/dashboard.dart';
import 'package:opay_clone/screens/send_money_screen.dart';
import 'package:opay_clone/screens/airtime_screen.dart';
import 'package:opay_clone/screens/electricity_screen.dart';
import 'package:opay_clone/screens/profile_screen.dart';
import 'package:opay_clone/screens/admin_screen.dart';
import 'package:opay_clone/screens/transaction_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OpayApp());
}

class OpayApp extends StatelessWidget {
  const OpayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opay Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: AuthGate(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/send': (context) => const SendMoneyScreen(),
        '/airtime': (context) => const AirtimeScreen(),
        '/electricity': (context) => const ElectricityScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const AdminScreen(),
        '/history': (context) => const TransactionHistoryScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const DashboardScreen(); // ✅ Authenticated user
        } else {
          return const LoginScreen(); // ❌ Not logged in
        }
      },
    );
  }
}
