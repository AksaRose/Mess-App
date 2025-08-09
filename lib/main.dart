import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/selection_provider.dart';
import 'screens/selection_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/login_admin_screen.dart';
import 'screens/admin/stats_screen.dart';
import 'screens/admin/menu_editor_screen.dart';
import 'firebase_options.dart';
import 'services/config.dart';
import 'package:mess_app/env.dart';
import 'theme/dark_theme.dart';

void main() async {
  await Env.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        },
        initialRoute: LoginScreen.route,
      ),
    );
  }
}

// Counter demo removed; replaced with app routes
