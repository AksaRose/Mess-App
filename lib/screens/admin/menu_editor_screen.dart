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
      final batch = _db.batch();
      
      for (int i = 0; i < _weekdays.length; i++) {
        final dayKey = 'week_${i + 1}';
        final dayData = _menuData[dayKey] ?? {};
        
        final docRef = _db.collection('weeklyMenu').doc(dayKey);
        batch.set(docRef, {
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
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu saved successfully!')),
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

  void _updateMenu(String dayKey, String timeSlot, String type, String value) {
    setState(() {
      _menuData[dayKey] ??= {};
      _menuData[dayKey]![_getFieldKey(timeSlot, type)] = value;
    });
  }

  String _getFieldKey(String timeSlot, String type) {
    final slotKey = timeSlot.toLowerCase().replaceAll(' (4 pm)', '');
    return '${slotKey}${type == 'Veg' ? 'Veg' : 'NonVeg'}';
  }

  String _getFieldValue(String dayKey, String timeSlot, String type) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMenuData,
            tooltip: 'Save Menu',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (int i = 0; i < _weekdays.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weekdays[i],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final timeSlot in _timeSlots)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeSlot,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Veg',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(
                                    text: _getFieldValue('week_${i + 1}', timeSlot, 'Veg'),
                                  ),
                                  onChanged: (value) => _updateMenu(
                                    'week_${i + 1}',
                                    timeSlot,
                                    'Veg',
                                    value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Non-Veg',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(
                                    text: _getFieldValue('week_${i + 1}', timeSlot, 'NonVeg'),
                                  ),
                                  onChanged: (value) => _updateMenu(
                                    'week_${i + 1}',
                                    timeSlot,
                                    'NonVeg',
                                    value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
