import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class FirebaseUserAuthService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirebaseUserAuthService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  String _emailFromAdmission(String admissionNo) => '${admissionNo.trim()}@mess.app';

  Future<bool> signUp({
    required String admissionNo,
    required String fullName,
    required int passOutYear,
    required String password,
  }) async {
    final email = _emailFromAdmission(admissionNo);
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    await _db.collection('users').doc(uid).set({
      'admissionNo': admissionNo,
      'fullName': fullName,
      'passOutYear': passOutYear,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String fullName,
    required String admissionNo,
    required int passOutYear,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    await _db.collection('users').doc(uid).set({
      'email': email,
      'admissionNo': admissionNo,
      'fullName': fullName,
      'passOutYear': passOutYear,
      'role': 'user',
      'createdAt': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<bool> login({
    required String admissionNo,
    required String password,
  }) async {
    final email = _emailFromAdmission(admissionNo);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return true;
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return true;
  }

  fb.User? get currentUser => _auth.currentUser;

  Future<String?> fetchCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['role'] as String?; // 'admin' | 'user'
  }
}


