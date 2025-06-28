import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int totalUsers = 0;
  double totalBalance = 0;
  int totalTransactions = 0;
  Map<String, int> typeBreakdown = {};

  int totalReferrals = 0;
  double totalReferralEarnings = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => loading = true);

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      totalUsers = usersSnapshot.docs.length;

      // Sum all balances
      totalBalance = 0;
      totalReferrals = 0;
      for (var doc in usersSnapshot.docs) {
        final balance = doc.data()['balance'] ?? 0;
        totalBalance += balance.toDouble();

        if (doc.data().containsKey('referralUsed')) {
          totalReferrals++;
        }
      }

      // Fetch all referral transactions and sum amount
      totalReferralEarnings = 0;
      final txs = await FirebaseFirestore.instance
          .collectionGroup('transactions')
          .where('type', isEqualTo: 'referral')
          .get();

      for (var tx in txs.docs) {
        final amount = tx.data()['amount'] ?? 0;
        totalReferralEarnings += amount.toDouble();
      }

      // Transaction counts by type
      final txSnapshots = await Future.wait(
        usersSnapshot.docs.map((userDoc) async {
          final txs = await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .collection('transactions')
              .get();
          return txs.docs;
        }),
      );

      totalTransactions = 0;
      typeBreakdown = {};
      for (var userTxs in txSnapshots) {
        totalTransactions += userTxs.length;
        for (var tx in userTxs) {
          final type = tx['type'] ?? 'other';
          typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
        }
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics'),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    '📊 Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildStatTile('👥 Total Users', '$totalUsers'),
                  _buildStatTile('💰 Total Balance in System', '₦${totalBalance.toStringAsFixed(2)}'),
                  _buildStatTile('🧾 Total Transactions', '$totalTransactions'),
                  const Divider(),

                  const SizedBox(height: 10),
                  const Text(
                    '🎁 Referral Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildStatTile('👥 Total Referred Users', '$totalReferrals'),
                  _buildStatTile('💸 Total Referral Rewards Paid', '₦${totalReferralEarnings.toStringAsFixed(2)}'),

                  const SizedBox(height: 20),
                  const Divider(),

                  const Text(
                    '📂 Transactions by Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...typeBreakdown.entries.map((entry) {
                    return ListTile(
                      leading: const Icon(Icons.analytics),
                      title: Text('${entry.key.toUpperCase()}'),
                      trailing: Text('${entry.value}'),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildStatTile(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
