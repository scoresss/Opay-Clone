import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  String userName = '';
  String userEmail = '';
  int referralCount = 0;
  double referralEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadReferralStats();
  }

  Future<void> _loadUser() async {
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userName = doc.data()?['name'] ?? '';
        userEmail = doc.data()?['email'] ?? '';
      });
    }
  }

  Future<void> _loadReferralStats() async {
    if (uid == null) return;

    // Count referred users
    final referredUsers = await FirebaseFirestore.instance
        .collection('users')
        .where('referralUsed', isEqualTo: uid)
        .get();
    referralCount = referredUsers.size;

    // Calculate referral earnings
    final txs = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('type', isEqualTo: 'referral')
        .get();

    referralEarnings = 0;
    for (var tx in txs.docs) {
      referralEarnings += (tx.data()['amount'] ?? 0).toDouble();
    }

    setState(() {});
  }

  void _copyReferralCode() {
    if (uid != null) {
      Clipboard.setData(ClipboardData(text: uid!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code copied!')),
      );
    }
  }

  void _shareReferralCode() {
    if (uid != null) {
      final msg = 'Join this amazing app and get ₦50 bonus!\nUse my referral code: $uid';
      Share.share(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('You are not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.person, size: 100, color: Colors.green),
          const SizedBox(height: 10),
          Text(
            userName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            userEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          const Divider(),

          // 🎁 Referral Code
          const Text('Referral Code', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(uid!, style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyReferralCode,
                  tooltip: 'Copy code',
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareReferralCode,
                  tooltip: 'Share code',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),

          // 📊 Referral Stats
          const Text('Referral Summary', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('👥 Total Users Referred'),
              trailing: Text('$referralCount'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('💰 Total Referral Earnings'),
              trailing: Text('₦${referralEarnings.toStringAsFixed(2)}'),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),

          // 👥 Referred Users List
          const Text('Referred Users', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          _buildReferredUsersList(),
        ],
      ),
    );
  }

  Widget _buildReferredUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('referralUsed', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final referred = snapshot.data!.docs;

        if (referred.isEmpty) {
          return const Text('No users referred yet.');
        }

        return Column(
          children: referred.map((doc) {
            final name = doc['name'] ?? 'Unnamed';
            final joined = doc['createdAt'] ?? '';
            final formattedDate = DateFormat.yMMMMd().format(DateTime.parse(joined));

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(name),
              subtitle: Text('Joined: $formattedDate'),
            );
          }).toList(),
        );
      },
    );
  }
}
