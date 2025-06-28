import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool maintenanceGlobal = false;
  bool airtimeOff = false;
  bool electricityOff = false;
  bool transferOff = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceSettings();
  }

  Future<void> _loadMaintenanceSettings() async {
    final globalDoc = await FirebaseFirestore.instance.collection('app_settings').doc('global').get();
    final featureDoc = await FirebaseFirestore.instance.collection('app_settings').doc('maintenance').get();

    setState(() {
      maintenanceGlobal = globalDoc.data()?['maintenance'] ?? false;
      airtimeOff = featureDoc.data()?['airtime'] ?? false;
      electricityOff = featureDoc.data()?['electricity'] ?? false;
      transferOff = featureDoc.data()?['transfer'] ?? false;
      loading = false;
    });
  }

  Future<void> _toggleGlobal(bool value) async {
    await FirebaseFirestore.instance.collection('app_settings').doc('global').set({
      'maintenance': value
    }, SetOptions(merge: true));

    setState(() => maintenanceGlobal = value);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value ? '🔴 App globally disabled' : '🟢 App enabled'),
    ));
  }

  Future<void> _toggleFeature(String feature, bool value) async {
    await FirebaseFirestore.instance.collection('app_settings').doc('maintenance').set({
      feature: value
    }, SetOptions(merge: true));

    setState(() {
      if (feature == 'airtime') airtimeOff = value;
      if (feature == 'electricity') electricityOff = value;
      if (feature == 'transfer') transferOff = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value ? '$feature feature disabled' : '$feature feature enabled'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), backgroundColor: Colors.green),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('🛠 Global Maintenance'),
            value: maintenanceGlobal,
            onChanged: _toggleGlobal,
          ),
          const Divider(),
          const Text('Per-Feature Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('📲 Airtime'),
            subtitle: const Text('Disable Airtime purchase'),
            value: airtimeOff,
            onChanged: (v) => _toggleFeature('airtime', v),
          ),
          SwitchListTile(
            title: const Text('💡 Electricity'),
            subtitle: const Text('Disable Electricity service'),
            value: electricityOff,
            onChanged: (v) => _toggleFeature('electricity', v),
          ),
          SwitchListTile(
            title: const Text('💸 Transfers'),
            subtitle: const Text('Disable money transfers'),
            value: transferOff,
            onChanged: (v) => _toggleFeature('transfer', v),
          ),
          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Top-Up User Balance'),
            onTap: () => Navigator.pushNamed(context, '/admin'),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Admin Analytics'),
            onTap: () => Navigator.pushNamed(context, '/admin_analytics'),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Transaction History'),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          const Divider(height: 30),
          const Text('🛠 Remote Logout User', style: TextStyle(fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Force Logout User by Email'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ForceLogoutDialog(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🔄 Popup to Force Logout User
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }

      await query.docs.first.reference.set({'forceLogout': true}, SetOptions(merge: true));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout command sent to user')),
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
