import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../utils/constants.dart';
import '../../widgets/pocki_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              _Mascot()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.6, 0.6)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'PockiWords',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Learn languages with cute flashcards\nand fun mini-games.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const Spacer(),
              PockiButton(
                label: 'Create Account',
                icon: Icons.favorite_rounded,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ));
                },
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
              const SizedBox(height: AppSpacing.md),
              PockiOutlineButton(
                label: 'I already have an account',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ));
                },
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mascot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Center(
        child: Text('🐰', style: TextStyle(fontSize: 96)),
      ),
    );
  }
}
