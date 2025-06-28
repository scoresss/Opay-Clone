import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int totalUsers = 0;
  int totalTransactions = 0;
  double totalReferralPayouts = 0;
  Map<String, int> referralCounts = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final allUsers = usersSnap.docs;
    totalUsers = allUsers.length;

    // Count referred users
    final referred = allUsers.where((doc) => doc.data()['referralUsed'] != null);
    for (var doc in referred) {
      final refBy = doc['referralUsed'];
      referralCounts[refBy] = (referralCounts[refBy] ?? 0) + 1;
    }

    int txCount = 0;
    double referralTotal = 0;

    for (var userDoc in allUsers) {
      final txs = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('transactions')
          .get();

      txCount += txs.size;
      for (var tx in txs.docs) {
        if (tx.data()['type'] == 'referral') {
          referralTotal += (tx.data()['amount'] ?? 0).toDouble();
        }
      }
    }

    setState(() {
      totalTransactions = txCount;
      totalReferralPayouts = referralTotal;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final topReferrers = referralCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Admin Analytics'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatTile('👤 Total Users', totalUsers.toString()),
          _buildStatTile('💸 Total Transactions', totalTransactions.toString()),
          _buildStatTile('💰 Referral Payouts', '₦${totalReferralPayouts.toStringAsFixed(2)}'),
          _buildStatTile(
            '👥 Referred Users',
            referralCounts.values.fold<int>(0, (a, b) => a + b).toString(),
          ),
          const SizedBox(height: 24),
          const Text('🥇 Top Referrers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          ...topReferrers.map((entry) => ListTile(
                title: Text('UID: ${entry.key}'),
                subtitle: Text('${entry.value} users referred'),
              )),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
