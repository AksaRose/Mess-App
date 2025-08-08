import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/selection_provider.dart';
import 'selection_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String route = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mess App')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<String>(
              future: context.read<SelectionProvider>().todayChoiceLabel,
              builder: (context, snapshot) {
                final label = snapshot.hasData ? snapshot.data : 'Non‑Veg';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Today's Choice: ${label ?? 'Non‑Veg'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, SelectionScreen.route),
              icon: const Icon(Icons.restaurant_menu, size: 28),
              label: const Text('Submit Food Choice'),
            ),
            // Admin entry is now via normal login and role-based routing
          ],
        ),
      ),
    );
  }
}
