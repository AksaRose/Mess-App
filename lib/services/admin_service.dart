import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'firebase_admin_service.dart';

class AdminCounts {
  final int veg;
  final int nonVeg;
  const AdminCounts({required this.veg, required this.nonVeg});
}

abstract class AdminService {
  Future<AdminCounts> getCountsForDate(DateTime date);
}

class LocalAdminService implements AdminService {
  static const String _keySelectionsByDate = 'selections_by_date';

  @override
  Future<AdminCounts> getCountsForDate(DateTime date) async {
    // Local mode only has the current user's selection, so counts are 0/1
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectionsByDate);
    if (raw == null) return const AdminCounts(veg: 0, nonVeg: 1);
    final Map<String, dynamic> map = jsonDecode(raw);
    final key = _dateKey(date);
    final entry = map[key];
    if (entry == null) return const AdminCounts(veg: 0, nonVeg: 1);
    final data = entry as Map<String, dynamic>;
    final choice = data['choice'] as String?;
    return choice == 'veg'
        ? const AdminCounts(veg: 1, nonVeg: 0)
        : const AdminCounts(veg: 0, nonVeg: 1);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class AdminServiceFactory {
  static AdminService create() {
    if (AppConfig.isFirebaseEnabled) {
      return FirebaseAdminService();
    }
    return LocalAdminService();
  }
}


