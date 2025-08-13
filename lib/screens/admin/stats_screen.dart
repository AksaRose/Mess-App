import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/menu_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_editor_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminStatsScreen extends StatefulWidget {
  static const String route = '/admin/stats';
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final AdminService _service = AdminServiceFactory.create();
  late DateTime _date;
  Future<AdminCounts>? _future;
  final _weekdayNames = const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  @override
  void initState() {
    super.initState();
    _date = DateTime.now().add(const Duration(days: 1));
    _future = _service.getCountsForDate(_date);
  }

  void _reload() {
    setState(() {
      _future = _service.getCountsForDate(_date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomorrow\'s Counts'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // For now, just navigating to login
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: FutureBuilder<AdminCounts>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 100),
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading admin data...'),
                    ],
                  );
                }
                
                if (snapshot.hasError) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data:',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 100),
                      Icon(Icons.info_outline, size: 48, color: Colors.blue),
                      SizedBox(height: 16),
                      Text('No data available'),
                    ],
                  );
                }
                
                final counts = snapshot.data!;
                final weekday = _weekdayNames[_date.weekday - 1];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Date: ${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')} ($weekday)',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submissions from today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildUserListTile('Vegetarian', counts.veg, counts.vegUsers, Colors.green),
                    const SizedBox(height: 16),
                    _buildUserListTile('Non‑Vegetarian', counts.nonVeg, counts.nonVegUsers, Colors.orange),
                    if (counts.caffeineCounts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Caffeine Choices:',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ...counts.caffeineCounts.entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildUserListTile(
                            entry.key, 
                            entry.value, 
                            counts.caffeineUsers[entry.key] ?? [], 
                            Colors.brown
                          ),
                        )
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pushNamed(context, MenuEditorScreen.route);
                        },
                        label: const Text('Edit Weekly Menu'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserListTile(String label, int count, List<AdminUser> users, Color color) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: color, radius: 6),
        title: Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        children: users.isEmpty 
          ? [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No users selected this option',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            ]
          : users.map((user) => ListTile(
              dense: true,
              leading: const Icon(Icons.person, size: 20),
              title: Text(
                user.fullName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Admission: ${user.admissionNo} • Pass-out Year: ${user.passOutYear}',
                style: const TextStyle(fontSize: 12),
              ),
            )).toList(),
      ),
    );
  }
}


