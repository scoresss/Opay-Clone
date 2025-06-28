import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          '🚧 App Under Maintenance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
