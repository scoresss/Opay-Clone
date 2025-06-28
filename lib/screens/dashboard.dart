import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String userName = '';
  String userEmail = '';
  String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        userName = data['name'] ?? '';
        userEmail = data['email'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    final txStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('👋 Welcome, $userName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(userEmail, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 24),
          StreamBuilder<DocumentSnapshot>(
            stream: balanceStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final balance = (snapshot.data!.data() as Map)['balance'] ?? 0.0;
              return Card(
                color: Colors.green.shade100,
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Current Balance'),
                  subtitle: Text('₦${balance.toStringAsFixed(2)}'),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text('⚡ Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionCard(context, Icons.send, 'Send Money', '/send_money'),
              _actionCard(context, Icons.phone_android, 'Airtime', '/airtime'),
              _actionCard(context, Icons.flash_on, 'Electricity', '/electricity'),
              _actionCard(context, Icons.account_balance_wallet, 'Top-Up', '/topup'),
              _actionCard(context, Icons.history, 'History', '/history'),
            ],
          ),

          const SizedBox(height: 32),
          const Text('🧾 Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot>(
            stream: txStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final txs = snapshot.data!.docs;

              if (txs.isEmpty) {
                return const Text('No recent transactions');
              }

              return Column(
                children: txs.map((tx) {
                  final data = tx.data() as Map;
                  final type = data['type'];
                  final amount = data['amount'];
                  final date = (data['date'] as Timestamp).toDate();
                  return ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text('$type - ₦$amount'),
                    subtitle: Text(date.toString()),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: SizedBox(
        width: 100,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, size: 32, color: Colors.green),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
