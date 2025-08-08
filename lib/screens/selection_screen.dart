import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/selection_provider.dart';
import 'confirmation_screen.dart';

class SelectionScreen extends StatelessWidget {
  static const String route = '/';
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectionProvider = context.watch<SelectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mess Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Choose your meal for tomorrow',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    final d = selectionProvider.selectedDate;
                    selectionProvider.setSelectedDate(
                      d.subtract(const Duration(days: 1)),
                    );
                  },
                  child: const Text('Prev'),
                ),
                const SizedBox(width: 8),
                Text(
                  '${selectionProvider.selectedDate.year}-${selectionProvider.selectedDate.month.toString().padLeft(2, '0')}-${selectionProvider.selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    final d = selectionProvider.selectedDate;
                    selectionProvider.setSelectedDate(
                      d.add(const Duration(days: 1)),
                    );
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
            if (!selectionProvider.isSubmissionOpen)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Submission closed for tomorrow. Opens again after midnight.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in selectionProvider.selectedMenu.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.timeSlot),
                            Flexible(
                              child: Text(
                                'Veg: ${item.veg}\nNon‑Veg: ${item.nonVeg}',
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ToggleButtons(
              isSelected: [
                selectionProvider.currentChoice == MealChoice.veg,
                selectionProvider.currentChoice == MealChoice.nonVeg,
              ],
              onPressed: (index) {
                if (index == 0) {
                  selectionProvider.selectChoice(MealChoice.veg);
                } else {
                  selectionProvider.selectChoice(MealChoice.nonVeg);
                }
              },
              borderRadius: BorderRadius.circular(12),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Veg'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Non-Veg'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FutureBuilder<bool>(
              future: selectionProvider.isChangeLimitReachedForSelectedDate(),
              builder: (context, snapshot) {
                final limitReached = snapshot.data == true;
                return ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
                  onPressed: selectionProvider.currentChoice == null ||
                          !selectionProvider.isSubmissionOpen ||
                          limitReached
                      ? null
                      : () async {
                          try {
                            await selectionProvider.submitChoice();
                            if (!context.mounted) return;
                            Navigator.pushNamed(context, ConfirmationScreen.route);
                          } catch (e) {
                            if (!context.mounted) return;
                            final msg = e.toString().contains('Change limit')
                                ? 'Change limit reached (max 3 per day)'
                                : 'Failed to submit: $e';
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                  label: Text(limitReached ? 'Limit reached (3 max)' : 'Submit Choice'),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'You can resubmit at most 3 times',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: context.read<SelectionProvider>().plannedChoiceLabelForSelectedDate,
              builder: (context, snapshot) {
                final label = snapshot.hasData ? snapshot.data : 'Non‑Veg';
                return Text(
                  "Tomorrow's Choice: ${label ?? 'Non‑Veg'}",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
            const Spacer(),
            if (selectionProvider.lastSubmittedAt != null)
              Text(
                'Last submitted: ${selectionProvider.lastSubmittedAt}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
          ],
        ),
      ),
    );
  }
}
