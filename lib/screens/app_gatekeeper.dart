import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opay_clone/screens/maintenance_screen.dart'; // Your existing screen
import 'package:opay_clone/screens/lock_screen.dart';        // Continue flow normally if app is active

class AppGatekeeper extends StatelessWidget {
  const AppGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('app_settings')
          .doc('global')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong.')),
          );
        }

        if (snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final isDown = data?['maintenance'] ?? false;

          if (isDown == true) {
            return const MaintenanceScreen(); // 🔁 Using your existing screen
          } else {
            return const LockScreen(); // Proceed normally
          }
        }

        // Default fallback
        return const Scaffold(
          body: Center(child: Text('Unable to load app status')),
        );
      },
    );
  }
}
