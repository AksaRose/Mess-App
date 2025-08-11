import 'package:flutter/foundation.dart';

import '../services/backend.dart';
import '../services/backend_factory.dart';
import '../services/models.dart';
import '../services/menu_service.dart';

enum MealChoice { veg, nonVeg }

class SelectionProvider extends ChangeNotifier {
  final Backend _backend = BackendFactory.create();
  final MenuService _menuService = MenuServiceFactory.create();

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


  bool get isSubmissionOpen {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Ensure selection is only for tomorrow and within the submission window (1 PM to 10 PM)
    if (!_selectedDate.isAtSameMomentAs(tomorrow)) {
      return false;
    }

    final submissionStartTime = DateTime(now.year, now.month, now.day, 13, 0, 0); // 1 PM
    final submissionEndTime = DateTime(now.year, now.month, now.day, 22, 0, 0); // 10 PM

    return now.isAfter(submissionStartTime) && now.isBefore(submissionEndTime);
  }

  void selectChoice(MealChoice choice) {
    _currentChoice = choice;
    notifyListeners();
  }

  void setSelectedDate(DateTime newDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    // Normalize newDate to ignore time
    final normalizedDate = DateTime(newDate.year, newDate.month, newDate.day);

    // Restrict date selection to yesterday, today, and tomorrow
    if (normalizedDate.isAtSameMomentAs(yesterday) ||
        normalizedDate.isAtSameMomentAs(today) ||
        normalizedDate.isAtSameMomentAs(tomorrow)) {
      _selectedDate = normalizedDate;
      notifyListeners();
    }
  }

  Future<void> submitChoice() async {
    if (_currentChoice == null) return;
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

  Future<bool> isChangeLimitReachedForSelectedDate() async {
    final count = await _backend.getChangeCountForDate(_selectedDate);
    return count >= 3;
  }
}
