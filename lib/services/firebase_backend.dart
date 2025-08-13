import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'backend.dart';
import 'models.dart';

class FirebaseBackend implements Backend {
  final FirebaseFirestore _db;
  FirebaseBackend({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveSelection(SelectionPayload payload) async {
    final dateKey = _dateKey(payload.date);
    final userId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    final docRef = _db
        .collection('selections')
        .doc(dateKey)
        .collection('entries')
        .doc(userId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      int changeCount = 0;
      String? previousChoice;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        changeCount = (data['changeCount'] as num?)?.toInt() ?? 0;
        previousChoice = data['choice'] as String?;
      }
      final newChoice = payload.choice;
      final isChanging = previousChoice != null && previousChoice != newChoice;
      final nextCount = isChanging ? changeCount + 1 : changeCount;
      if (nextCount > 3) {
        throw Exception('Change limit reached');
      }
      final saveData = {
        ...payload.toJson(),
        'changeCount': nextCount,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      txn.set(docRef, saveData, SetOptions(merge: true));
    });
  }

  @override
  Future<String?> getChoiceForDate(DateTime date) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final dateKey = _dateKey(date);
    final doc = await _db
        .collection('selections')
        .doc(dateKey)
        .collection('entries')
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    final data = doc.data();
    return (data?['choice'] as String?);
  }

  @override
  Future<int> getChangeCountForDate(DateTime date) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final dateKey = _dateKey(date);
    final doc = await _db
        .collection('selections')
        .doc(dateKey)
        .collection('entries')
        .doc(uid)
        .get();
    if (!doc.exists) return 0;
    final data = doc.data();
    return (data?['changeCount'] as num?)?.toInt() ?? 0;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<void> submitWeeklyChoice(WeeklySelectionPayload payload) async {
    final userId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    final docRef = _db.collection('weeklySelections').doc(userId);

    // Store by weekday keys (1=Mon .. 7=Sun)
    final Map<String, dynamic> updates = {};
    payload.weeklyChoices.forEach((date, choice) {
      final weekday = date.weekday; // 1..7
      updates['weekday_$weekday'] = choice.name; // 'veg' | 'nonVeg'
    });
    await docRef.set(updates, SetOptions(merge: true));
  }

  @override
  Future<Map<DateTime, String>> getWeeklySubmissions(String userId) async {
    final doc = await _db.collection('weeklySelections').doc(userId).get();
    if (!doc.exists) return {};
    final data = doc.data() as Map<String, dynamic>;

    // Expand weekday_* into concrete dates for the next 7 days starting today
    final Map<DateTime, String> result = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final weekdayKey = 'weekday_${date.weekday}';
      final choice = data[weekdayKey];
      if (choice is String && choice.isNotEmpty) {
        result[date] = choice; // 'veg' | 'nonVeg'
      }
    }
    return result;
  }

  @override
  Future<Submission?> getSubmissionForDate(String userId, DateTime date) async {
    final dateKey = _dateKey(date);
    final doc = await _db
        .collection('selections')
        .doc(dateKey)
        .collection('entries')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data();
    return Submission(
      choice: data?['choice'] as String,
      timestamp: data?['updatedAt'] as String,
      userId: userId,
      date: DateTime.parse(dateKey),
    );
  }

  @override
  Future<void> submitSingleWeeklyChoice(WeeklySelectionPayload payload) async {
    final userId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    // Assuming payload.weeklyChoices will only contain one entry for the specific day
    final dateEntry = payload.weeklyChoices.entries.first;
    final weekday = dateEntry.key.weekday; // 1..7
    final choice = dateEntry.value.name; // 'veg' | 'nonVeg'

    final docRef = _db.collection('weeklySelections').doc(userId);
    await docRef.set({'weekday_$weekday': choice}, SetOptions(merge: true));
  }
}

