import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard.dart'; // ✅ User dashboard
import 'screens/admin_dashboard_screen.dart';
import 'screens/top_up_screen.dart';
import 'services/role_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const OpayApp());
}

class OpayApp extends StatefulWidget {
  const OpayApp({super.key});

  @override
  State<OpayApp> createState() => _OpayAppState();
}

class _OpayAppState extends State<OpayApp> with WidgetsBindingObserver {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _watchForceLogout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isLocked = true;
    }
  }

  void _watchForceLogout() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) async {
        if (doc.exists && doc.data()?['forceLogout'] == true) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'forceLogout': false});
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opay App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: SplashScreen(
        onFinish: (context) async {
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          } else if (_isLocked) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockScreen()));
            _isLocked = false;
          } else {
            final isAdmin = await RoleService.isAdmin();
            if (isAdmin) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
            }
          }
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/lock': (_) => const LockScreen(),
        '/dashboard': (_) => const Dashboard(),
        '/admin_dashboard': (_) => const AdminDashboardScreen(),
        '/topup': (_) => const TopUpScreen(),
        // Add others like airtime, electricity, send_money, history...
      },
    );
  }
}
