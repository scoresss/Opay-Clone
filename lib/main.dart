import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard.dart';
import 'screens/top_up_screen.dart';
import 'screens/send_money_screen.dart';
import 'screens/airtime_screen.dart';
import 'screens/electricity_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';

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
      title: 'Opay App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: SplashScreen(
        onFinish: (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/dashboard': (_) => const Dashboard(),
        '/topup': (_) => const TopUpScreen(),
        '/send_money': (_) => const SendMoneyScreen(),
        '/airtime': (_) => const AirtimeScreen(),
        '/electricity': (_) => const ElectricityScreen(),
        '/history': (_) => const TransactionHistoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
