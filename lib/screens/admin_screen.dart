import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_settings')
            .doc('global')
            .snapshots(),
        builder: (context, snapshot) {
          final isDown = snapshot.data?.get('maintenance') ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDown)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⚠ The app is currently in Maintenance Mode!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 🔄 Maintenance toggle
                _buildMaintenanceToggle(isDown),
                const Divider(),

                // 💰 Top-up section
                const SizedBox(height: 10),
                const Text('Top Up User Balance', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User UID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _topUpBalance,
                  icon: const Icon(Icons.add),
                  label: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Balance'),
                ),

                const SizedBox(height: 30),
                // 📊 Analytics Button
                ListTile(
                  leading: const Icon(Icons.pie_chart),
                  title: const Text('View Analytics'),
                  onTap: () {
                    Navigator.pushNamed(context, '/analytics');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceToggle(bool currentStatus) {
    return SwitchListTile(
      title: const Text('🛠 App Maintenance Mode'),
      subtitle: const Text('Disable app for all users remotely'),
      value: currentStatus,
      onChanged: (value) async {
        await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('global')
            .set({'maintenance': value}, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            value
                ? 'App is now in maintenance mode!'
                : 'App is now active for all users!',
          ),
        ));
      },
    );
  }

  Future<void> _topUpBalance() async {
    final uid = _userIdController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (uid.isEmpty || amount == null) {
      _showMsg('Please enter valid UID and amount');
      return;
    }

    setState(() => _loading = true);

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final userSnap = await userDoc.get();

      if (!userSnap.exists) {
        _showMsg('User not found');
        setState(() => _loading = false);
        return;
      }

      final currentBalance = userSnap.data()?['balance'] ?? 0;
      final newBalance = currentBalance + amount;

      await userDoc.update({'balance': newBalance});

      await userDoc.collection('transactions').add({
        'title': 'Admin Top Up',
        'amount': amount,
        'type': 'admin',
        'status': 'success',
        'date': DateTime.now().toIso8601String(),
      });

      _showMsg('Balance updated successfully!');
      _amountController.clear();
      _userIdController.clear();
    } catch (e) {
      _showMsg('Error: ${e.toString()}');
    }

    setState(() => _loading = false);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
