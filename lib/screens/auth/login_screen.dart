import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firebase_user_auth_service.dart';
import '../home_screen.dart';
import 'signup_screen.dart';
import '../admin/stats_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ok = await _auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        // If Firebase is enabled, fetch role and route admins
        try {
          final role = await FirebaseUserAuthService().fetchCurrentUserRole();
          if (!mounted) return;
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, AdminStatsScreen.route);
            return;
          }
        } catch (_) {}
        Navigator.pushReplacementNamed(context, HomeScreen.route);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString().contains('firebase_auth')
          ? 'Invalid email or password'
          : 'Login failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) =>
                  v == null || v.length < 4 ? 'Min 4 chars' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, SignupScreen.route),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
