import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'backend.dart';
import 'package:mess_app/services/models.dart';

// Simple local storage backend for MVP; can be swapped to Firebase later.
class LocalBackend implements Backend {
  static const String _keyUserId = 'user_id';
  static const String _keySelection = 'selection_record';
  static const String _keyConfirmed = 'confirmation_record';
  static const String _keySelectionsByDate = 'selections_by_date';
  static const String qrToken = 'MESS_QR_STATIC_TOKEN'; // printed as QR in mess

  Future<String> _getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_keyUserId);
    if (existing != null) return existing;
    final newId = const Uuid().v4();
    await prefs.setString(_keyUserId, newId);
    return newId;
  }

  @override
  Future<void> saveSelection(SelectionPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getOrCreateUserId();
    final data = {'userId': userId, ...payload.toJson()};
    // change limit tracking per date in local map
    final rawMap = prefs.getString(_keySelectionsByDate);
    final Map<String, dynamic> map = rawMap == null ? {} : jsonDecode(rawMap);
    final dateKey = _dateKey(payload.date);
    final existing = map[dateKey] as Map<String, dynamic>?;
    int changeCount = 0;
    if (existing != null) {
      final prevChoice = existing['choice'] as String?;
      changeCount = (existing['changeCount'] as num?)?.toInt() ?? 0;
      if (prevChoice != null && prevChoice != payload.choice) {
        changeCount += 1;
      }
      if (changeCount > 3) {
        throw Exception('Change limit reached');
      }
    }
    final withCount = {
      ...data,
      'changeCount': changeCount,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    // Save latest selection snapshot
    await prefs.setString(_keySelection, jsonEncode(withCount));
    // Save per-date record for historical lookup (yesterday, etc.)
    map[dateKey] = withCount;
    await prefs.setString(_keySelectionsByDate, jsonEncode(map));
  }

  Future<bool> confirmWithQr(String qrValue) async {
    if (qrValue != qrToken) return false;
    final prefs = await SharedPreferences.getInstance();
    final selection = prefs.getString(_keySelection);
    if (selection == null) return false;
    final decoded = jsonDecode(selection) as Map<String, dynamic>;
    decoded['confirmedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(_keyConfirmed, jsonEncode(decoded));
    return true;
  }

  Future<AdminScanResult> adminScan(String qrValue) async {
    // For MVP, admin uses same QR. In production, admin QR would be different.
    if (qrValue != qrToken) {
      return AdminScanResult(success: false, message: 'Invalid QR');
    }
    final prefs = await SharedPreferences.getInstance();
    final confirmed = prefs.getString(_keyConfirmed);
    if (confirmed == null) {
      return AdminScanResult(success: false, message: 'No confirmation found');
    }
    final data = jsonDecode(confirmed) as Map<String, dynamic>;
    final choice = data['choice'];
    final userId = data['userId'];
    final dateIso = data['date'] as String?;
    final date = dateIso != null ? DateTime.tryParse(dateIso) : null;
    final today = DateTime.now();
    final isToday = date != null &&
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    if (!isToday) {
      return AdminScanResult(
        success: false,
        message: 'Selection not for today',
      );
    }
    return AdminScanResult(
      success: true,
      message: 'User $userId confirmed: $choice',
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _dateKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<String?> getChoiceForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectionsByDate);
    if (raw == null) return null;
    final Map<String, dynamic> map = jsonDecode(raw);
    final entry = map[_dateKey(date)];
    if (entry == null) return null;
    final data = entry as Map<String, dynamic>;
    return data['choice'] as String?;
  }

  @override
  Future<int> getChangeCountForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectionsByDate);
    if (raw == null) return 0;
    final Map<String, dynamic> map = jsonDecode(raw);
    final entry = map[_dateKey(date)];
    if (entry == null) return 0;
    final data = entry as Map<String, dynamic>;
    return (data['changeCount'] as num?)?.toInt() ?? 0;
  }
  @override
  Future<void> submitWeeklyChoice(WeeklySelectionPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getOrCreateUserId();
    final data = {
      'userId': userId,
      'weeklyChoices': payload.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('weekly_selections_$userId', jsonEncode(data));
  }

  @override
  Future<Map<DateTime, String>> getWeeklySubmissions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('weekly_selections_$userId');
    if (raw == null) return {};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final weeklyChoices = data['weeklyChoices'] as Map<String, dynamic>;
    final Map<DateTime, String> result = {};
    weeklyChoices.forEach((dateString, choice) {
      result[DateTime.parse(dateString)] = choice as String;
    });
    return result;
  }

  @override
  Future<Submission?> getSubmissionForDate(String userId, DateTime date) async {
    // This is a placeholder for LocalBackend, as it doesn't store individual submissions by user and date directly for retrieval.
    // In a real local backend, you might retrieve from _keySelectionsByDate.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectionsByDate);
    if (raw == null) return null;
    final Map<String, dynamic> map = jsonDecode(raw);
    final entry = map[_dateKey(date)];
    if (entry == null) return null;
    final data = entry as Map<String, dynamic>;
    return Submission(
      choice: data['choice'] as String,
      timestamp: data['timestamp'] as String,
      userId: data['userId'] as String,
      date: DateTime.parse(data['date']),
    );
  }
  @override
  Future<void> submitSingleWeeklyChoice(WeeklySelectionPayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await _getOrCreateUserId();
    // Assuming payload.weeklyChoices will only contain one entry for the specific day
    final dateEntry = payload.weeklyChoices.entries.first;
    final dateKey = _dateKey(dateEntry.key);

    final rawMap = prefs.getString('weekly_selections_$userId');
    final Map<String, dynamic> weeklySelections = rawMap == null ? {} : jsonDecode(rawMap);

    weeklySelections[dateKey] = dateEntry.value.name;

    await prefs.setString('weekly_selections_$userId', jsonEncode(weeklySelections));
  }
}

