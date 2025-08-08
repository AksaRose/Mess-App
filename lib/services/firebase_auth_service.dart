import 'package:firebase_auth/firebase_auth.dart' as fb;

class FirebaseAdminAuthService {
  final fb.FirebaseAuth _auth;
  FirebaseAdminAuthService({fb.FirebaseAuth? auth}) : _auth = auth ?? fb.FirebaseAuth.instance;

  Future<void> signInWithEmailPassword({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async => _auth.signOut();

  fb.User? get currentUser => _auth.currentUser;
}


