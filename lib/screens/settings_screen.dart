import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isAdmin = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        isAdmin = (doc.data()?['role'] ?? 'user') == 'admin';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.green),
      body: ListView(
        children: [
          if (isAdmin) const Divider(),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Dashboard'),
              onTap: () => Navigator.pushNamed(context, '/admin_dashboard'),
            ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Force Logout a User'),
              onTap: () => showDialog(
                context: context,
                builder: (_) => const ForceLogoutDialog(),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

// 🔐 Admin Remote Logout Dialog
class ForceLogoutDialog extends StatefulWidget {
  const ForceLogoutDialog({super.key});

  @override
  State<ForceLogoutDialog> createState() => _ForceLogoutDialogState();
}

class _ForceLogoutDialogState extends State<ForceLogoutDialog> {
  final emailController = TextEditingController();
  bool loading = false;

  Future<void> forceLogout() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => loading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      await query.docs.first.reference.set({'forceLogout': true}, SetOptions(merge: true));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout command sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Force Logout User'),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(labelText: 'Enter user email'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: loading ? null : forceLogout,
          child: loading ? const CircularProgressIndicator() : const Text('Logout'),
        ),
      ],
    );
  }
}
