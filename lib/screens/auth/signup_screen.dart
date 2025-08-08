import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../services/auth_service.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  static const String route = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _admissionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passOutYearController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _admissionController.dispose();
    _emailController.dispose();
    _passOutYearController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ok = await _auth.signUp(
        admissionNo: _admissionController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        passOutYear: int.parse(_passOutYearController.text.trim()),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (ok) {
        Navigator.pushReplacementNamed(context, HomeScreen.route);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User already exists')));
      }
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Password should be at least 6 characters';
          break;
        case 'email-already-in-use':
          message = 'Email already in use';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = 'Signup failed: ${e.code}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _admissionController,
              decoration: const InputDecoration(
                labelText: 'Hostel Admission No',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passOutYearController,
              decoration: const InputDecoration(labelText: 'Pass-out Year'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final year = int.tryParse(v);
                if (year == null ||
                    year < 2000 ||
                    year > DateTime.now().year + 10) {
                  return 'Enter valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) =>
                  v == null || v.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Create Account'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, LoginScreen.route),
              child: const Text('Have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
