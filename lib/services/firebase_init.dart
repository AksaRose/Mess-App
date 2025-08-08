import 'package:firebase_core/firebase_core.dart';

Future<void> initFirebaseIfEnabled(bool enabled) async {
  if (!enabled) return;
  try {
    // Requires generated options after running `flutterfire configure`
    // ignore: uri_does_not_exist
    import 'package:mess_app/firebase_options.dart' as fo; // placeholder
  } catch (_) {}
  await Firebase.initializeApp();
}


