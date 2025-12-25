import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the system is in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Background changes: White for Light Mode, Dark Grey for Dark Mode
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered Logo
              const Image(
                image: AssetImage('assets/icons/nairapay.png'),
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 24),

              // Tagline color adjusts automatically
              Text(
                'Your Digital Payment Solution',
                style: TextStyle(
                  color: isDarkMode 
                      ? Colors.white70 
                      : Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}