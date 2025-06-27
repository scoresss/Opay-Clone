import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const OpayApp());
}

class OpayApp extends StatelessWidget {
  const OpayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opay Clone',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
