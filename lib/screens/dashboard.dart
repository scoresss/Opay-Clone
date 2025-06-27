import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opay Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Welcome to Opay!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildFeatureTile(
                context,
                icon: Icons.send,
                title: 'Send Money',
                route: '/send',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.phone_android,
                title: 'Buy Airtime',
                route: '/airtime',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.lightbulb_outline,
                title: 'Pay Electricity',
                route: '/electricity',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.history,
                title: 'Transactions',
                route: '/history',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.person,
                title: 'Profile',
                route: '/profile',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Admin',
                route: '/admin',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String route}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38, color: Colors.green),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
