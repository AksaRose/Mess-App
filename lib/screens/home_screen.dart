import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Import lottie
import 'package:intl/intl.dart'; // Import intl for date formatting

import '../providers/selection_provider.dart';
import 'selection_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Note: AuthService needs to be accessible here, e.g. via provider
              // For now, just navigating to login
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Lottie.asset(
                  'assets/lottie/Cat Movement.json',
                  height: 200, // Adjust height as needed
                  repeat: true, // Loop the animation
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showTodaysChoice(context),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Know Your Choice'),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, SelectionScreen.route),
                  icon: const Icon(Icons.room_service_outlined),
                  label: const Text('Choose Your Meal'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTodaysChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow the modal to take up more height
      builder: (context) {
        return FractionallySizedBox( // Use FractionallySizedBox to control height
          heightFactor: 0.6, // Adjust as needed, e.g., 60% of screen height
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                color: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView( // Make the content scrollable
                  child: Column(
                    mainAxisSize: MainAxisSize.max, // Take max space in SingleChildScrollView
                    crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
                    children: [
                      Text(
                        'Your Meal Choice for Today',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white), // Adjust text style
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()), // Display current date
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<String>(
                        future: context.read<SelectionProvider>().todayChoiceLabel,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          final label = snapshot.hasData ? labelFromChoice(snapshot.data) : 'Not Selected';
                          return Text(
                            label,
                            style: TextStyle(
                              fontSize: 28, // Adjust font size
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Lottie.asset(
                        'assets/lottie/animation.json',
                        height: 150, // Adjust height as needed
                        repeat: true, // Loop the animation
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton( // Changed to ElevatedButton for better visibility
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45), // Make button full width
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String labelFromChoice(String? choice) {
    if (choice == null) return 'Not Selected';
    switch (choice) {
      case 'veg':
        return 'Veg';
      case 'non-veg':
        return 'Non-Veg';
      default:
        return 'Not Selected';
    }
  }
}
