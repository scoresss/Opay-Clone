import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool maintenanceMode = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceStatus();
  }

  Future<void> _loadMaintenanceStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('global')
        .get();
    setState(() {
      maintenanceMode = doc.data()?['maintenance'] ?? false;
      loading = false;
    });
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => maintenanceMode = value);
    await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('global')
        .set({'maintenance': value}, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? 'App disabled' : 'App enabled')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('🛠 App Maintenance Mode'),
            subtitle: const Text('Globally disable app for all users'),
            value: maintenanceMode,
            onChanged: _toggleMaintenance,
          ),
          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Top-Up User Balance'),
            onTap: () => Navigator.pushNamed(context, '/admin'),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('View Analytics'),
            onTap: () => Navigator.pushNamed(context, '/analytics'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Transaction History'),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
    );
  }
}
