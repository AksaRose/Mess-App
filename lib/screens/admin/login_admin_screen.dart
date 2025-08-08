import 'package:flutter/material.dart';

import '../home_screen.dart';
import 'stats_screen.dart';
import '../../services/config.dart';
import '../../services/firebase_auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  static const String route = '/admin/login';
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (AppConfig.isFirebaseEnabled) {
        final auth = FirebaseAdminAuthService();
        await auth.signInWithEmailPassword(
          email: _username.text.trim(),
          password: _password.text,
        );
      } else {
        // Local fallback
        if (!(_username.text.trim() == 'admin' && _password.text == 'admin123')) {
          throw Exception('Invalid admin creds');
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, AdminStatsScreen.route);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, HomeScreen.route),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _username,
              decoration: InputDecoration(
                labelText: AppConfig.isFirebaseEnabled ? 'Email' : 'Username',
              ),
              keyboardType: AppConfig.isFirebaseEnabled
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (AppConfig.isFirebaseEnabled && !v.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) => v == null || v.length < 4 ? 'Min 4 chars' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Login as Admin'),
            ),
          ],
        ),
      ),
    );
  }
}


