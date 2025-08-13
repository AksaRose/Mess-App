import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:mess_app/services/firebase_init.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'providers/selection_provider.dart';
import 'screens/selection_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/login_admin_screen.dart';
import 'screens/admin/stats_screen.dart';
import 'screens/admin/menu_editor_screen.dart';
import 'screens/weekly_preference_screen.dart';
import 'package:mess_app/env.dart';
import 'theme/dark_theme.dart';

void main() async {
  await Env.load();
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseIfEnabled(true); // Assuming Firebase is enabled
  
  // Connect to Firebase Emulators
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SelectionProvider())],
      child: MaterialApp(
        title: 'Mess App',
        theme: darkTheme,
        routes: {
          HomeScreen.route: (_) => const HomeScreen(),
          SelectionScreen.route: (_) => const SelectionScreen(),
          ConfirmationScreen.route: (_) => const ConfirmationScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          SignupScreen.route: (_) => const SignupScreen(),
          AdminLoginScreen.route: (_) => const AdminLoginScreen(),
          AdminStatsScreen.route: (_) => const AdminStatsScreen(),
          MenuEditorScreen.route: (_) => const MenuEditorScreen(),
          WeeklyPreferenceScreen.route: (_) => const WeeklyPreferenceScreen(),
        },
        initialRoute: LoginScreen.route,
      ),
    );
  }
}

// Counter demo removed; replaced with app routes
