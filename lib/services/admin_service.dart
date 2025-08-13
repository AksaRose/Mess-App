import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'firebase_admin_service.dart';

class AdminUser {
  final String uid;
  final String fullName;
  final String admissionNo;
  final int passOutYear;
  
  const AdminUser({
    required this.uid,
    required this.fullName,
    required this.admissionNo,
    required this.passOutYear,
  });
}

class AdminCounts {
  final int veg;
  final int nonVeg;
  final Map<String, int> caffeineCounts;
  final List<AdminUser> vegUsers;
  final List<AdminUser> nonVegUsers;
  final Map<String, List<AdminUser>> caffeineUsers;
  
  const AdminCounts({
    required this.veg, 
    required this.nonVeg, 
    this.caffeineCounts = const {},
    this.vegUsers = const [],
    this.nonVegUsers = const [],
    this.caffeineUsers = const {},
  });
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
    final caffeine = data['caffeine'] as String?; // optional
    final vegCount = choice == 'veg' ? 1 : 0;
    final nonVegCount = choice == 'veg' ? 0 : 1;
    final caffeineCounts = <String, int>{
      'chaya': caffeine == 'chaya' ? 1 : 0,
      'kaapi': caffeine == 'kaapi' ? 1 : 0,
      'blackCoffee': caffeine == 'blackCoffee' ? 1 : 0,
      'blackTea': caffeine == 'blackTea' ? 1 : 0,
    };
    return AdminCounts(veg: vegCount, nonVeg: nonVegCount, caffeineCounts: caffeineCounts);
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


