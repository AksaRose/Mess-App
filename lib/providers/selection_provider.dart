import 'package:flutter/foundation.dart';

import '../services/backend.dart';
import '../services/backend_factory.dart';
import '../services/models.dart';
import '../services/menu_service.dart';

enum MealChoice { veg, nonVeg }

class SelectionProvider extends ChangeNotifier {
  final Backend _backend = BackendFactory.create();
  final MenuService _menuService = MenuService();

  MealChoice? _currentChoice;
  DateTime? _lastSubmittedAt;
  DateTime? _lastConfirmedAt;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  MealChoice? get currentChoice => _currentChoice;
  DateTime? get lastSubmittedAt => _lastSubmittedAt;
  DateTime? get lastConfirmedAt => _lastConfirmedAt;
  DateTime get selectedDate => _selectedDate;
  DailyMenu get selectedMenu => _menuService.getMenuFor(_selectedDate);
  DailyMenu get todayMenu => _menuService.getMenuFor(DateTime.now());
  DailyMenu get tomorrowMenu => _menuService.getMenuFor(DateTime.now().add(const Duration(days: 1)));
  Future<String> get yesterdayChoiceLabel async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final choice = await _backend.getChoiceForDate(yesterday);
    return (choice == 'veg') ? 'Veg' : 'Non‑Veg';
  }

  Future<String> get todayChoiceLabel async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final choice = await _backend.getChoiceForDate(today);
    return (choice == 'veg') ? 'Veg' : 'Non‑Veg';
  }

  Future<String> get plannedChoiceLabelForSelectedDate async {
    final choice = await _backend.getChoiceForDate(_selectedDate);
    return (choice == 'veg') ? 'Veg' : 'Non‑Veg';
  }

  bool get isSubmissionOpen {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = DateTime(today.year, today.month, today.day, 12, 0);
    // Window is today until 12:00 local time for selecting tomorrow
    return now.isBefore(cutoff);
  }

  void selectChoice(MealChoice choice) {
    _currentChoice = choice;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<bool> isChangeLimitReachedForSelectedDate() async {
    final count = await _backend.getChangeCountForDate(_selectedDate);
    return count >= 3;
  }

  Future<void> submitChoice() async {
    if (_currentChoice == null) return;
    if (!isSubmissionOpen) return;
    try {
      await _backend.saveSelection(
        SelectionPayload(
          choice: _currentChoice == MealChoice.veg ? 'veg' : 'non-veg',
          date: _selectedDate,
        ),
      );
      _lastSubmittedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      rethrow; // let UI handle and show message
    }
  }
}
