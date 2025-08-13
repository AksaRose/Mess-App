import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';

import '../services/backend.dart';
import '../services/backend_factory.dart';
import '../services/models.dart'; // Import MealChoice from models.dart
import '../services/menu_service.dart';

class SelectionProvider extends ChangeNotifier {
  final Backend _backend = BackendFactory.create();
  final MenuService _menuService = MenuServiceFactory.create();

  MealChoice? _currentChoice;
  CaffeineChoice? _currentCaffeineChoice;
  DateTime? _lastSubmittedAt;
  DateTime? _lastConfirmedAt;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final Map<DateTime, MealChoice> _weeklyChoices = {};
  final Map<DateTime, CaffeineChoice?> _weeklyCaffeine = {};

  MealChoice? get currentChoice => _currentChoice;
  CaffeineChoice? get currentCaffeineChoice => _currentCaffeineChoice;
  DateTime? get lastSubmittedAt => _lastSubmittedAt;
  DateTime? get lastConfirmedAt => _lastConfirmedAt;
  DateTime get selectedDate => _selectedDate;
  DailyMenu get selectedMenu => _menuService.getMenuFor(_selectedDate);
  DailyMenu get todayMenu => _menuService.getMenuFor(DateTime.now());
  DailyMenu get tomorrowMenu => _menuService.getMenuFor(DateTime.now().add(const Duration(days: 1)));
  Map<DateTime, MealChoice> get weeklyChoices => _weeklyChoices;
  Map<DateTime, CaffeineChoice?> get weeklyCaffeine => _weeklyCaffeine;


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

  void selectCaffeineChoice(CaffeineChoice? choice) {
    _currentCaffeineChoice = choice;
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
      _loadPlannedChoice(); // Load the specific choice for the newly selected date
      _loadWeeklyChoices(); // Reload weekly choices for context
      notifyListeners();
    }
  }

  Future<void> _loadWeeklyChoices() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _weeklyChoices.clear();
      return;
    }
    final weeklySubmissions = await _backend.getWeeklySubmissions(user.uid);
    _weeklyChoices.clear();
    weeklySubmissions.forEach((date, choice) {
      _weeklyChoices[date] = choice == 'veg' ? MealChoice.veg : MealChoice.nonVeg;
    });
    notifyListeners();
  }

  void setWeeklyChoice(DateTime date, MealChoice choice) {
    _weeklyChoices[DateTime(date.year, date.month, date.day)] = choice;
    notifyListeners();
  }

  void setWeeklyCaffeine(DateTime date, CaffeineChoice? choice) {
    _weeklyCaffeine[DateTime(date.year, date.month, date.day)] = choice;
    notifyListeners();
  }

  Future<void> submitSingleWeeklyChoice(DateTime date, {MealChoice? choice}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    // Use the provided choice or get from weekly choices
    final selectedChoice = choice ?? _weeklyChoices[date];
    if (selectedChoice == null) {
      throw Exception('No choice selected for this date.');
    }

    final payload = WeeklySelectionPayload(weeklyChoices: {
      date: selectedChoice
    }, weeklyCaffeineChoices: {
      date: _weeklyCaffeine[date]
    });
    await _backend.submitSingleWeeklyChoice(payload);

    // Update the weekly choices map after successful submission
    final normalized = DateTime(date.year, date.month, date.day);
    _weeklyChoices[normalized] = selectedChoice;
    // caffeine can be null (meaning no preference)
    _weeklyCaffeine[normalized] = _weeklyCaffeine[normalized];
    notifyListeners();
  }

  Future<void> submitChoice() async {
    if (_currentChoice == null) return;
    try {
      await _backend.saveSelection(
        SelectionPayload(
          choice: _currentChoice == MealChoice.veg ? 'veg' : 'non-veg',
          date: _selectedDate,
        ),
        caffeineChoice: _currentCaffeineChoice,
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
    return (choice == 'veg') ? 'Veg' : (choice == 'non-veg' ? 'Non‑Veg' : 'Not Selected');
  }

  Future<void> _loadPlannedChoice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _currentChoice = null;
      _lastSubmittedAt = null;
      return;
    }
    final submission = await _backend.getSubmissionForDate(user.uid, _selectedDate);
    if (submission != null) {
      _currentChoice = submission.choice == 'veg' ? MealChoice.veg : MealChoice.nonVeg;
      _lastSubmittedAt = DateTime.parse(submission.timestamp);
    } else {
      // If no direct submission, check weekly choices for the selected date
      final weeklySubmissions = await _backend.getWeeklySubmissions(user.uid);
      final weeklyChoiceStr = weeklySubmissions[_selectedDate];
      if (weeklyChoiceStr == 'veg') {
        _currentChoice = MealChoice.veg;
      } else if (weeklyChoiceStr == 'non-veg') {
        _currentChoice = MealChoice.nonVeg;
      } else {
        _currentChoice = null;
      }
      _lastSubmittedAt = null; // No specific submission timestamp for weekly choice
    }
    notifyListeners();
  }

  Future<bool> isChangeLimitReachedForSelectedDate() async {
    final count = await _backend.getChangeCountForDate(_selectedDate);
    return count >= 3;
  }

  /// Returns the user's effective meal choice for today:
  /// 1. If user submitted a choice yesterday, use that.
  /// 2. Else, if user has a weekly recurring choice for today's weekday, use that.
  /// 3. Else, default to non-veg.
  Future<MealChoice> getEffectiveChoiceForToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // 1. Check for yesterday's submission
    final yesterdayChoiceStr = await _backend.getChoiceForDate(yesterday);
    if (yesterdayChoiceStr == 'veg') return MealChoice.veg;
    if (yesterdayChoiceStr == 'non-veg') return MealChoice.nonVeg;

    // 2. Check weekly recurring choice for today's weekday (expanded by backend)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final weeklySubmissions = await _backend.getWeeklySubmissions(user.uid);
      final weeklyChoiceStr = weeklySubmissions[today];
      if (weeklyChoiceStr == 'veg') return MealChoice.veg;
      if (weeklyChoiceStr == 'nonVeg' || weeklyChoiceStr == 'non-veg') return MealChoice.nonVeg;
    }

    // 3. Default to non-veg
    return MealChoice.nonVeg;
  }
}
