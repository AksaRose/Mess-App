import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/menu_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_editor_screen.dart';

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
      body: Center(
        child: FutureBuilder<AdminCounts>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final counts = snapshot.data!;
            final weekday = _weekdayNames[_date.weekday - 1];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Date: ${_date.year}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')} ($weekday) - Submissions from today'),
                const SizedBox(height: 8),
                _StatTile(label: 'Veg', value: counts.veg, color: Colors.green),
                const SizedBox(height: 12),
                _StatTile(label: 'Non‑Veg', value: counts.nonVeg, color: Colors.orange),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, MenuEditorScreen.route);
                  },
                  label: const Text('Edit Weekly Menu'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(backgroundColor: color, radius: 8),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 24),
            Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}


