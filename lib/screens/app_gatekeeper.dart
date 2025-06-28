// lib/screens/app_gatekeeper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:opay_clone/screens/app_maintenance_screen.dart';
import 'package:opay_clone/screens/lock_screen.dart';

class AppGatekeeper extends StatelessWidget {
  const AppGatekeeper({super.key});

  Future<bool> checkMaintenanceStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('maintenance')
          .get();

      return doc.exists && doc.data()?['enabled'] == true;
    } catch (e) {
      // Default to not under maintenance if error
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkMaintenanceStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const AppUnderMaintenanceScreen();
        } else {
          return const LockScreen(); // Or SplashScreen if you prefer
        }
      },
    );
  }
}
