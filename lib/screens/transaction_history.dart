import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  final List<Map<String, dynamic>> mockTransactions = const [
    {
      'title': 'Airtime Purchase',
      'amount': '-₦500',
      'date': 'June 22, 2025',
    },
    {
      'title': 'Money Received',
      'amount': '+₦2,000',
      'date': 'June 21, 2025',
    },
    {
      'title': 'Electricity Bill',
      'amount': '-₦3,000',
      'date': 'June 19, 2025',
    },
    {
      'title': 'Money Sent',
      'amount': '-₦1,500',
      'date': 'June 17, 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 16),
        itemBuilder: (context, index) {
          final transaction = mockTransactions[index];
          final isCredit = transaction['amount'].toString().startsWith('+');

          return ListTile(
            leading: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
            ),
            title: Text(transaction['title']),
            subtitle: Text(transaction['date']),
            trailing: Text(
              transaction['amount'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}
