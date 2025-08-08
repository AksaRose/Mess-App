import 'backend.dart';
import 'config.dart';
import 'firebase_backend.dart';
import 'local_backend.dart';

class BackendFactory {
  static Backend create() {
    if (AppConfig.isFirebaseEnabled) return FirebaseBackend();
    return LocalBackend();
  }
}


