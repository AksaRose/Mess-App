import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_service.dart';

class FirebaseAdminService implements AdminService {
  final FirebaseFirestore _db;
  FirebaseAdminService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AdminCounts> getCountsForDate(DateTime date) async {
    try {
      print('Admin: Fetching counts for date: ${_dateKey(date)}');
      
      // We compute for provided date (e.g., tomorrow) with fallback logic:
      // 1) Explicit submissions in selections/date
      // 2) Else, use weeklySelections weekday mapping
      // 3) Default meal = non-veg
      final dateKey = _dateKey(date);
      final entriesCol = _db.collection('selections').doc(dateKey).collection('entries');
      
      print('Admin: Reading from selections/$dateKey/entries');
      final explicitSnap = await entriesCol.get();
      print('Admin: Found ${explicitSnap.docs.length} explicit entries');

      // Collect explicit meal choices by user
      final Map<String, String> explicitMealsByUid = {};
      for (final doc in explicitSnap.docs) {
        final data = doc.data();
        final choice = (data['choice'] as String?) ?? 'non-veg';
        explicitMealsByUid[doc.id] = choice; // uid -> 'veg' | 'non-veg'
      }

      // Get all users from users collection
      print('Admin: Reading all users from users collection');
      final allUsersSnap = await _db.collection('users').get();
      print('Admin: Found ${allUsersSnap.docs.length} total users');

      // Get weekly selections for users who have them
      print('Admin: Reading weeklySelections collection');
      final weeklySnap = await _db.collection('weeklySelections').get();
      print('Admin: Found ${weeklySnap.docs.length} weekly selections');

      int veg = 0;
      int nonVeg = 0;
      final Map<String, int> caffeineCounts = {
        'chaya': 0,
        'kaapi': 0,
        'blackCoffee': 0,
        'blackTea': 0,
      };
      
      final List<AdminUser> vegUsers = [];
      final List<AdminUser> nonVegUsers = [];
      final Map<String, List<AdminUser>> caffeineUsers = {
        'chaya': [],
        'kaapi': [],
        'blackCoffee': [],
        'blackTea': [],
      };

      // Process each user to determine their meal choice
      for (final userDoc in allUsersSnap.docs) {
        final uid = userDoc.id;
        final userData = userDoc.data();
        
        // Create AdminUser object
        final userDetails = AdminUser(
          uid: uid,
          fullName: userData['fullName'] as String? ?? 'Unknown',
          admissionNo: userData['admissionNo'] as String? ?? 'Unknown',
          passOutYear: userData['passOutYear'] as int? ?? 0,
        );

        // Determine meal choice for this user
        String meal;
        String? caffeine;
        
        // 1. Check explicit submission first
        final explicit = explicitMealsByUid[uid];
        if (explicit != null) {
          meal = explicit; // 'veg' | 'non-veg' (explicit single-day)
        } else {
          // 2. Check weekly recurring choice
          final weeklyDoc = weeklySnap.docs.where((d) => d.id == uid).firstOrNull;
          if (weeklyDoc != null) {
            final weekly = weeklyDoc.data();
            final weekdayKey = 'weekday_${date.weekday}';
            final weeklyMeal = weekly[weekdayKey] as String?; // 'veg' | 'nonVeg'
            
            if (weeklyMeal == 'veg') {
              meal = 'veg';
            } else if (weeklyMeal == 'nonVeg' || weeklyMeal == 'non-veg') {
              meal = 'non-veg';
            } else {
              meal = 'non-veg'; // default
            }
            
            // Get caffeine from weekly
            final caffeineKey = 'caffeine_weekday_${date.weekday}';
            caffeine = weekly[caffeineKey] as String?;
          } else {
            // 3. No weekly selection, default to non-veg
            meal = 'non-veg';
            caffeine = null;
          }
        }
        
        // Add user to appropriate meal list
        if (meal == 'veg') {
          veg += 1;
          vegUsers.add(userDetails);
        } else {
          nonVeg += 1;
          nonVegUsers.add(userDetails);
        }

        // Add user to caffeine list if they have a preference
        if (caffeine != null && caffeine.isNotEmpty) {
          if (caffeineCounts.containsKey(caffeine)) {
            caffeineCounts[caffeine] = (caffeineCounts[caffeine] ?? 0) + 1;
            caffeineUsers[caffeine]!.add(userDetails);
          }
        }
      }

      print('Admin: Final counts - Veg: $veg, NonVeg: $nonVeg, Caffeine: $caffeineCounts');
      print('Admin: User counts - Veg users: ${vegUsers.length}, NonVeg users: ${nonVegUsers.length}');
      
      return AdminCounts(
        veg: veg, 
        nonVeg: nonVeg, 
        caffeineCounts: caffeineCounts,
        vegUsers: vegUsers,
        nonVegUsers: nonVegUsers,
        caffeineUsers: caffeineUsers,
      );
      
    } catch (e, stackTrace) {
      print('Admin: Error fetching counts: $e');
      print('Admin: Stack trace: $stackTrace');
      rethrow;
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


