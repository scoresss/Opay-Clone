import 'package:flutter/material.dart';
import 'package:opay_clone/screens/login_screen.dart';
import 'package:opay_clone/screens/dashboard.dart';
import 'package:opay_clone/screens/register_screen.dart';
import 'package:opay_clone/screens/admin_screen.dart';
import 'package:opay_clone/screens/send_money_screen.dart';
import 'package:opay_clone/screens/airtime_screen.dart';
import 'package:opay_clone/screens/electricity_screen.dart';
import 'package:opay_clone/screens/profile_screen.dart';
import 'package:opay_clone/screens/transaction_history.dart';

void main() {
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
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/admin': (context) => AdminScreen(),
        '/send-money': (context) => SendMoneyScreen(),
        '/airtime': (context) => AirtimeScreen(),
        '/electricity': (context) => ElectricityScreen(),
        '/profile': (context) => ProfileScreen(),
        '/history': (context) => TransactionHistoryScreen(),
      },
    );
  }
}
