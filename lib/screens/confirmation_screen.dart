import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/selection_provider.dart';

class ConfirmationScreen extends StatelessWidget {
  static const String route = '/confirmed';
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectionProvider = context.watch<SelectionProvider>();
    final choice = selectionProvider.currentChoice;
    final date = selectionProvider.selectedDate;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 96,
              color: choice == MealChoice.veg ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              choice == MealChoice.veg ? 'You are Veg' : 'You are Non‑Veg',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('For date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
            if (selectionProvider.lastConfirmedAt != null)
              Text('Confirmed at: ${selectionProvider.lastConfirmedAt}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
