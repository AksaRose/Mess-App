import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; // Import confetti package
import 'package:mess_app/screens/weekly_preference_screen.dart';
import 'package:mess_app/services/models.dart' as models;

import '../providers/selection_provider.dart';
import 'confirmation_screen.dart';

class SelectionScreen extends StatefulWidget {
  static const String route = '/';
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectionProvider = context.watch<SelectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Meal'),
        centerTitle: true,
      ),
      body: Stack(
        // Use Stack to overlay ConfettiWidget
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateSelector(context, selectionProvider),
                const SizedBox(height: 24),
                _buildMenuCard(context, selectionProvider),
                const SizedBox(height: 24),
                _buildSubmitButton(context, selectionProvider),
                const SizedBox(height: 16),
                _buildWeeklyChoiceButton(context),
                const SizedBox(height: 16),
                _buildInfoSection(context, selectionProvider),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, // don't specify a direction, blast randomly
            shouldLoop: false, // don't loop the animation
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ], // manually specify the colors to be used
            createParticlePath: (size) => Path(), // create a custom path for the particles
          ),
        ],
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

  Widget _buildSubmitButton(
      BuildContext context, SelectionProvider selectionProvider) {
    return ElevatedButton(
      onPressed: () {
        _showSubmissionWindow(context, selectionProvider);
      },
      child: const Text('Submit Your Choice'),
    );
  }

  void _showSubmissionWindow(
      BuildContext context, SelectionProvider selectionProvider) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Select Your Meal',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ToggleButtons(
                      isSelected: [
                        selectionProvider.currentChoice == models.MealChoice.veg,
                        selectionProvider.currentChoice == models.MealChoice.nonVeg,
                      ],
                      onPressed: (index) {
                        setState(() {
                          selectionProvider.selectChoice(
                              index == 0 ? models.MealChoice.veg : models.MealChoice.nonVeg);
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      selectedColor: Colors.black,
                      fillColor: Theme.of(context).colorScheme.secondary,
                      color: Colors.white,
                      children: const [
                        Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            child: Text('Veg')),
                        Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            child: Text('Non-Veg')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<bool>(
                      future: selectionProvider
                          .isChangeLimitReachedForSelectedDate(),
                      builder: (context, snapshot) {
                        final limitReached = snapshot.data == true;
                        final isEnabled =
                            selectionProvider.currentChoice != null &&
                                selectionProvider.isSubmissionOpen &&
                                !limitReached;
                        return ElevatedButton.icon(
                          icon: const Icon(
                              Icons.playlist_add_check_circle_outlined),
                          onPressed: !isEnabled
                              ? null
                              : () async {
                                  try {
                                    await selectionProvider.submitChoice();
                                    if (!context.mounted) return;
                                    Navigator.pop(context); // Close the modal
                                    _confettiController.play(); // Play confetti
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    final msg =
                                        e.toString().contains('Change limit')
                                            ? 'Change limit reached (max 3 per day)'
                                            : 'Failed to submit: $e';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(msg)));
                                  }
                                },
                          label: Text(limitReached
                              ? 'Change Limit Reached'
                              : 'Confirm Selection'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection(
      BuildContext context, SelectionProvider selectionProvider) {
    return Column(
      children: [
        Text(
          'You can change your selection up to 3 times per day.\nSubmissions are open from 12:00 PM to 10:00 PM.',
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

  Widget _buildWeeklyChoiceButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, WeeklyPreferenceScreen.route);
      },
      child: const Text('Weekly Choices'),
    );
  }
}
