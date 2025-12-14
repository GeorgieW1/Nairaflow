import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light blue-gray background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/icons/nairapay.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),

              const SizedBox(height: 32),

              // App name
              Text(
                'NairaPay',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary, // Darker text for contrast
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Your Digital Payment Solution',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.8), // Darker text for contrast
                    ),
              ),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary, // Darker indicator for contrast
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
