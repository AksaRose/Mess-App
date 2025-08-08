import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_service.dart';

class FirebaseAdminService implements AdminService {
  final FirebaseFirestore _db;
  FirebaseAdminService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AdminCounts> getCountsForDate(DateTime date) async {
    final dateKey = _dateKey(date);
    final col = _db.collection('selections').doc(dateKey).collection('entries');
    final snap = await col.get();
    int veg = 0;
    int nonVeg = 0;
    for (final doc in snap.docs) {
      final choice = (doc.data()['choice'] as String?) ?? 'non-veg';
      if (choice == 'veg') {
        veg += 1;
      } else {
        nonVeg += 1;
      }
    }
    return AdminCounts(veg: veg, nonVeg: nonVeg);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


