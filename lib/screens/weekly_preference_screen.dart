import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/menu_service.dart';
import '../services/firebase_menu_service.dart';
import '../providers/selection_provider.dart';
import 'package:mess_app/services/models.dart' as models;

class WeeklyPreferenceScreen extends StatefulWidget {
  static const String route = '/weekly_preference';
  const WeeklyPreferenceScreen({super.key});

  @override
  State<WeeklyPreferenceScreen> createState() => _WeeklyPreferenceScreenState();
}

class _WeeklyPreferenceScreenState extends State<WeeklyPreferenceScreen> {
  DateTime? selectedDate;
  models.MealChoice selectedChoice = models.MealChoice.veg;

  @override
  void initState() {
    super.initState();
    // Set default to today
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Preferences'),
        centerTitle: true,
      ),
      body: Consumer<SelectionProvider>(
        builder: (context, selectionProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday Selection Section
                _buildWeekdaySelector(context),
                const SizedBox(height: 16),
                
                // Menu Display Section
                if (selectedDate != null) ...[
                  _buildMenuDisplay(context, selectedDate!),
                  const SizedBox(height: 16),
                  
                  // Meal Choice Selection
                  _buildMealChoiceSelector(context, selectionProvider),
                  const SizedBox(height: 16),
                  
                  // Submit Button
                  _buildSubmitButton(context, selectionProvider),
                  const SizedBox(height: 20), // Extra space at bottom for safety
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekdaySelector(BuildContext context) {
    final now = DateTime.now();
    final weekDates = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DateTime>(
              value: selectedDate,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Choose a day',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: weekDates.map((date) {
                return DropdownMenuItem<DateTime>(
                  value: date,
                  child: Text(
                    _getDayName(date.weekday),
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (DateTime? newDate) {
                setState(() {
                  selectedDate = newDate;
                  // Get the previously selected choice for this date from the provider
                  if (newDate != null) {
                    final provider = Provider.of<SelectionProvider>(context, listen: false);
                    final storedChoice = provider.weeklyChoices[newDate];
                    selectedChoice = storedChoice ?? models.MealChoice.veg;
                  } else {
                    selectedChoice = models.MealChoice.veg;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDisplay(BuildContext context, DateTime date) {
    final menuService = MenuServiceFactory.create();
    return FutureBuilder<DailyMenu>(
      future: (menuService as FirebaseMenuService).getMenuForAsync(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
          return const Text(
            'No menu available for this date.',
            style: TextStyle(fontStyle: FontStyle.italic),
          );
        }
        final menu = snapshot.data!;
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu for ${_getDayName(date.weekday)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                ...menu.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.timeSlot,
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      Flexible(
                        child: Text(
                          'Veg: ${item.veg}\nNon-Veg: ${item.nonVeg}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealChoiceSelector(BuildContext context, SelectionProvider selectionProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Your Meal Choice',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceButton(
                    context,
                    'Vegetarian',
                    Icons.eco,
                    Colors.green,
                    selectedChoice == models.MealChoice.veg,
                    () {
                      setState(() {
                        selectedChoice = models.MealChoice.veg;
                      });
                      if (selectedDate != null) {
                        selectionProvider.setWeeklyChoice(selectedDate!, models.MealChoice.veg);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChoiceButton(
                    context,
                    'Non-Vegetarian',
                    Icons.restaurant,
                    Colors.orange,
                    selectedChoice == models.MealChoice.nonVeg,
                    () {
                      setState(() {
                        selectedChoice = models.MealChoice.nonVeg;
                      });
                      if (selectedDate != null) {
                        selectionProvider.setWeeklyChoice(selectedDate!, models.MealChoice.nonVeg);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Caffeine (optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildCaffeineRow(context, selectionProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildCaffeineRow(BuildContext context, SelectionProvider selectionProvider) {
    final current = selectedDate != null ? selectionProvider.weeklyCaffeine[selectedDate!] : null;
    models.CaffeineChoice? selected = current;

    Widget caffeineBtn(String label, IconData icon, Color color, models.CaffeineChoice value) {
      final isSelected = selected == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              // toggle/deselect support
              if (selected == value) {
                selected = null;
              } else {
                selected = value;
              }
            });
            if (selectedDate != null) {
              selectionProvider.setWeeklyCaffeine(selectedDate!, selected);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: isSelected ? Colors.white : color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        caffeineBtn('Chaya', Icons.local_cafe, Colors.brown, models.CaffeineChoice.chaya),
        const SizedBox(width: 6),
        caffeineBtn('Kaapi', Icons.coffee, Colors.brown.shade700, models.CaffeineChoice.kaapi),
        const SizedBox(width: 6),
        caffeineBtn('Black Coffee', Icons.coffee_outlined, Colors.black87, models.CaffeineChoice.blackCoffee),
        const SizedBox(width: 6),
        caffeineBtn('Black Tea', Icons.emoji_food_beverage_outlined, Colors.teal, models.CaffeineChoice.blackTea),
      ],
    );
  }

  Widget _buildChoiceButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, SelectionProvider selectionProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedDate == null ? null : () async {
          try {
            await selectionProvider.submitSingleWeeklyChoice(selectedDate!, choice: selectedChoice);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Choice for ${_getDayName(selectedDate!.weekday)} submitted successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Reset choice after successful submission
            setState(() {
              selectedChoice = models.MealChoice.veg;
            });
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to submit: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Submit Choice for ${selectedDate != null ? _getDayName(selectedDate!.weekday) : 'Selected Day'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }
}