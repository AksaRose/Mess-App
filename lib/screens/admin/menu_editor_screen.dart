import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuEditorScreen extends StatefulWidget {
  static const String route = '/admin/menu-editor';
  const MenuEditorScreen({super.key});

  @override
  State<MenuEditorScreen> createState() => _MenuEditorScreenState();
}

class _MenuEditorScreenState extends State<MenuEditorScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final _timeSlots = ['Breakfast', 'Lunch', 'Snacks (4 PM)', 'Dinner'];
  
  Map<String, Map<String, String>> _menuData = {};
  bool _loading = true;
  String _selectedWeekday = 'Monday';
  int _selectedWeekdayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    setState(() => _loading = true);
    try {
      final snapshot = await _db.collection('weeklyMenu').get();
      final data = <String, Map<String, String>>{};
      
      for (final doc in snapshot.docs) {
        final docData = doc.data();
        data[doc.id] = {
          'breakfastVeg': docData['breakfastVeg'] ?? '',
          'breakfastNonVeg': docData['breakfastNonVeg'] ?? '',
          'lunchVeg': docData['lunchVeg'] ?? '',
          'lunchNonVeg': docData['lunchNonVeg'] ?? '',
          'snacksVeg': docData['snacksVeg'] ?? '',
          'snacksNonVeg': docData['snacksNonVeg'] ?? '',
          'dinnerVeg': docData['dinnerVeg'] ?? '',
          'dinnerNonVeg': docData['dinnerNonVeg'] ?? '',
        };
      }
      
      setState(() {
        _menuData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load menu: $e')),
        );
      }
    }
  }

  Future<void> _saveMenuData() async {
    try {
      // Save only the selected weekday
      final dayKey = 'week_${_selectedWeekdayIndex + 1}';
      final dayData = _menuData[dayKey] ?? {};
      
      final docRef = _db.collection('weeklyMenu').doc(dayKey);
      await docRef.set({
        'breakfastVeg': dayData['breakfastVeg'] ?? '',
        'breakfastNonVeg': dayData['breakfastNonVeg'] ?? '',
        'lunchVeg': dayData['lunchVeg'] ?? '',
        'lunchNonVeg': dayData['lunchNonVeg'] ?? '',
        'snacksVeg': dayData['snacksVeg'] ?? '',
        'snacksNonVeg': dayData['snacksNonVeg'] ?? '',
        'dinnerVeg': dayData['dinnerVeg'] ?? '',
        'dinnerNonVeg': dayData['dinnerNonVeg'] ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu for $_selectedWeekday saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save menu: $e')),
        );
      }
    }
  }

  void _updateMenu(String timeSlot, String type, String value) {
    setState(() {
      final dayKey = 'week_${_selectedWeekdayIndex + 1}';
      _menuData[dayKey] ??= {};
      _menuData[dayKey]![_getFieldKey(timeSlot, type)] = value;
    });
  }

  String _getFieldKey(String timeSlot, String type) {
    final slotKey = timeSlot.toLowerCase().replaceAll(' (4 pm)', '');
    return '${slotKey}${type == 'Veg' ? 'Veg' : 'NonVeg'}';
  }

  String _getFieldValue(String timeSlot, String type) {
    final dayKey = 'week_${_selectedWeekdayIndex + 1}';
    final fieldKey = _getFieldKey(timeSlot, type);
    return _menuData[dayKey]?[fieldKey] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Weekly Menu')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Weekly Menu'),
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday Selector
            Card(
              margin: const EdgeInsets.only(bottom: 8.0), // Reduced margin
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Use minimum space
                  children: [
                    Text(
                      'Select Weekday',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith( // Smaller title
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8), // Reduced SizedBox
                    DropdownButtonFormField<String>(
                      value: _selectedWeekday,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Choose a weekday',
                        isDense: true, // Make it dense
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact padding
                      ),
                      items: _weekdays.asMap().entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedWeekday = newValue;
                            _selectedWeekdayIndex = _weekdays.indexOf(newValue);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Menu Editor for Selected Day - Use Expanded to take available space
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: Theme.of(context).primaryColor,
                            size: 20, // Smaller icon
                          ),
                          const SizedBox(width: 4), // Reduced SizedBox
                          Text(
                            'Menu for $_selectedWeekday',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith( // Smaller title
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), // Reduced SizedBox
                      
                      // Time Slot Fields - Use ListView.builder for efficient rendering
                      Expanded(
                        child: ListView.builder(
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final timeSlot = _timeSlots[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0), // Reduced padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    timeSlot,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14, // Smaller font size
                                    ),
                                  ),
                                  const SizedBox(height: 4), // Reduced SizedBox
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMenuTextField(
                                          timeSlot,
                                          'Veg',
                                        ),
                                      ),
                                      const SizedBox(width: 8), // Reduced SizedBox
                                      Expanded(
                                        child: _buildMenuTextField(
                                          timeSlot,
                                          'NonVeg',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveMenuData,
                          icon: const Icon(Icons.save),
                          label: Text('Save Menu for $_selectedWeekday'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                            textStyle: const TextStyle(fontSize: 14), // Smaller font size
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMenuTextField(String timeSlot, String type) {
    final dayKey = 'week_${_selectedWeekdayIndex + 1}';
    final fieldKey = _getFieldKey(timeSlot, type);
    final controller = TextEditingController(text: _menuData[dayKey]?[fieldKey] ?? '');
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: type == 'Veg' ? 'Veg' : 'Non-Veg',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      onChanged: (value) => _updateMenu(timeSlot, type, value),
    );
  }
}
