import 'package:firebase_core/firebase_core.dart';
import 'package:mess_app/firebase_options.dart';

Future<void> initFirebaseIfEnabled(bool enabled) async {
  if (!enabled) return;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Firebase is already initialized, or other error.
  }
}


