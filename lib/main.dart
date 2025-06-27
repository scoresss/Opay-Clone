import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:opay_clone/screens/login_screen.dart';
import 'package:opay_clone/screens/dashboard.dart';
import 'package:opay_clone/screens/register_screen.dart';
import 'package:opay_clone/screens/admin_screen.dart';
import 'package:opay_clone/screens/send_money_screen.dart';
import 'package:opay_clone/screens/airtime_screen.dart';
import 'package:opay_clone/screens/electricity_screen.dart';
import 'package:opay_clone/screens/profile_screen.dart';
import 'package:opay_clone/screens/transaction_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(OpayApp());
}

class OpayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opay Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin': (context) => const AdminScreen(),
        '/send': (context) => const SendMoneyScreen(),
        '/airtime': (context) => const AirtimeScreen(),
        '/electricity': (context) => const ElectricityScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const TransactionHistoryScreen(),
      },
    );
  }
}
