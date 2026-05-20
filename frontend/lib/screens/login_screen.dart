import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.tealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  size: 48,
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Juggaad',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.amethystDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find trusted services near you',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Dummy Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
                child: const Text('Continue as Guest'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
