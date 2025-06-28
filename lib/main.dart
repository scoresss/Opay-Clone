import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:opay/screens/splash_screen.dart';
import 'package:opay/screens/login_screen.dart';
import 'package:opay/screens/register_screen.dart';
import 'package:opay/screens/lock_screen.dart';
import 'package:opay/screens/dashboard_screen.dart';
import 'package:opay/screens/admin_dashboard_screen.dart';
import 'package:opay/services/role_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opay',
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
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            }
          }
        },
      ),
      routes: {
        '/register': (_) => const RegisterScreen(),
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/lock': (_) => const LockScreen(),
        '/admin_dashboard': (_) => const AdminDashboardScreen(),
      },
    );
  }
}
