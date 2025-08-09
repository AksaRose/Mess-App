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
        title: const Text('Choose Your Meal'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateSelector(context, selectionProvider),
            const SizedBox(height: 24),
            _buildMenuCard(context, selectionProvider),
            const SizedBox(height: 24),
            _buildMealChoiceToggle(context, selectionProvider),
            const SizedBox(height: 32),
            _buildSubmitButton(context, selectionProvider),
            const SizedBox(height: 16),
            _buildInfoSection(context, selectionProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
      BuildContext context, SelectionProvider selectionProvider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    final isAtStart = selectionProvider.selectedDate.isAtSameMomentAs(yesterday);
    final isAtEnd = selectionProvider.selectedDate.isAtSameMomentAs(tomorrow);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: isAtStart
              ? null
              : () {
                  final d = selectionProvider.selectedDate;
                  selectionProvider.setSelectedDate(d.subtract(const Duration(days: 1)));
                },
        ),
        Text(
          '${selectionProvider.selectedDate.year}-${selectionProvider.selectedDate.month.toString().padLeft(2, '0')}-${selectionProvider.selectedDate.day.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isAtEnd
              ? null
              : () {
                  final d = selectionProvider.selectedDate;
                  selectionProvider.setSelectedDate(d.add(const Duration(days: 1)));
                },
        ),
      ],
    );
  }

  Widget _buildMenuCard(
      BuildContext context, SelectionProvider selectionProvider) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu for the Day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            if (selectionProvider.selectedMenu.items.isEmpty)
              const Text('No menu available for this date.')
            else
              ...selectionProvider.selectedMenu.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.timeSlot, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Flexible(
                        child: Text(
                          'Veg: ${item.veg}\nNon-Veg: ${item.nonVeg}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealChoiceToggle(
      BuildContext context, SelectionProvider selectionProvider) {
    return ToggleButtons(
      isSelected: [
        selectionProvider.currentChoice == MealChoice.veg,
        selectionProvider.currentChoice == MealChoice.nonVeg,
      ],
      onPressed: (index) {
        if (selectionProvider.isSubmissionOpen) {
          selectionProvider.selectChoice(
              index == 0 ? MealChoice.veg : MealChoice.nonVeg);
        }
      },
      borderRadius: BorderRadius.circular(12),
      selectedColor: Colors.black,
      fillColor: Theme.of(context).colorScheme.secondary,
      color: Colors.white,
      children: const [
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text('Veg')),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text('Non-Veg')),
      ],
    );
  }

  Widget _buildSubmitButton(
      BuildContext context, SelectionProvider selectionProvider) {
    return FutureBuilder<bool>(
      future: selectionProvider.isChangeLimitReachedForSelectedDate(),
      builder: (context, snapshot) {
        final limitReached = snapshot.data == true;
        final isEnabled = selectionProvider.currentChoice != null &&
            selectionProvider.isSubmissionOpen &&
            !limitReached;

        return ElevatedButton.icon(
          icon: const Icon(Icons.playlist_add_check_circle_outlined),
          onPressed: !isEnabled
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
          label: Text(limitReached ? 'Change Limit Reached' : 'Confirm Selection'),
        );
      },
    );
  }

  Widget _buildInfoSection(
      BuildContext context, SelectionProvider selectionProvider) {
    return Column(
      children: [
        Text(
          'You can change your selection up to 3 times per day.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        FutureBuilder<String>(
          future:
              context.read<SelectionProvider>().plannedChoiceLabelForSelectedDate,
          builder: (context, snapshot) {
            final label = snapshot.data ?? 'Not Selected';
            return Text(
              "Your choice for this day: $label",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            );
          },
        ),
        const SizedBox(height: 16),
        if (selectionProvider.lastSubmittedAt != null)
          Text(
            'Last submission: ${selectionProvider.lastSubmittedAt}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
